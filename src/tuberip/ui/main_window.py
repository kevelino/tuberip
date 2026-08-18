from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton,
    QProgressBar, QListWidget, QListWidgetItem, QMessageBox, QSplitter,
    QLabel,
)
from PySide6.QtCore import Qt, QThread, Signal
from PySide6.QtGui import QColor

from ..backend.models import DownloadItem, Mode, DownloadConfig
from ..backend.downloader import DependencyError, Downloader
from .widgets import (
    URLInput, ModeSelector, QualityCombo, AudioSettings,
    OutputFolder, SubtitlesGroup,
)


class DownloadWorker(QThread):
    progress = Signal(float)
    status_changed = Signal(str)
    finished = Signal()

    def __init__(self, downloader: Downloader, item: DownloadItem):
        super().__init__()
        self.downloader = downloader
        self.item = item

    def run(self) -> None:
        self.downloader.download(self.item)
        self.finished.emit()


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("TubeRip")
        self.resize(720, 480)

        self.items: list[DownloadItem] = []
        self.workers: list[DownloadWorker] = []

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

        list_item = QListWidgetItem(f"{url} — {mode.value} — En attente")
        list_item.setData(Qt.UserRole, len(self.items) - 1)
        self.queue_list.addItem(list_item)

        self._update_item_display(len(self.items) - 1)

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
        self._update_item_display(idx)

    def _on_status_changed(self, status: str) -> None:
        sender = self.sender()
        if not isinstance(sender, DownloadWorker):
            return
        idx = self.workers.index(sender)
        self.items[idx].status = status
        self._update_item_display(idx)

    def _on_finished(self, idx: int) -> None:
        self._update_item_display(idx)

    def _update_item_display(self, idx: int) -> None:
        item = self.items[idx]
        list_item = self.queue_list.item(idx)
        if list_item is None:
            return
        status_label = {
            "pending": "En attente",
            "downloading": f"Téléchargement {item.progress:.0f}%",
            "done": "Terminé",
            "error": f"Erreur: {item.error or 'inconnue'}",
        }.get(item.status, item.status)
        list_item.setText(f"{item.url} — {item.config.mode.value if item.config else ''} — {status_label}")
