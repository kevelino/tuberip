from __future__ import annotations

from typing import ClassVar

from PySide6.QtCore import QSettings, Qt
from PySide6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QDialog,
    QDialogButtonBox,
    QFileDialog,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QSlider,
    QSpinBox,
    QTextBrowser,
    QVBoxLayout,
    QWidget,
)

# ─────────────────────────────────────────────────────────────────────────────
# URL Input
# ─────────────────────────────────────────────────────────────────────────────

class URLInput(QWidget):
    """URL/ID input field with label, matching the mockup."""

    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 6)
        layout.setSpacing(6)

        label = QLabel("Paste YouTube Video URL or ID")
        label.setObjectName("inputLabel")

        self.input = QLineEdit()
        self.input.setObjectName("urlInput")
        self.input.setPlaceholderText("https://www.youtube.com/watch?v=...")
        self.input.setMinimumHeight(38)

        layout.addWidget(label)
        layout.addWidget(self.input)

    def text(self) -> str:
        return self.input.text().strip()

    def set_text(self, value: str) -> None:
        self.input.setText(value)


# ─────────────────────────────────────────────────────────────────────────────
# Format Selector
# ─────────────────────────────────────────────────────────────────────────────

class FormatSelector(QComboBox):
    """Video / Audio format dropdown."""

    VIDEO_ITEMS: ClassVar[list[str]] = ["Video (MP4)", "Video (MKV)", "Video (WEBM)"]
    AUDIO_ITEMS: ClassVar[list[str]] = ["Audio (MP3)", "Audio (M4A)", "Audio (OPUS)"]

    def __init__(self, parent=None):
        super().__init__(parent)
        self.addItems(self.VIDEO_ITEMS + self.AUDIO_ITEMS)
        self.setMinimumHeight(38)

    def is_video(self) -> bool:
        return self.currentText().startswith("Video")

    def audio_format(self) -> str:
        text = self.currentText()
        if "MP3" in text:
            return "mp3"
        if "M4A" in text:
            return "m4a"
        return "opus"


# ─────────────────────────────────────────────────────────────────────────────
# Quality Selector
# ─────────────────────────────────────────────────────────────────────────────

class QualitySelector(QComboBox):
    """Quality preset dropdown, updated based on format."""

    VIDEO_PRESETS: ClassVar[list[str]] = [
        "1080p Full HD • 30fps • ~145MB",
        "720p HD • 30fps • ~85MB",
        "480p SD • 30fps • ~45MB",
        "360p • ~25MB",
        "best",
    ]
    AUDIO_PRESETS: ClassVar[list[str]] = [
        "MP3 320kbps • ~45MB",
        "MP3 192kbps • ~28MB",
        "MP3 128kbps • ~18MB",
        "M4A 128kbps • ~15MB",
        "best",
    ]

    def __init__(self, parent=None):
        super().__init__(parent)
        self.addItems(self.VIDEO_PRESETS)
        self.setMinimumHeight(38)

    def set_video(self):
        self.clear()
        self.addItems(self.VIDEO_PRESETS)

    def set_audio(self):
        self.clear()
        self.addItems(self.AUDIO_PRESETS)

    def quality_value(self) -> str:
        """Return the raw quality token (e.g. '1080', 'best')."""
        text = self.currentText()
        part = text.split("p")[0].strip()
        if part.isdigit():
            return part
        return "best"


# ─────────────────────────────────────────────────────────────────────────────
# Save-to Row  (editable path + folder-picker button)
# ─────────────────────────────────────────────────────────────────────────────

