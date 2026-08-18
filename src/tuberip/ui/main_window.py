from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton,
    QListWidget, QListWidgetItem, QMessageBox, QLabel,
)
from PySide6.QtCore import Qt, QThread, Signal

from ..backend.models import DownloadItem, Mode, DownloadConfig
from ..backend.downloader import DependencyError, Downloader
from .widgets import (
    URLInput, ModeSelector, QualityCombo, AudioSettings,
    OutputFolder, SubtitlesGroup,
)
from .download_item_widget import DownloadItemWidget


class DownloadWorker(QThread):
    progress = Signal(float)
    status_changed = Signal(str)
    finished = Signal()

    def __init__(self, downloader: Downloader, item: DownloadItem):
        super().__init__()
        self.downloader = downloader
        self.item = item

    def run(self) -> None:
        self.downloader.download(
            self.item,
            on_progress=lambda p: self.progress.emit(p),
            on_status=lambda s: self.status_changed.emit(s),
        )
        self.finished.emit()


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("TubeRip")
        self.resize(720, 480)

        self.items: list[DownloadItem] = []
        self.workers: list[DownloadWorker] = []
        self.widgets: list[DownloadItemWidget] = []

        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)

        # --- Input area ---
        self.url_input = URLInput()
        self.mode_selector = ModeSelector()
        self.video_quality = QualityCombo()
        self.audio_settings = AudioSettings()
        self.output_folder = OutputFolder(
            default_path=(
                DownloadConfig().output_dir
            )
        )
        self.subtitles = SubtitlesGroup()

        form = QWidget()
        form_layout = QVBoxLayout(form)

        mode_layout = QHBoxLayout()
        mode_layout.addWidget(self.mode_selector)
        form_layout.addLayout(mode_layout)

        video_row = QHBoxLayout()
        video_row.addWidget(QLabel("Qualité vidéo:"))
        video_row.addWidget(self.video_quality)
        video_row.addStretch()
        form_layout.addLayout(video_row)

        form_layout.addWidget(self.audio_settings)
        form_layout.addWidget(self.output_folder)
        form_layout.addWidget(self.subtitles)

        main_layout.addWidget(self.url_input)
        main_layout.addWidget(form)

        # --- Actions ---
        actions = QHBoxLayout()
        self.download_btn = QPushButton("Télécharger")
        self.download_btn.clicked.connect(self.start_download)
        actions.addStretch()
        actions.addWidget(self.download_btn)
        main_layout.addLayout(actions)

        # --- Queue / History ---
        self.queue_list = QListWidget()
        main_layout.addWidget(QLabel("Téléchargements:"))
        main_layout.addWidget(self.queue_list, 1)

        self.mode_selector.mode_changed.connect(self._on_mode_changed)
        self._on_mode_changed("video")

    def _on_mode_changed(self, mode: str) -> None:
        is_video = mode == "video"
        self.video_quality.setEnabled(is_video)
        self.audio_settings.setEnabled(not is_video)

    def start_download(self) -> None:
        url = self.url_input.text()
        if not url:
            QMessageBox.warning(self, "Erreur", "Veuillez entrer une URL.")
            return

        mode = Mode(self.mode_selector.current_mode())
        config = DownloadConfig(
            mode=mode,
            quality=self.video_quality.currentText(),
            audio_format=self.audio_settings.format(),
            audio_quality=self.audio_settings.quality(),
            subtitle_lang=self.subtitles.lang(),
            download_subtitles=self.subtitles.download(),
            output_dir=self.output_folder.path() or DownloadConfig().output_dir,
        )

        item = DownloadItem(url=url, config=config)
        self.items.append(item)

        widget = DownloadItemWidget()
        widget.set_info(f"{url} — {mode.value}")
        widget.set_status("En attente")
        widget.set_progress(0.0)

        list_item = QListWidgetItem()
        list_item.setSizeHint(widget.sizeHint())
        self.queue_list.addItem(list_item)
        self.queue_list.setItemWidget(list_item, widget)

        self.widgets.append(widget)

        worker = DownloadWorker(Downloader(config), item)
        worker.progress.connect(self._on_progress)
        worker.status_changed.connect(self._on_status_changed)
        worker.finished.connect(lambda: self._on_finished(len(self.items) - 1))
        self.workers.append(worker)
        worker.start()

    def _on_progress(self, value: float) -> None:
        sender = self.sender()
        if not isinstance(sender, DownloadWorker):
            return
        idx = self.workers.index(sender)
        self.items[idx].progress = value
        if idx < len(self.widgets):
            self.widgets[idx].set_progress(value)

    def _on_status_changed(self, status: str) -> None:
        sender = self.sender()
        if not isinstance(sender, DownloadWorker):
            return
        idx = self.workers.index(sender)
        self.items[idx].status = status
        if idx < len(self.widgets):
            widget = self.widgets[idx]
            if status == "error" and self.items[idx].error:
                widget.set_error(self.items[idx].error)
            elif status == "done":
                widget.set_status("Terminé")
                widget.set_progress(100.0)
            elif status == "downloading":
                widget.set_status("Téléchargement...")
            else:
                widget.set_status(status)

    def _on_finished(self, idx: int) -> None:
        if idx < len(self.widgets):
            widget = self.widgets[idx]
            item = self.items[idx]
            if item.status == "done":
                widget.set_status("Terminé")
                widget.set_progress(100.0)
            elif item.status == "error":
                widget.set_error(item.error or "Erreur inconnue")
