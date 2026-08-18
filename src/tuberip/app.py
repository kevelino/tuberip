import os
import sys
from pathlib import Path

from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication

from .ui.main_window import MainWindow


def _resource_path(relative: str) -> str:
    base = getattr(sys, "_MEIPASS", None)
    if base:
        return os.path.join(base, relative)
    return str(Path(__file__).parent / relative)


def _load_styles(app: QApplication) -> None:
    style_path = _resource_path(os.path.join("ui", "styles.qss"))
    if os.path.exists(style_path):
        with open(style_path, "r", encoding="utf-8") as fh:
            app.setStyleSheet(fh.read())


def _set_icon(app: QApplication) -> None:
    icon_path = _resource_path(os.path.join("tuberip", "assets", "tuberip.svg"))
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("TubeRip")
    app.setOrganizationName("TubeRip")

    _load_styles(app)
    _set_icon(app)

    window = MainWindow()
    window.show()

    return app.exec()
