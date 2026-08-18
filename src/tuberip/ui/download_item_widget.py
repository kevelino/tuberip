from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (
    QHBoxLayout,
    QLabel,
    QProgressBar,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

STATUS_STYLES = {
    "Downloading": ("statusDownloading", "●"),
    "Completed":   ("statusCompleted",   "✓"),
    "Queued":      ("statusQueued",      "○"),
    "Paused":      ("statusPaused",      "⏸"),
    "Error":       ("statusError",       "✕"),
    "Cancelled":   ("statusCancelled",   "⊘"),
}


class DownloadItemWidget(QWidget):
    """
    A single row in the download queue, matching the mockup layout:

        [idx]  [title / meta]          [● Status  speed info]  [✕] [||]
                                [━━━━━░░░░░░░░░░░░░░]
    """

    pause_requested = Signal()
    cancel_requested = Signal()
    open_folder_requested = Signal()

    def __init__(self, index: int, title: str = "", parent=None):
        super().__init__(parent)
        self.setMinimumHeight(72)
        self._is_completed = False

        root = QHBoxLayout(self)
        root.setContentsMargins(16, 12, 16, 12)
        root.setSpacing(16)

        # ── Index ────────────────────────────────────────────
        self.idx_label = QLabel(str(index))
        self.idx_label.setObjectName("itemIndex")
        self.idx_label.setFixedWidth(18)
        self.idx_label.setAlignment(Qt.AlignTop | Qt.AlignHCenter)
        root.addWidget(self.idx_label)

        # ── Title + Meta + Progress ──────────────────────────
        info_col = QVBoxLayout()
        info_col.setSpacing(3)
        info_col.setContentsMargins(0, 0, 0, 0)

        self.title_label = QLabel(title or "Fetching title…")
        self.title_label.setObjectName("itemTitle")
        self.title_label.setWordWrap(True)

        self.meta_label = QLabel("Pending")
        self.meta_label.setObjectName("itemMeta")

        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        self.progress_bar.setTextVisible(False)
        self.progress_bar.setFixedHeight(5)

        info_col.addWidget(self.title_label)
        info_col.addWidget(self.meta_label)
        info_col.addWidget(self.progress_bar)
        root.addLayout(info_col, 2)

        # ── Status column ────────────────────────────────────
        status_col = QVBoxLayout()
        status_col.setSpacing(2)
        status_col.setContentsMargins(0, 0, 0, 0)
        status_col.setAlignment(Qt.AlignTop)

        # Row: dot label + text label
        status_row = QHBoxLayout()
        status_row.setSpacing(5)

        self.dot_label = QLabel("○")
        self.dot_label.setObjectName("statusQueued")

        self.status_label = QLabel("Queued")
        self.status_label.setObjectName("statusQueued")

        status_row.addWidget(self.dot_label)
        status_row.addWidget(self.status_label)
        status_row.addStretch()

        self.info_label = QLabel("")    # speed / remaining / size info
        self.info_label.setObjectName("statusInfo")

        status_col.addLayout(status_row)
        status_col.addWidget(self.info_label)
        root.addLayout(status_col, 1)

        # ── Action Buttons ───────────────────────────────────
        btn_col = QVBoxLayout()
        btn_col.setSpacing(6)
        btn_col.setAlignment(Qt.AlignTop | Qt.AlignRight)

        self.cancel_btn = QPushButton("✕")
        self.cancel_btn.setObjectName("itemActionBtn")
        self.cancel_btn.setFixedSize(30, 30)
        self.cancel_btn.setToolTip("Cancel download")

        self.pause_btn = QPushButton("⏸")
        self.pause_btn.setObjectName("itemActionBtn")
        self.pause_btn.setFixedSize(30, 30)
        self.pause_btn.setToolTip("Pause download")

        btn_col.addWidget(self.cancel_btn)
        btn_col.addWidget(self.pause_btn)
        root.addLayout(btn_col)

        # ── Signal connections ──────────────────────────────
        self.cancel_btn.clicked.connect(self._on_cancel_clicked)
        self.pause_btn.clicked.connect(self.pause_requested)

    def _on_cancel_clicked(self) -> None:
        if self._is_completed:
            self.open_folder_requested.emit()
        else:
            self.cancel_requested.emit()

    def set_paused(self, paused: bool) -> None:
        """Toggle pause button between pause (⏸) and resume (⏵) visuals."""
        if paused:
            self.pause_btn.setText("⏵")
            self.pause_btn.setToolTip("Resume download")
        else:
            self.pause_btn.setText("⏸")
            self.pause_btn.setToolTip("Pause download")

    # ── Public API ───────────────────────────────────────────

    def set_title(self, text: str) -> None:
        self.title_label.setText(text)

    def set_info(self, text: str) -> None:
        self.meta_label.setText(text)

    def set_speed_info(self, text: str) -> None:
        self.info_label.setText(text)

    def set_progress(self, value: float) -> None:
        self.progress_bar.setValue(int(value))

    def set_status(self, status: str) -> None:
        """status: 'Queued' | 'Downloading' | 'Paused' | 'Completed' | 'Error' | 'Cancelled'"""
        obj_name, dot = STATUS_STYLES.get(status, ("statusQueued", "○"))
        self.dot_label.setText(dot)
        self.dot_label.setObjectName(obj_name)
        self.status_label.setText(status)
        self.status_label.setObjectName(obj_name)
        # Force Qt to re-apply stylesheet after objectName change
        self.dot_label.setStyle(self.dot_label.style())
        self.status_label.setStyle(self.status_label.style())

        if status == "Completed":
            self._is_completed = True
            self.pause_btn.hide()
            self.set_paused(False)
            self.cancel_btn.setText("📁")
            self.cancel_btn.setToolTip("Open folder")
        elif status == "Paused":
            self.set_paused(True)
        elif status == "Downloading":
            self._is_completed = False
            self.pause_btn.show()
            self.set_paused(False)
            self.cancel_btn.setText("✕")
            self.cancel_btn.setToolTip("Cancel download")

    def set_error(self, error: str) -> None:
        self.set_status("Error")
        self.info_label.setText(error[:60])
