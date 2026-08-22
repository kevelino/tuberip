# Plan: Surface the real yt-dlp failure reason

## Context
When a download fails, the user only sees `yt-dlp exited with code 1`. The actual
diagnostic message printed by yt-dlp (e.g. `ERROR: Sign in to confirm you're not a
bot`, `ERROR: ... is not available`, `ERROR: Unable to download ...`) is written to
stderr, merged into stdout, read line-by-line in `downloader.py`, but **discarded**
— the loop only keeps `[download]` progress lines. On failure, `item.error` is set
to a generic string at `downloader.py:257`.

Confirmed environment facts:
- `yt-dlp` present at `/usr/bin/yt-dlp`, `ffmpeg` at `/usr/bin/ffmpeg` → not a
  missing-dependency problem.
- Default output dir `~/Downloads/YouTube` is auto-created by yt-dlp, so usually fine.

Most common real causes of code 1 here (need the surfaced error to confirm):
1. Outdated yt-dlp (YouTube frequently breaks old builds).
2. The specific URL (age-restricted / private / region-blocked / removed).
3. Non-writable output directory.

## Goal
1. Make the app report the **real** yt-dlp error so the user can see *why* it failed.
2. Give immediate diagnostic/remediation steps the user can run now.

## Changes

### 1. Capture the real yt-dlp error (`backend/downloader.py`)
In `download()`:
- Initialize `last_error: str | None = None` before launching the process.
- In the `for line in self._proc.stdout:` loop, detect yt-dlp error/warning lines and
  keep the most relevant one, e.g.:
  ```python
  if "ERROR:" in line:
      last_error = line.strip()
  elif last_error is None and ("WARNING:" in line or "ERROR" in line):
      last_error = line.strip()
  ```
- On non-zero exit (`else` branch at line 255-259), set:
  ```python
  item.error = last_error or f"yt-dlp exited with code {self._proc.returncode}"
  ```
  Keep the return code appended as a fallback so info is never lost:
  `f"{last_error} (exit {self._proc.returncode})"`.

### 2. (Optional) Reuse the captured error for the metadata step
`fetch_metadata()` (lines 116-141) silently returns `{}` on failure, so a bad URL
never surfaces. Capture `result.stderr` and log/raise a clearer message when
`returncode != 0`. Low priority but improves diagnosis.

## Immediate remediation (run now, no code change)
1. Update yt-dlp (most likely fix):
   - If installed via pip: `pip install -U yt-dlp`
   - If system package: `sudo apt update && sudo apt install --only-upgrade yt-dlp`
     (or use `uv tool upgrade yt-dlp` if installed that way).
2. Retry the download after the fix; if it still fails, the surfaced `ERROR:` line
   will now name the exact reason.
3. If the error mentions "confirm you're not a bot" / age restriction, that URL needs
   cookies/auth — out of scope for this plan, but can be addressed later via a
   cookie/account import option.

## Validation
- Run `uv run python main.py`, attempt the same download.
- Confirm the error badge now shows the real `ERROR: ...` text instead of only
  `yt-dlp exited with code 1`.
- Confirm a successful download still completes with `status == "done"`.

## Open question
Do you want the app to also offer an in-app **yt-dlp self-update** button (run
`yt-dlp -U`)? Default plan does NOT add this; it only surfaces the real error.
