# TubeRip Desktop — UI/UX Redesign Plan

## Context
TubeRip is a Flutter desktop app (Linux/Windows/macOS) that downloads YouTube videos/audio.
The current UI works but looks generic. We are adopting the **structure, spacing, typography
and component style** of a reference mockup provided by the user, with two hard constraints:

- **Cyan is the ONLY accent.** Everywhere the mockup uses purple/violet, use the app's existing
  cyan token (`AppColors.cyan`). No purple/violet anywhere.
- **Status colors:** green = Completed, amber/orange = Queued, cyan = Downloading.
- **Visual/layout pass only.** Do NOT change download logic, file I/O, format/quality resolution,
  or the sidebar's existing navigation items (Downloads / Settings / Help / About) — only restyle
  them. Where the mockup's header icon-cluster supersedes sidebar items, **migrate their
  functionality into the header** rather than deleting it.

Source of truth for layout: the user's written spec (this model cannot read the mockup image).

## Current-state gaps (verified by reading the code)
- `download_list_item.dart:146` shows a hardcoded `'Speed info'` placeholder — never populated.
- `DownloadItem` (`models.dart`) has no `speed`/`eta`/`fileSize`/`resolution` fields.
- `Downloader.download()` already exposes an `onSpeed` callback and `AppUtils.parseSpeed`
  returns `"X MB/s • ETA 0:45"`, but `DownloadManager.startDownload` never wires `onSpeed`.
- Sidebar `Settings`/`Help` are dialog launchers (fine); `Downloads`/`About` are no-ops.
- Colors/spacing/radii are hardcoded across widgets (no theme tokens).
- `Inter` is referenced everywhere but no font asset is declared in `pubspec.yaml` (falls back to
  system font).
- Window is frameless (`linux/runner/my_application.cc`, `window_manager`); large-radius window
  corners are a native concern (see Risks).

## Design decisions
1. **Theme tokens** — Introduce a `ThemeExtension` (`TubeRipTheme`) holding spacing, radius, and
   color references, and keep a single cyan source. Widgets read tokens via `Theme.of(context).extension<TubeRipTheme>()`.
   Keep `AppColors` as the underlying values but add `TubeRipTheme` on top so cyan is defined once.
2. **Reusable widgets** — extract:
   - `StatusBadge` (dot / check / outlined-circle + color, driven by status).
   - `DownloadQueueItem` with a `DownloadStatus` enum (`downloading | completed | queued |
     paused | error | cancelled`) controlling color + icon + trailing content. Replaces
     `download_list_item.dart`.
   - `PrimaryDropdown` — themed `DropdownButton` (leading icon + chevron, dark menu) used for
     **Format** and **Quality** selectors.
3. **Header bar** (replaces `TitleBar`) — left: accent outline icon + bold "TubeRip" wordmark;
   right: icon cluster = queue icon, **settings (gear)**, **help (?)**, then window controls
   (minimize / maximize / close) as small circular icon buttons. Migrate Settings & Help out of
   the sidebar into this cluster (reuse existing `SettingsDialog` / `HelpDialog`).
4. **Sidebar** — keep `Downloads` (active) and `About`; remove the now-duplicated `Settings`/`Help`
   entries (functionality migrated to header). Restyle remaining items: cyan active highlight,
   consistent icon style, better spacing.
5. **URL input section** — small label `"Paste YouTube Video URL or ID"` above a full-width rounded
   input; 2px cyan border + soft glow on focus; placeholder example YouTube URL. Add a **Paste**
   convenience button (reads clipboard) alongside the existing clear button.
6. **Options row** — replace the segmented `ModeSelector` + `QualitySelector` with
   `PrimaryDropdown` for **Format** ("Video (MP4)" / "Audio (MP3)…") and **Quality**
   (resolution labels, e.g. `Best`, `1080p`, `720p`…). Keep the small **gear** button for advanced
   options (opens `SettingsDialog`). NOTE: fps + estimated file-size in the quality dropdown require
   metadata; show resolution only for now (see Open Questions).
7. **Action row** — full-width, pill-shaped CTA with cyan gradient fill + leading download icon +
   label `"Download Video"` / `"Download Audio"` (mode-aware). Below it: `"Save to:"` label + path +
   folder icon button (existing `OutputSelector`).
