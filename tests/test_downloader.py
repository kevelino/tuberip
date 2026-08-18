from unittest.mock import patch

import pytest

from tuberip.backend.downloader import DependencyError, Downloader
from tuberip.backend.models import DownloadConfig, DownloadItem, Mode


def test_build_url_from_id():
    assert Downloader.build_url("abc123") == "https://www.youtube.com/watch?v=abc123"


def test_build_url_from_full_url():
    assert Downloader.build_url("https://youtu.be/abc123") == "https://youtu.be/abc123"


def test_build_format_best():
    config = DownloadConfig(mode=Mode.VIDEO, quality="best")
    downloader = Downloader(config)
    assert "bestvideo" in downloader.build_format()


def test_build_format_720():
    config = DownloadConfig(mode=Mode.VIDEO, quality="720")
    downloader = Downloader(config)
    assert "height<=720" in downloader.build_format()


def test_build_format_audio():
    config = DownloadConfig(mode=Mode.AUDIO)
    downloader = Downloader(config)
    assert downloader.build_format() == "bestaudio/best"


def test_build_command_audio():
    config = DownloadConfig(
        mode=Mode.AUDIO,
        audio_format="mp3",
        audio_quality="0",
    )
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "-x" in cmd
    assert "--audio-format" in cmd
    assert "mp3" in cmd
    assert "--audio-quality" in cmd
    assert "0" in cmd


def test_build_command_video():
    config = DownloadConfig(mode=Mode.VIDEO, quality="720")
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "-f" in cmd
    assert "--merge-output-format" in cmd
    assert "mp4" in cmd
    assert "-x" not in cmd


def test_download_command_output_template():
    config = DownloadConfig(output_dir="/tmp/tuberip-test")
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert any("/tmp/tuberip-test" in part for part in cmd)


def test_check_dependencies_raises_when_missing():
    with patch("tuberip.backend.downloader.shutil.which", return_value=None):
        with pytest.raises(DependencyError):
            Downloader.check_dependencies()


def test_download_item_defaults():
    item = DownloadItem(url="https://youtube.com/watch?v=abc123")
    assert item.status == "pending"
    assert item.progress == 0.0
    assert item.error is None


def test_download_config_defaults():
    config = DownloadConfig()
    assert config.mode == Mode.VIDEO
    assert config.quality == "480"
    assert config.audio_format == "mp3"
    assert config.audio_quality == "0"
    assert config.download_subtitles is False
