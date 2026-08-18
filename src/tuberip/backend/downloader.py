from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
from typing import Callable

from .models import DownloadConfig, DownloadItem, Mode


class DependencyError(Exception):
    pass


class Downloader:
    def __init__(self, config: DownloadConfig | None = None):
        self.config  = config or DownloadConfig()
        self._proc: subprocess.Popen[str] | None = None
        self._paused = False

    # ─────────────────────────────────────────────────────────
    # Dependency check
    # ─────────────────────────────────────────────────────────

    @staticmethod
    def check_dependencies() -> None:
        missing: list[str] = []
        if shutil.which("yt-dlp") is None:
            missing.append("yt-dlp")
        if shutil.which("ffmpeg") is None:
            missing.append("ffmpeg")
        if missing:
            raise DependencyError(
                "Missing dependencies: " + ", ".join(missing) + ". Install them and retry."
            )

    # ─────────────────────────────────────────────────────────
    # URL helper
    # ─────────────────────────────────────────────────────────

    @staticmethod
    def build_url(video_id: str) -> str:
        if video_id.startswith("http"):
            return video_id
        return f"https://www.youtube.com/watch?v={video_id}"

    # ─────────────────────────────────────────────────────────
    # Command builder
    # ─────────────────────────────────────────────────────────

    def build_format(self) -> str:
        if self.config.mode == Mode.AUDIO:
            return "bestaudio/best"
        quality = self.config.quality
        if quality == "best":
            return "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"
        return (
            f"bestvideo[height<={quality}][ext=mp4]+"
            f"bestaudio[ext=m4a]/"
            f"best[height<={quality}]"
        )

    def build_command(self, url: str) -> list[str]:
        output_template = os.path.join(
            self.config.output_dir, "%(title)s [%(id)s].%(ext)s"
        )
        cmd: list[str] = [
            "yt-dlp",
            "-o", output_template,
            "--retries", "10",
            "--fragment-retries", "10",
            "--socket-timeout", "30",
            "--no-abort-on-error",
            "--progress",
        ]

        if self.config.mode == Mode.AUDIO:
            cmd += [
                "-x",
                "--audio-format", self.config.audio_format,
                "--audio-quality", self.config.audio_quality,
            ]
        else:
            cmd += [
                "-f", self.build_format(),
                "--merge-output-format", "mp4",
            ]

        if self.config.download_subtitles:
            cmd += [
                "--write-sub",
                "--write-auto-sub",
                "--sub-lang", self.config.subtitle_lang,
                "--convert-subs", "srt",
            ]

        if self.config.embed_thumbnail:
            cmd += ["--embed-thumbnail"]

        if self.config.embed_metadata:
            cmd += ["--embed-metadata"]

        if self.config.rate_limit:
            cmd += ["--limit-rate", self.config.rate_limit]

        cmd.append(url)
        return cmd

    # ─────────────────────────────────────────────────────────
    # Metadata (title, etc.)
    # ─────────────────────────────────────────────────────────

    def fetch_metadata(self, url: str) -> dict:
        """Fetch video metadata via yt-dlp --dump-json. Returns {} on failure."""
        full_url = self.build_url(url)
        try:
            result = subprocess.run(
                [
                    "yt-dlp",
                    "--dump-json",
                    "--no-warnings",
                    full_url,
                ],
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
            )
            if result.returncode == 0 and result.stdout.strip():
                first_line = result.stdout.strip().split("\n")[0]
                return json.loads(first_line)
        except (
            subprocess.SubprocessError,
            json.JSONDecodeError,
            OSError,
        ):
            pass
        return {}

    # ─────────────────────────────────────────────────────────
    # Pause / Resume / Cancel
    # ─────────────────────────────────────────────────────────

    def pause(self) -> None:
        """Suspend the yt-dlp subprocess (Linux SIGSTOP)."""
        if self._proc and self._proc.poll() is None and not self._paused:
            try:
                os.kill(self._proc.pid, signal.SIGSTOP)
                self._paused = True
            except (ProcessLookupError, PermissionError):
                pass

    def resume(self) -> None:
        """Resume a paused yt-dlp subprocess (Linux SIGCONT)."""
        if self._proc and self._proc.poll() is None and self._paused:
            try:
                os.kill(self._proc.pid, signal.SIGCONT)
                self._paused = False
            except (ProcessLookupError, PermissionError):
                pass

    def cancel(self) -> None:
        """Terminate the yt-dlp subprocess immediately."""
        if self._proc and self._proc.poll() is None:
            # Resume first if paused, otherwise kill may not propagate
            if self._paused:
                try:
                    os.kill(self._proc.pid, signal.SIGCONT)
                except (ProcessLookupError, PermissionError):
                    pass
            self._proc.terminate()
            try:
                self._proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self._proc.kill()

    # ─────────────────────────────────────────────────────────
    # Download
    # ─────────────────────────────────────────────────────────

    def download(
        self,
        item: DownloadItem,
        on_progress: Callable[[float], None] | None = None,
        on_status:   Callable[[str],   None] | None = None,
        on_speed:    Callable[[str],   None] | None = None,
    ) -> None:
        self.check_dependencies()

        # Bail out early if the item was cancelled before we started
        if item.status == "cancelled":
            if on_status:
                on_status("cancelled")
            return

        url = self.build_url(item.url)
        item.url    = url
        item.config = self.config
        item.status = "downloading"
        item.progress = 0.0
        item.error  = None

        if on_status:
            on_status("downloading")

        cmd = self.build_command(url)

        try:
            self._proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )

            for line in self._proc.stdout:
                # Cancelled — stop reading
                if item.status == "cancelled":
                    break

                line = line.strip()
                if "[download]" in line and "%" in line:
                    try:
                        percent_str = line.split("%")[0].split()[-1]
                        item.progress = float(percent_str)
                        if on_progress:
                            on_progress(item.progress)

                        # Parse speed and ETA
                        if on_speed:
                            speed_str = self._parse_speed_info(line)
                            if speed_str:
                                on_speed(speed_str)
                    except (IndexError, ValueError):
                        pass

            self._proc.wait()

            if item.status == "cancelled":
                if on_status:
                    on_status("cancelled")
                return

            if self._proc.returncode == 0:
                item.status   = "done"
                item.progress = 100.0
                if on_progress:
                    on_progress(100.0)
                if on_status:
                    on_status("done")
            else:
                item.status = "error"
                item.error  = f"yt-dlp exited with code {self._proc.returncode}"
                if on_status:
                    on_status("error")

        except FileNotFoundError as exc:
            item.status = "error"
            item.error  = f"Command not found: {exc}"
            if on_status:
                on_status("error")
        except Exception as exc:  # noqa: BLE001
            item.status = "error"
            item.error  = str(exc)
            if on_status:
                on_status("error")
        finally:
            self._proc = None

    @staticmethod
    def _parse_speed_info(line: str) -> str | None:
        """Extract speed and ETA from a yt-dlp progress line."""
        speed_match = re.search(r'\bat\s+([\d.]+)\s*(\w+/s)', line)
        eta_match = re.search(r'\bETA\s+([\d:]+)', line)
        parts = []
        if speed_match:
            parts.append(f"{speed_match.group(1)} {speed_match.group(2)}")
        if eta_match:
            parts.append(f"ETA {eta_match.group(1)}")
        return " • ".join(parts) if parts else None
