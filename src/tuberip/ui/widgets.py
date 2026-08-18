from PySide6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFileDialog,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QSpinBox,
    QWidget,
)


class URLInput(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)

        self.input = QLineEdit()
        self.input.setPlaceholderText("Collez l'URL YouTube ici...")
        layout.addWidget(QLabel("URL:"))
        layout.addWidget(self.input)

    def text(self) -> str:
        return self.input.text().strip()

    def set_text(self, value: str) -> None:
        self.input.setText(value)


class ModeSelector(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)

        self.video_btn = QPushButton("Vidéo")
        self.video_btn.setCheckable(True)
        self.video_btn.setChecked(True)

        self.audio_btn = QPushButton("Audio")
        self.audio_btn.setCheckable(True)

        layout.addWidget(QLabel("Mode:"))
        layout.addWidget(self.video_btn)
        layout.addWidget(self.audio_btn)
        layout.addStretch()

        self.video_btn.clicked.connect(self._on_video)
        self.audio_btn.clicked.connect(self._on_audio)

    def _on_video(self):
        self.video_btn.setChecked(True)
        self.audio_btn.setChecked(False)
        self.mode_changed.emit("video")

    def _on_audio(self):
        self.audio_btn.setChecked(True)
        self.video_btn.setChecked(False)
        self.mode_changed.emit("audio")

    from PySide6.QtCore import Signal

    mode_changed = Signal(str)

    def current_mode(self) -> str:
        return "video" if self.video_btn.isChecked() else "audio"


class QualityCombo(QComboBox):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.addItems(["best", "1080", "720", "480"])


class AudioSettings(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QFormLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)

        self.format_combo = QComboBox()
        self.format_combo.addItems(["mp3", "m4a", "best"])

        self.quality_spin = QSpinBox()
        self.quality_spin.setRange(0, 9)
        self.quality_spin.setValue(0)

        layout.addRow("Format:", self.format_combo)
        layout.addRow("Qualité (0-9):", self.quality_spin)

    def format(self) -> str:
        return self.format_combo.currentText()

    def quality(self) -> str:
        return str(self.quality_spin.value())


class OutputFolder(QWidget):
    def __init__(self, default_path: str = "", parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)

        self.path_edit = QLineEdit(default_path)
        self.browse_btn = QPushButton("...")
        self.browse_btn.setFixedWidth(40)

        layout.addWidget(QLabel("Dossier:"))
        layout.addWidget(self.path_edit)
        layout.addWidget(self.browse_btn)

        self.browse_btn.clicked.connect(self._browse)

    def _browse(self):
        path = QFileDialog.getExistingDirectory(self, "Choisir le dossier")
        if path:
            self.path_edit.setText(path)

    def path(self) -> str:
        return self.path_edit.text().strip()


class SubtitlesGroup(QGroupBox):
    def __init__(self, parent=None):
        super().__init__("Sous-titres", parent)
        layout = QFormLayout(self)

        self.lang_edit = QLineEdit("fr,en")
        self.download_check = QCheckBox("Télécharger les sous-titres")
        self.download_check.setChecked(False)

        layout.addRow("Langue:", self.lang_edit)
        layout.addRow("", self.download_check)

    def lang(self) -> str:
        return self.lang_edit.text().strip()

    def download(self) -> bool:
        return self.download_check.isChecked()
