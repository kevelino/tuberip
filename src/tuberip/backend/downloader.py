import os
import shutil
import subprocess
import sys
from typing import List, Optional

from .models import DownloadConfig, DownloadItem, Mode


class DependencyError(Exception):
    pass


class Downloader:
    def __init__(self, config: Optional[DownloadConfig] = None):
        self.config = config or DownloadConfig()

    @staticmethod
    def check_dependencies() -> None:
        missing: List[str] = []

        if shutil.which("yt-dlp") is None:
            missing.append("yt-dlp")

        if shutil.which("ffmpeg") is None:
            missing.append("ffmpeg")

        if missing:
            raise DependencyError(
                "Missing dependencies: " + ", ".join(missing) +
                ". Install them and retry."
            )

    @staticmethod
    def build_url(video_id: str) -> str:
        if video_id.startswith("http"):
            return video_id
        return f"https://www.youtube.com/watch?v={video_id}"

    def build_format(self) -> str:
        if self.config.mode == Mode.AUDIO:
            return "bestaudio/best"

        quality = self.config.quality
        if quality == "best":
            return (
                "bestvideo[ext=mp4]+bestaudio[ext=m4a]/"
                "bestvideo+bestaudio/best"
            )
        return (
            f"bestvideo[height<={quality}][ext=mp4]+"
            f"bestaudio[ext=m4a]/"
            f"best[height<={quality}]"
        )

    def build_command(self, url: str) -> List[str]:
        output_template = os.path.join(
            self.config.output_dir, "%(title)s [%(id)s].%(ext)s"
        )

        command: List[str] = [
            "yt-dlp",
            "--cookies-from-browser",
            "firefox",
            "--remote-components",
            "ejs:github",
            "-o",
            output_template,
            "--embed-thumbnail",
            "--add-metadata",
            "--retries",
            "10",
            "--fragment-retries",
            "10",
            "--socket-timeout",
            "30",
            "--no-abort-on-error",
            "--progress",
        ]

        if self.config.mode == Mode.AUDIO:
            command += [
                "-x",
                "--audio-format",
                self.config.audio_format,
                "--audio-quality",
                self.config.audio_quality,
            ]
        else:
            command += [
                "-f",
                self.build_format(),
                "--merge-output-format",
                "mp4",
            ]

        if self.config.download_subtitles:
            command += [
                "--write-sub",
                "--write-auto-sub",
                "--sub-lang",
                self.config.subtitle_lang,
                "--convert-subs",
                "srt",
            ]

        command.append(url)
        return command

    def download(
        self,
        item: DownloadItem,
        on_progress=None,
        on_status=None,
    ) -> None:
        self.check_dependencies()

        url = self.build_url(item.url)
        item.url = url
        item.config = self.config
        item.status = "downloading"
        item.progress = 0.0
        item.error = None

        if on_status:
            on_status("downloading")

        command = self.build_command(url)

        try:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )

            for line in process.stdout:
                line = line.strip()
                if "[download]" in line and "%" in line:
                    try:
                        percent_str = line.split("%")[0].split()[-1]
                        item.progress = float(percent_str)
                        if on_progress:
                            on_progress(item.progress)
                    except (IndexError, ValueError):
                        pass

            process.wait()

            if process.returncode == 0:
                item.status = "done"
                item.progress = 100.0
                if on_progress:
                    on_progress(100.0)
                if on_status:
                    on_status("done")
            else:
                item.status = "error"
                item.error = f"yt-dlp exited with code {process.returncode}"
                if on_status:
                    on_status("error")

        except FileNotFoundError as exc:
            item.status = "error"
            item.error = f"Command not found: {exc}"
            if on_status:
                on_status("error")
        except Exception as exc:
            item.status = "error"
            item.error = str(exc)
            if on_status:
                on_status("error")
