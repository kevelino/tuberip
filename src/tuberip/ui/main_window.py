from __future__ import annotations

import os

from PySide6.QtCore import QPoint, QSettings, Qt, QThread, QUrl, Signal
from PySide6.QtGui import QDesktopServices, QShortcut
from PySide6.QtWidgets import (
    QApplication,
    QFrame,
    QHBoxLayout,
    QLabel,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

from ..backend.downloader import DependencyError, Downloader
from ..backend.models import DownloadConfig, DownloadItem, Mode
from .download_item_widget import DownloadItemWidget
from .widgets import (
    FormatSelector,
    HelpDialog,
    QualitySelector,
    SaveToRow,
    SettingsDialog,
    URLInput,
)

SETTINGS_ORG = "TubeRip"
SETTINGS_APP = "TubeRip"


# ─────────────────────────────────────────────────────────────────────────────
# Worker Thread
# ─────────────────────────────────────────────────────────────────────────────


class DownloadWorker(QThread):
    progress = Signal(float)
    status_changed = Signal(str)
    speed_info = Signal(str)
    title_found = Signal(str)
    finished = Signal()

    def __init__(self, downloader: Downloader, item: DownloadItem):
        super().__init__()
        self.downloader = downloader
        self.item = item
        self._paused = False

    def run(self) -> None:
        # Fetch metadata (title) before starting the actual download
        meta = self.downloader.fetch_metadata(self.item.url)
        if meta:
            self.title_found.emit(meta.get("title", self.item.url))

        self.downloader.download(
            self.item,
            on_progress=lambda p: self.progress.emit(p),
            on_status=lambda s: self.status_changed.emit(s),
            on_speed=lambda s: self.speed_info.emit(s),
        )
        self.finished.emit()

    def pause(self) -> None:
        if self._paused:
            self.downloader.resume()
            self._paused = False
        else:
            self.downloader.pause()
            self._paused = True

    def resume(self) -> None:
        if self._paused:
            self.downloader.resume()
            self._paused = False

    def cancel(self) -> None:
        self.item.status = "cancelled"
        self.downloader.cancel()
        self._paused = False


# ─────────────────────────────────────────────────────────────────────────────
# Main Window
# ─────────────────────────────────────────────────────────────────────────────


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("TubeRip")
        self.resize(860, 560)
        self.setMinimumSize(720, 480)

        # Frameless so we can draw our own title bar
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.Window)
        self._drag_pos: QPoint | None = None

        self.settings = QSettings(SETTINGS_ORG, SETTINGS_APP)
        self.items: list[DownloadItem] = []
        self.workers: list[DownloadWorker] = []
        self.widgets: list[DownloadItemWidget] = []

        # ── Root widget ───────────────────────────────────────
        root = QWidget()
        root.setObjectName("rootWidget")
        self.setCentralWidget(root)

        root_layout = QVBoxLayout(root)
        root_layout.setContentsMargins(0, 0, 0, 0)
        root_layout.setSpacing(0)

        # ── Build sections ────────────────────────────────────
        root_layout.addWidget(self._build_title_bar())
        root_layout.addWidget(self._build_content(), 1)

        # ── Keyboard shortcuts ────────────────────────────────
        self._setup_shortcuts()

    # ─────────────────────────────────────────────────────────
    # Shortcuts
    # ─────────────────────────────────────────────────────────

    def _setup_shortcuts(self) -> None:
        enter_sc = QShortcut(Qt.Key_Return, self)
        enter_sc.activated.connect(self.start_download)

        settings_sc = QShortcut(Qt.CTRL | Qt.Key_S, self)
        settings_sc.activated.connect(self._on_settings_clicked)

        quit_sc = QShortcut(Qt.CTRL | Qt.Key_Q, self)
        quit_sc.activated.connect(QApplication.quit)

    # ─────────────────────────────────────────────────────────
    # Title Bar
    # ─────────────────────────────────────────────────────────

    def _build_title_bar(self) -> QWidget:
        bar = QWidget()
        bar.setObjectName("titleBar")
        bar.setFixedHeight(50)

        layout = QHBoxLayout(bar)
        layout.setContentsMargins(16, 0, 16, 0)
        layout.setSpacing(0)

        # Logo box + app name
        logo = QLabel("TR")
        logo.setObjectName("logoBox")
        logo.setAlignment(Qt.AlignCenter)
        logo.setFixedSize(28, 24)

        app_name = QLabel("TubeRip")
        app_name.setObjectName("appName")

        layout.addWidget(logo)
        layout.addSpacing(10)
        layout.addWidget(app_name)
        layout.addStretch()

        # Toolbar icon buttons (no Downloads button — queue is already visible)
        self._title_bar_btns: dict[str, QPushButton] = {}
        for icon, tip, key in [("⚙", "Settings", "settings"), ("?", "Help", "help")]:
            btn = QPushButton(icon)
            btn.setObjectName("titleBarBtn")
            btn.setFixedSize(34, 34)
            btn.setToolTip(tip)
            layout.addWidget(btn)
            self._title_bar_btns[key] = btn

        self._title_bar_btns["settings"].clicked.connect(self._on_settings_clicked)
        self._title_bar_btns["help"].clicked.connect(self._on_help_clicked)

        # Vertical divider
        div = QFrame()
        div.setObjectName("separator")
        div.setFrameShape(QFrame.VLine)
        div.setFixedWidth(1)
        div.setFixedHeight(24)
        layout.addSpacing(8)
        layout.addWidget(div)
        layout.addSpacing(4)

        # Window controls
        min_btn = QPushButton("─")
        min_btn.setObjectName("minBtn")
        min_btn.setFixedSize(34, 34)
        min_btn.clicked.connect(self.showMinimized)

        max_btn = QPushButton("□")
        max_btn.setObjectName("maxBtn")
        max_btn.setFixedSize(34, 34)
        max_btn.clicked.connect(self._toggle_max)

        close_btn = QPushButton("✕")
        close_btn.setObjectName("closeBtn")
        close_btn.setFixedSize(34, 34)
        close_btn.clicked.connect(self.close)

        for btn in (min_btn, max_btn, close_btn):
            btn.setStyleSheet(
                "QPushButton { background: transparent; border: none; "
                "color: #71717a; font-size: 13px; }"
                "QPushButton:hover { color: #e4e4e7; }"
            )
            layout.addWidget(btn)

        return bar

    def _toggle_max(self):
        if self.isMaximized():
            self.showNormal()
        else:
            self.showMaximized()

    # ─────────────────────────────────────────────────────────
    # Content Area
    # ─────────────────────────────────────────────────────────

    def _build_content(self) -> QWidget:
        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(24, 20, 24, 20)
        layout.setSpacing(14)

        # ── URL field ─────────────────────────────────────────
        self.url_input = URLInput()
        layout.addWidget(self.url_input)

        # ── Format row: [Format combo] [Quality combo] ─────
        format_row = QHBoxLayout()
        format_row.setSpacing(10)

        self.format_selector = FormatSelector()
        self.quality_selector = QualitySelector()

        format_row.addWidget(self.format_selector, 2)
        format_row.addWidget(self.quality_selector, 3)
        layout.addLayout(format_row)

        # ── Action row: [Download btn] [Save-to row] ─────────
        action_row = QHBoxLayout()
        action_row.setSpacing(16)

        self.download_btn = QPushButton("📥  Download Video")
        self.download_btn.setObjectName("downloadBtn")
        self.download_btn.setMinimumHeight(38)
        self.download_btn.clicked.connect(self.start_download)

        self.save_to_row = SaveToRow(
            default_path=self.settings.value("output_dir", "", type=str)
            or DownloadConfig().output_dir
        )

        action_row.addWidget(self.download_btn, 2)
        action_row.addWidget(self.save_to_row, 3)
        layout.addLayout(action_row)

        # ── Queue header ──────────────────────────────────────
        queue_header = QVBoxLayout()
        queue_header.setSpacing(1)

        queue_title = QLabel("Download Queue")
        queue_title.setObjectName("sectionTitle")

        queue_sub = QLabel("Recent Downloads")
        queue_sub.setObjectName("sectionSubtitle")

        queue_header.addWidget(queue_title)
        queue_header.addWidget(queue_sub)
        layout.addLayout(queue_header)

        # ── Queue list ────────────────────────────────────────
        self.queue_list = QListWidget()
        self.queue_list.setVerticalScrollMode(QListWidget.ScrollPerPixel)
        self.queue_list.setSpacing(4)
        layout.addWidget(self.queue_list, 1)

        # ── Signals ───────────────────────────────────────────
        self.format_selector.currentIndexChanged.connect(self._on_format_changed)

        return content

    # ─────────────────────────────────────────────────────────
    # Format change
    # ─────────────────────────────────────────────────────────

    def _on_format_changed(self) -> None:
        if self.format_selector.is_video():
            self.quality_selector.set_video()
            self.download_btn.setText("📥  Download Video")
        else:
            self.quality_selector.set_audio()
            self.download_btn.setText("🎵  Download Audio")

    # ─────────────────────────────────────────────────────────
    # Settings & Help
    # ─────────────────────────────────────────────────────────

    def _on_settings_clicked(self) -> None:
        dialog = SettingsDialog(parent=self)
        if dialog.exec() == SettingsDialog.Accepted:
            self.settings.setValue("output_dir", self.save_to_row.path())

    def _on_help_clicked(self) -> None:
        dialog = HelpDialog(parent=self)
        dialog.exec()

    def _load_settings_dict(self) -> dict:
        s = self.settings
        return {
            "audio_quality":      str(s.value("audio_quality", 0, type=int)),
            "subtitle_lang":      s.value("subtitle_lang", "en,fr", type=str),
            "download_subtitles": s.value("download_subtitles", False, type=bool),
            "embed_thumbnail":    s.value("embed_thumbnail", True, type=bool),
            "embed_metadata":     s.value("embed_metadata", True, type=bool),
            "rate_limit":         s.value("rate_limit", "", type=str),
        }

    # ─────────────────────────────────────────────────────────
    # Download logic
    # ─────────────────────────────────────────────────────────

    def _resolve_output_dir(self) -> str:
        """Expand ~ and environment vars; fall back to default."""
        saved = self.settings.value("output_dir", "", type=str)
        raw = self.save_to_row.path() or saved or DownloadConfig().output_dir
        expanded = os.path.expandvars(os.path.expanduser(raw))
        # Persist if it changed
        if expanded != saved:
            self.settings.setValue("output_dir", expanded)
        return expanded

    def start_download(self) -> None:
        url = self.url_input.text()
        if not url:
            QMessageBox.warning(
                self, "TubeRip", "Please paste a YouTube URL or video ID."
            )
            return

        # Check dependencies before starting
        try:
            Downloader.check_dependencies()
        except DependencyError as exc:
            QMessageBox.critical(self, "TubeRip", str(exc))
            return

        is_video = self.format_selector.is_video()
        mode = Mode.VIDEO if is_video else Mode.AUDIO
        saved = self._load_settings_dict()

        config = DownloadConfig(
            mode=mode,
            quality=self.quality_selector.quality_value(),
            audio_format=self.format_selector.audio_format(),
            audio_quality=saved["audio_quality"],
            subtitle_lang=saved["subtitle_lang"],
            download_subtitles=saved["download_subtitles"],
            embed_thumbnail=saved["embed_thumbnail"],
            embed_metadata=saved["embed_metadata"],
            rate_limit=saved["rate_limit"],
            output_dir=self._resolve_output_dir(),
        )

        item = DownloadItem(url=url, config=config)
        self.items.append(item)

        idx = len(self.items) - 1
        widget = DownloadItemWidget(index=idx, title=url)
        widget.set_status("Queued")

        # Format/quality info
        quality_text = self.quality_selector.currentText().split("•")[0].strip()
        widget.set_info(f"{quality_text} • Progress: 0%")

        list_item = QListWidgetItem()
        list_item.setSizeHint(widget.sizeHint())
        self.queue_list.addItem(list_item)
        self.queue_list.setItemWidget(list_item, widget)
        self.widgets.append(widget)

        # ── Connect per-item signals ──────────────────────────
        widget.pause_requested.connect(lambda: self._on_pause_item(idx))
        widget.cancel_requested.connect(lambda: self._on_cancel_item(idx))
        widget.open_folder_requested.connect(lambda: self._on_open_folder(idx))

        # Clear input after queuing
        self.url_input.set_text("")

        # Spawn worker
        worker = DownloadWorker(Downloader(config), item)
        worker.title_found.connect(lambda title: self._on_title_found(idx, title))
        worker.progress.connect(lambda p: self._on_progress(idx, p))
        worker.status_changed.connect(lambda s: self._on_status_changed(idx, s))
        worker.speed_info.connect(lambda s: self._on_speed_info(idx, s))
        worker.finished.connect(lambda: self._on_finished(idx))
        self.workers.append(worker)
        worker.start()

    def _on_title_found(self, idx: int, title: str) -> None:
        if idx < len(self.widgets):
            self.widgets[idx].set_title(title)
            self.items[idx].title = title

    def _on_progress(self, idx: int, value: float) -> None:
        if idx >= len(self.widgets):
            return
        self.items[idx].progress = value
        w = self.widgets[idx]
        w.set_progress(value)
        w.set_status("Downloading")
        # Update meta label with progress %
        meta = w.meta_label.text()
        parts = [p for p in meta.split(" • ") if "Progress:" not in p]
        parts.append(f"Progress: {int(value)}%")
        w.set_info(" • ".join(parts))

    def _on_speed_info(self, idx: int, speed_str: str) -> None:
        if idx < len(self.widgets):
            self.widgets[idx].set_speed_info(speed_str)

    def _on_status_changed(self, idx: int, status: str) -> None:
        if idx >= len(self.widgets):
            return
        self.items[idx].status = status
        widget = self.widgets[idx]
        if status == "error":
            widget.set_error(self.items[idx].error or "Unknown error")
        elif status == "done":
            widget.set_status("Completed")
            widget.set_progress(100.0)
        elif status == "downloading":
            widget.set_status("Downloading")
        elif status == "cancelled":
            widget.set_status("Cancelled")

    def _on_finished(self, idx: int) -> None:
        if idx >= len(self.widgets):
            return
        widget = self.widgets[idx]
        item = self.items[idx]
        if item.status == "done":
            widget.set_status("Completed")
            widget.set_progress(100.0)
        elif item.status == "error":
            widget.set_error(item.error or "Unknown error")
        elif item.status == "cancelled":
            widget.set_status("Cancelled")

    # ─────────────────────────────────────────────────────────
    # Item actions (pause / cancel / open folder)
    # ─────────────────────────────────────────────────────────

    def _on_pause_item(self, idx: int) -> None:
        if idx >= len(self.workers) or idx >= len(self.widgets):
            return
        worker = self.workers[idx]
        item = self.items[idx]
        widget = self.widgets[idx]

        # Only allow pausing active downloads
        if item.status not in ("downloading", "Paused"):
            return

        worker.pause()
        if item.status == "downloading":
            item.status = "Paused"
            widget.set_status("Paused")
        else:
            item.status = "downloading"
            widget.set_status("Downloading")

    def _on_cancel_item(self, idx: int) -> None:
        if idx >= len(self.workers) or idx >= len(self.widgets):
            return
        worker = self.workers[idx]
        item = self.items[idx]
        widget = self.widgets[idx]

        if item.status in ("done", "Completed"):
            return

        worker.cancel()
        item.status = "cancelled"
        widget.set_progress(0)

    def _on_open_folder(self, idx: int) -> None:
        if idx >= len(self.items):
            return
        item = self.items[idx]
        output_dir = item.config.output_dir if item.config else ""
        if output_dir and os.path.isdir(output_dir):
            QDesktopServices.openUrl(QUrl.fromLocalFile(output_dir))

    # ─────────────────────────────────────────────────────────
    # Frameless window drag
    # ─────────────────────────────────────────────────────────

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self._drag_pos = (
                event.globalPosition().toPoint() - self.frameGeometry().topLeft()
            )

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.LeftButton and self._drag_pos is not None:
            self.move(event.globalPosition().toPoint() - self._drag_pos)

    def mouseReleaseEvent(self, event):
        self._drag_pos = None