class SaveToRow(QWidget):
    """'Save to: [editable path input]  [📁]' row matching the mockup."""

    def __init__(self, default_path: str = "", parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(8)

        self.save_label = QLabel("Save to:")
        self.save_label.setObjectName("saveToLabel")

        self.path_edit = QLineEdit(default_path or "~/Downloads/YouTube")
        self.path_edit.setObjectName("urlInput")
        self.path_edit.setMinimumHeight(36)
        self.path_edit.setPlaceholderText("~/Downloads/YouTube")
        self.path_edit.setToolTip("Type or paste a folder path, or click 📁 to browse")
        self.path_edit.setClearButtonEnabled(True)

        self.folder_btn = QPushButton("📁")
        self.folder_btn.setObjectName("folderBtn")
        self.folder_btn.setFixedSize(36, 36)
        self.folder_btn.setToolTip("Browse for download folder")

        layout.addWidget(self.save_label)
        layout.addWidget(self.path_edit, 1)
        layout.addWidget(self.folder_btn)

        self.folder_btn.clicked.connect(self._browse)

    def _browse(self):
        current = self.path_edit.text().strip() or ""
        path = QFileDialog.getExistingDirectory(
            self, "Select Download Folder", current
        )
        if path:
            self.path_edit.setText(path)

    def path(self) -> str:
        return self.path_edit.text().strip()


# ─────────────────────────────────────────────────────────────────────────────
# Settings Dialog
# ─────────────────────────────────────────────────────────────────────────────

class SettingsDialog(QDialog):
    """
    Advanced settings dialog opened by the ⚙ button.
    Uses QSettings for persistence.

    Exposes via ``values()``:
      - audio_quality  (str, "0"–"9")
      - subtitle_lang  (comma-sep language codes, e.g. 'en,fr')
      - download_subtitles (bool)
      - embed_thumbnail    (bool)
      - embed_metadata     (bool)
      - rate_limit         (str, e.g. '5M' or empty)
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings("TubeRip", "TubeRip")
        self.setWindowTitle("Advanced Settings")
        self.setMinimumWidth(460)
        self.setModal(True)

        root = QVBoxLayout(self)
        root.setSpacing(16)
        root.setContentsMargins(24, 24, 24, 24)

        # ── Header ────────────────────────────────────────────
        title = QLabel("Advanced Settings")
        title.setObjectName("sectionTitle")
        title.setStyleSheet("font-size: 16px; font-weight: 700; color: #ffffff;")
        root.addWidget(title)

        sub = QLabel("Configure download behaviour and metadata options.")
        sub.setObjectName("sectionSubtitle")
        root.addWidget(sub)

        # ── Audio Quality ─────────────────────────────────────
        audio_group = QGroupBox("Audio Quality (VBR 0 = best, 9 = smallest)")
        audio_layout = QHBoxLayout(audio_group)

        self.audio_quality_spin = QSpinBox()
        self.audio_quality_spin.setRange(0, 9)
        self.audio_quality_spin.setToolTip("0 = best quality, 9 = smallest file")
        self.audio_quality_spin.setMinimumHeight(34)

        self.audio_quality_slider = QSlider(Qt.Horizontal)
        self.audio_quality_slider.setRange(0, 9)
        self.audio_quality_slider.setTickPosition(QSlider.TicksBelow)
        self.audio_quality_slider.setTickInterval(1)

        # Keep spin & slider in sync
        self.audio_quality_spin.valueChanged.connect(self.audio_quality_slider.setValue)
        self.audio_quality_slider.valueChanged.connect(self.audio_quality_spin.setValue)

        audio_layout.addWidget(self.audio_quality_spin)
        audio_layout.addWidget(self.audio_quality_slider, 1)
        root.addWidget(audio_group)

        # ── Subtitles ─────────────────────────────────────────
        sub_group = QGroupBox("Subtitles")
        sub_form = QFormLayout(sub_group)
        sub_form.setSpacing(10)

        self.download_subs_check = QCheckBox("Download subtitles")
        self.download_subs_check.setToolTip("Embed subtitles into the output file")

        self.sub_lang_edit = QLineEdit()
        self.sub_lang_edit.setObjectName("urlInput")
        self.sub_lang_edit.setMinimumHeight(34)
        self.sub_lang_edit.setPlaceholderText("e.g. en, fr, de")
        self.sub_lang_edit.setToolTip("Comma-separated language codes")

        sub_form.addRow("", self.download_subs_check)
        sub_form.addRow("Languages:", self.sub_lang_edit)
        root.addWidget(sub_group)

        # ── Metadata & Extras ─────────────────────────────────
        meta_group = QGroupBox("Metadata & Extras")
        meta_layout = QVBoxLayout(meta_group)

        self.embed_thumb_check = QCheckBox("Embed thumbnail into file")
        self.embed_thumb_check.setToolTip("Embed the video thumbnail as cover art")

        self.embed_meta_check = QCheckBox("Embed video metadata (title, artist…)")
        self.embed_meta_check.setToolTip("Write metadata tags to the output file")

        meta_layout.addWidget(self.embed_thumb_check)
        meta_layout.addWidget(self.embed_meta_check)
        root.addWidget(meta_group)

        # ── Network ───────────────────────────────────────────
        net_group = QGroupBox("Network")
        net_form = QFormLayout(net_group)
        net_form.setSpacing(10)

        self.rate_limit_edit = QLineEdit()
        self.rate_limit_edit.setObjectName("urlInput")
        self.rate_limit_edit.setMinimumHeight(34)
        self.rate_limit_edit.setPlaceholderText("e.g. 5M, 500K  (empty = unlimited)")
        self.rate_limit_edit.setToolTip("Maximum download speed (e.g. 5M = 5 MB/s)")

        net_form.addRow("Rate limit:", self.rate_limit_edit)
        root.addWidget(net_group)

        # ── Buttons ───────────────────────────────────────────
        buttons = QDialogButtonBox(
            QDialogButtonBox.Ok | QDialogButtonBox.Cancel
        )
        buttons.button(QDialogButtonBox.Ok).setObjectName("downloadBtn")
        buttons.button(QDialogButtonBox.Ok).setText("Apply")
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        root.addWidget(buttons)

        # ── Load saved values from QSettings ─────────────────
        self._load_settings()

    def _load_settings(self) -> None:
        s = self._settings
        self.audio_quality_spin.setValue(s.value("audio_quality", 0, type=int))
        self.sub_lang_edit.setText(s.value("subtitle_lang", "en,fr"))
        self.download_subs_check.setChecked(s.value("download_subtitles", False, type=bool))
        self.embed_thumb_check.setChecked(s.value("embed_thumbnail", True, type=bool))
        self.embed_meta_check.setChecked(s.value("embed_metadata", True, type=bool))
        self.rate_limit_edit.setText(s.value("rate_limit", ""))

    def accept(self) -> None:
        s = self._settings
        s.setValue("audio_quality", self.audio_quality_spin.value())
        s.setValue("subtitle_lang", self.sub_lang_edit.text().strip())
        s.setValue("download_subtitles", self.download_subs_check.isChecked())
        s.setValue("embed_thumbnail", self.embed_thumb_check.isChecked())
        s.setValue("embed_metadata", self.embed_meta_check.isChecked())
        s.setValue("rate_limit", self.rate_limit_edit.text().strip())
        super().accept()

    def values(self) -> dict:
        return {
            "audio_quality":      str(self.audio_quality_spin.value()),
            "subtitle_lang":      self.sub_lang_edit.text().strip(),
            "download_subtitles": self.download_subs_check.isChecked(),
            "embed_thumbnail":    self.embed_thumb_check.isChecked(),
            "embed_metadata":     self.embed_meta_check.isChecked(),
            "rate_limit":         self.rate_limit_edit.text().strip(),
        }


# ─────────────────────────────────────────────────────────────────────────────
# Help Dialog
# ─────────────────────────────────────────────────────────────────────────────

class HelpDialog(QDialog):
    """About / Help dialog shown by the ? button."""

    HELP_TEXT = """\
<h2>TubeRip</h2>

<p><b>Cross-distro Linux desktop app</b> for downloading YouTube videos or
extracting audio. Built with PySide6 and <code>yt-dlp</code>.</p>

<h3 style="color:#11eef9;">Quick Start</h3>
<ol>
  <li><b>Paste a URL</b> — Enter a YouTube video URL or just the video ID
      in the input field.</li>
  <li><b>Select format &amp; quality</b> — Choose <b>Video</b> (MP4/MKV/WEBM)
      or <b>Audio</b> (MP3/M4A/OPUS) and a quality preset.</li>
  <li><b>Choose save location</b> — The default is
      <code>~/Downloads/YouTube</code>. Click the <b>📁</b> button to browse
      for another folder.</li>
  <li><b>Download</b> — Click <b>Download Video</b> (or <b>Download Audio</b>).
      The item appears in the queue with live progress.</li>
</ol>

<h3 style="color:#11eef9;">Queue Controls</h3>
<ul>
  <li><b>⏸ Pause</b> — Suspend an active download. Click again (⏵) to resume.</li>
  <li><b>✕ Cancel</b> — Stop and remove a pending or active download.</li>
  <li><b>📁 Open folder</b> — After completion, click the folder icon to open
      the file in your file manager.</li>
</ul>

<h3 style="color:#11eef9;">Advanced Settings</h3>
<p>Press <b>⚙ Settings</b> in the title bar to open the advanced settings:</p>
<ul>
  <li><b>Audio Quality</b> — VBR 0 (best) through 9 (smallest).</li>
  <li><b>Subtitles</b> — Download subtitles in selected languages.</li>
  <li><b>Metadata &amp; Extras</b> — Embed thumbnail and/or metadata tags.</li>
  <li><b>Rate limit</b> — Throttle bandwidth (e.g. <code>5M</code> for 5 MB/s).</li>
</ul>

<h3 style="color:#11eef9;">Keyboard Shortcuts</h3>
<table>
  <tr><td><b>Enter</b></td><td>Start download</td></tr>
  <tr><td><b>Ctrl + S</b></td><td>Open settings</td></tr>
  <tr><td><b>Ctrl + Q</b></td><td>Quit application</td></tr>
  <tr><td><b>Esc</b></td><td>Close dialog</td></tr>
</table>

<h3 style="color:#11eef9;">Dependencies</h3>
<p>This app requires <code>yt-dlp</code> and <code>ffmpeg</code> to be
   installed and on your <code>PATH</code>. If either is missing, an error
   message will be shown.</p>

<h3 style="color:#11eef9;">License</h3>
<p>MIT — see the bundled <code>LICENSE</code> file.</p>
"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Help — TubeRip")
        self.setMinimumWidth(480)
        self.setMinimumHeight(420)
        self.setModal(True)

        root = QVBoxLayout(self)
        root.setContentsMargins(24, 24, 24, 24)

        header = QLabel("Help")
        header.setObjectName("sectionTitle")
        header.setStyleSheet("font-size: 16px; font-weight: 700; color: #ffffff;")
        root.addWidget(header)

        browser = QTextBrowser()
        browser.setOpenExternalLinks(False)
        browser.setReadOnly(True)
        browser.setHtml(self.HELP_TEXT)
        root.addWidget(browser, 1)

        buttons = QDialogButtonBox(QDialogButtonBox.Ok)
        close_btn = buttons.button(QDialogButtonBox.Ok)
        close_btn.setText("Close")
        close_btn.setObjectName("itemActionBtn")
        buttons.accepted.connect(self.accept)
        root.addWidget(buttons)
