import os
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


class Mode(str, Enum):
    VIDEO = "video"
    AUDIO = "audio"


@dataclass
class DownloadConfig:
    mode: Mode = Mode.VIDEO
    quality: str = "480"
    audio_format: str = "mp3"
    audio_quality: str = "0"
    subtitle_lang: str = "fr,en"
    download_subtitles: bool = False
    output_dir: str = field(
        default_factory=lambda: (
            os.path.join(os.path.expanduser("~"), "Downloads", "YouTube")
        )
    )


@dataclass
class DownloadItem:
    url: str
    title: str = ""
    status: str = "pending"
    progress: float = 0.0
    error: Optional[str] = None
    config: Optional[DownloadConfig] = None
