from __future__ import annotations

import os
from dataclasses import dataclass, field
from enum import Enum


class Mode(str, Enum):
    VIDEO = "video"
    AUDIO = "audio"


@dataclass
class DownloadConfig:
    mode: Mode = Mode.VIDEO
    quality: str = "480"
    audio_format: str = "mp3"
    audio_quality: str = "0"
    subtitle_lang: str = "en,fr"
    download_subtitles: bool = False
    embed_thumbnail: bool = True
    embed_metadata: bool = True
    rate_limit: str = ""
    output_dir: str = field(
        default_factory=lambda: os.path.join(
            os.path.expanduser("~"), "Downloads", "YouTube"
        )
    )


@dataclass
class DownloadItem:
    url: str
    title: str = ""
    status: str = "pending"
    progress: float = 0.0
    error: str | None = None
    config: DownloadConfig | None = None
