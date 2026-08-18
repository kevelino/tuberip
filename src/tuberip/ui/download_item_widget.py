from PySide6.QtWidgets import QWidget, QVBoxLayout, QLabel, QProgressBar
from PySide6.QtCore import Qt


class DownloadItemWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        layout.setSpacing(4)

        self.info_label = QLabel("")
        self.info_label.setWordWrap(True)
        self.info_label.setTextInteractionFlags(Qt.TextSelectableByMouse)

        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)

        self.status_label = QLabel("En attente")
        self.status_label.setStyleSheet("color: #6b7280;")

        layout.addWidget(self.info_label)
        layout.addWidget(self.progress_bar)
        layout.addWidget(self.status_label)

    def set_info(self, text: str) -> None:
        self.info_label.setText(text)

    def set_progress(self, value: float) -> None:
        self.progress_bar.setValue(int(value))

    def set_status(self, text: str) -> None:
        self.status_label.setText(text)

    def set_error(self, error: str) -> None:
        self.status_label.setText(f"Erreur: {error}")
        self.status_label.setStyleSheet("color: #dc2626;")