8. **Download Queue section** — bold `"Download Queue"` header + muted subheading `"Recent Downloads"`.
   Each `DownloadQueueItem`:
   - Leading circular numbered badge (muted bg, index).
   - Title (bold, ellipsis) + subtitle (`format • quality • size • progress%`).
   - Trailing by state:
     - **downloading:** cyan `StatusBadge` + `"Downloading"`, `speed • ETA` text, full-width accent
       progress bar beneath, pause + cancel (X) icons right.
     - **completed:** green check + `"Completed"`, `"Location"` + folder icon to reveal file.
     - **queued/pending:** amber outlined circle + `"Queued"`, play/pause icon right.
     - **paused / error / cancelled:** keep existing handling (reuse status colors: amber paused,
       red error/cancelled) — do not drop these states.
9. **Empty state** — restyled: centered large muted download icon, bold `"No downloads yet"`,
   muted `"Enter a YouTube URL and click download to get started."`.
10. **Window radius** — apply the large radius to the inner content container (`ClipRRect` /
    rounded `Scaffold` body) for the visual effect. True rounded *window* corners on Linux frameless
    need a GTK shape mask — out of scope (see Risks).

## Data enabler (the only necessary logic touch)
To render real `speed • ETA` and `size` per the mockup, make this minimal, scoped change:
- `models.dart`: add `String? speed` and `String? eta` (and optional `String? fileSize`) to
  `DownloadItem`.
- `download_manager.dart` (`startDownload`): pass `onSpeed: (s) { item.speed = s; notifyListeners(); }`
  into `downloader.download(...)`.
- No change to yt-dlp command building, parsing regexes, or file paths.
If strict visual-only is required, this step can be skipped and the subtitle shows progress% only
(placeholder speed text removed either way).

## Files to change / create
- `lib/core/theme.dart` — add `TubeRipTheme` `ThemeExtension` + wire into `ThemeData`.
- `lib/core/constants.dart` — add radius/spacing tokens if not in the extension; confirm single
  cyan value.
- `lib/ui/widgets/header_bar.dart` (new) — replaces `title_bar.dart`.
- `lib/ui/widgets/title_bar.dart` — delete after migration (or keep window-control helpers if reused).
- `lib/ui/widgets/url_input.dart` — label, focus glow, paste button.
- `lib/ui/widgets/primary_dropdown.dart` (new) — themed dropdown.
- `lib/ui/widgets/format_selector.dart` (new, or inline) — Format `PrimaryDropdown`.
- `lib/ui/widgets/quality_selector.dart` — convert to `PrimaryDropdown` (resolution labels).
- `lib/ui/widgets/mode_selector.dart` — remove (replaced by Format dropdown) or keep as helper.
- `lib/ui/widgets/status_badge.dart` (new).
- `lib/ui/widgets/download_queue_item.dart` (new) — replaces `download_list_item.dart`.
- `lib/ui/widgets/download_list_item.dart` — delete after replacement.
- `lib/ui/screens/main_screen.dart` — restructure layout per sections 3–9; update sidebar; wire
  header; pass `onSpeed`.
- `lib/backend/models.dart` — add `speed`/`eta`/`fileSize` to `DownloadItem` (enabler).
- `lib/services/download_manager.dart` — wire `onSpeed`.
- `pubspec.yaml` (optional) — declare `Inter` font asset so the intended font actually renders.

## Validation
- `flutter analyze` passes with no new errors/warnings.
- `flutter build linux --debug` succeeds.
- Manual (Linux): `flutter run -d linux` — window opens; header shows wordmark + settings/help +
  window controls; paste a URL → input glows on focus; selecting Format/Quality updates the CTA
  label; starting a download shows a numbered card with live `speed • ETA`, animated accent
  progress bar, working pause/cancel; completed card shows green check + Location reveal; empty
  state renders when queue is empty.
- Confirm zero purple/violet anywhere in `lib/` (grep for hex purple ranges / `0x9` violet values).
- Keep existing keyboard shortcuts (Enter = download, Ctrl+S = settings, Ctrl+/ = help) working.

## Risks / open questions
- **Rounded window corners:** a true ~20px rounded *window* on Linux frameless requires a GTK shape
  mask (`gtk_widget_shape_combine_region` / `gtk_window_set_decorated` + CSS) — separate native task.
  Plan applies radius to inner content only unless you want the native change too.
- **Quality dropdown fps/size:** the mockup shows "resolution + fps + estimated file size". Real
  fps/size need a metadata fetch (`DownloadManager.fetchMetadata` exists but is unused). Out of
  strict visual scope; recommend resolution-only labels for now, defer dynamic fps/size to a
  follow-up.
- **Reveal-in-folder** for completed items needs a platform "show in file manager" call (not
  currently implemented; `url_launcher` is not a dependency). Recommend a minimal
  `Process.run('xdg-open', [dir])` on Linux for v1, cross-platform later.
- **'Inter' font:** currently undeclared → falls back to system font. Declaring it changes text
  metrics slightly; optional but recommended for fidelity.
