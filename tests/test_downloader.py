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


def test_build_command_embed_thumbnail():
    config = DownloadConfig(
        mode=Mode.VIDEO, quality="best", embed_thumbnail=True
    )
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "--embed-thumbnail" in cmd


def test_build_command_no_embed_thumbnail():
    config = DownloadConfig(
        mode=Mode.VIDEO, quality="best", embed_thumbnail=False
    )
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "--embed-thumbnail" not in cmd


def test_build_command_embed_metadata():
    config = DownloadConfig(
        mode=Mode.VIDEO, quality="best", embed_metadata=True
    )
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "--embed-metadata" in cmd


def test_build_command_rate_limit():
    config = DownloadConfig(
        mode=Mode.VIDEO, quality="best", rate_limit="5M"
    )
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "--limit-rate" in cmd
    assert "5M" in cmd


def test_build_command_no_rate_limit_when_empty():
    config = DownloadConfig(mode=Mode.VIDEO, quality="best", rate_limit="")
    downloader = Downloader(config)
    cmd = downloader.build_command("https://youtube.com/watch?v=abc123")
    assert "--limit-rate" not in cmd


def test_parse_speed_info():
    line = "[download]  12.3% of 4.56MiB at 1.23MiB/s ETA 00:03:45"
    result = Downloader._parse_speed_info(line)
    assert result is not None
    assert "MiB/s" in result
    assert "ETA" in result


def test_parse_speed_info_no_speed():
    line = "[download]  Destination: /tmp/video.mp4"
    result = Downloader._parse_speed_info(line)
    assert result is None


def test_check_dependencies_raises_when_missing():
    with (
        patch("tuberip.backend.downloader.shutil.which", return_value=None),
        pytest.raises(DependencyError),
    ):
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
    assert config.embed_thumbnail is True
    assert config.embed_metadata is True
    assert config.rate_limit == ""
