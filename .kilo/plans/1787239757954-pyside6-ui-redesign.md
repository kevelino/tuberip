# PySide6 UI Redesign Plan

## Summary
Redesign the TubeRip PySide6 app's visual layout and styling while keeping all download logic, signal wiring, and business logic untouched. Switch from a custom frameless title bar to native window decorations, introduce card-style queue items with state-driven trailing content, add an in-window header bar, responsive layout, and adaptive light/dark QSS.

## Key Decisions
- **Window decorations**: Native Qt title bar (remove `FramelessWindowHint` + drag handlers)
- **Theme**: Auto-detect system palette via `QApplication.palette()`; QSS uses `palette()` for backgrounds/text/fills so it adapts automatically. Cyan (`#11eef9`) is hardcoded as the single accent.
- **QComboBox two-weight rendering**: Custom `QStyledItemDelegate` for QualitySelector to render bold title + muted subtitle
- **Queue items**: `DownloadQueueItem(QFrame)` replaces `DownloadItemWidget`; cards with state-driven trailing buttons
- **Timestamps**: Stored in the widget; rendered as relative time ("2 min ago") instead of sequential index
- **Error state**: Dismiss button (removes from queue); retry noted as future work (requires backend changes)
- **Responsive**: `resizeEvent` on MainWindow; format/quality dropdowns stack vertically below ~600px content width
- **CTA button**: New `PillButton(QPushButton)` subclass with pill shape + cyan fill

## Affected Boundaries
- **In scope**: `app.py`, `main_window.py`, `ui/widgets.py`, `ui/download_item_widget.py`, `ui/styles.qss`, `ui/__init__.py`
- **Out of scope**: `backend/` (models.py, downloader.py), `main.py`, `DownloadWorker`, signal/slot download pipeline
- **Build/packaging**: PyInstaller spec must be updated if `styles.qss` is replaced by `theme.py`

## New Files

|`File` | `Class` | Purpose |
|---|---|---|
| `ui/theme.py` | `TubeRipTheme` | Color/spacing constants + `generate_qss(theme: str)` returning adaptive QSS using `palette()` tokens |
| `ui/status_badge.py` | `StatusBadge(QWidget)` | Colored dot + label widget; colors driven by status (cyan/downloading, green/completed, amber/queued, red/error) |
| `ui/pill_button.py` | `PillButton(QPushButton)` | Full-width pill-shaped CTA; mode-aware label ("Download Video"/"Download Audio"); disabled state |
| `ui/empty_state.py` | `EmptyState(QWidget)` | Centered: muted download icon + bold "No downloads yet" + subtext |
| `ui/header_bar.py` | `HeaderBar(QWidget)` | Left: cyan "TR" badge + bold "TubeRip"; Right: settings (gear) + help (?) tool buttons |
| `ui/download_queue_item.py` | `DownloadQueueItem(QFrame)` | Card-style queue row; replaces `DownloadItemWidget`; state-driven trailing content per status |

## Deleted Files
- `ui/download_item_widget.py` — replaced by `ui/download_queue_item.py`
- `ui/styles.qss` — replaced by `ui/theme.py` (QSS generated in Python with `palette()` tokens and constants)

## Modified Files

### `app.py`
- Add system theme detection: check `XDG_COLOR_SCHEME` env var and `QPalette.Window` lightness
- Replace `_load_styles()` reading `styles.qss` file with `app.setStyleSheet(ThemeGenerator.generate_qss())` from `theme.py`
- Pass detected theme to `MainWindow` constructor

### `main_window.py`
- Remove `Qt.FramelessWindowHint` from `setWindowFlags` → use native decorations
- Remove `mousePressEvent`/`mouseMoveEvent`/`mouseReleaseEvent` (no longer needed)
- Replace `_build_title_bar()` → `_build_header()` returning `HeaderBar` widget
- Restructure `_build_content()`:
  - URL input section (label + input with focus glow via `QGraphicsDropShadowEffect`)
  - Options row: `FormatSelector` + `QualitySelector` in a `QHBoxLayout` that toggles to `QVBoxLayout` on narrow windows
  - Action row: `PillButton` (CTA) + `SaveToRow` (path + folder button)
  - Queue section header ("Download Queue" / "Recent Downloads")
  - Empty state placeholder (shown when queue is empty; `QListWidget` hidden when empty and vice versa)
  - `QListWidget` for queue items (cards)
- `start_download()`: create `DownloadQueueItem` instead of `DownloadItemWidget`; connect same signals (`pause_requested`, `cancel_requested`, `open_folder_requested`)
- `_on_pause_item`: update to use `DownloadQueueItem.set_paused()` API
- `_on_cancel_item`: same signals, same logic
- `_on_progress`: update meta label handling for new subtitle field
- `_on_status_changed`: same status strings, new widget methods
- `_on_finished`: same status mapping
- Add `resizeEvent(self, event)`: toggle options row layout between horizontal/vertical based on content width threshold
- Add `_update_empty_state()`: show/hide `EmptyState` + `QListWidget` based on `self.items`

### `ui/widgets.py`
- `FormatSelector`: simplify items to ["Video (MP4)", "Video (MKV)", "Video (WEBM)", "Audio (MP3)", "Audio (M4A)", "Audio (OPUS)"]; apply two-weight delegate optionally
- `QualitySelector`: simplify VIDEO_PRESETS to ["Best", "1080p", "720p", "480p", "360p"]; AUDIO_PRESETS to ["Best", "320kbps", "192kbps", "128kbps"]; use custom delegate for two-weight rendering
- `SaveToRow`: keep but restyle path input as read-only compact display + folder button
- `SettingsDialog`: keep all functionality; restyle with theme tokens; add manual theme toggle (light/dark/auto) as a small QComboBox at top
- `HelpDialog`: keep all functionality; restyle

### `ui/__init__.py`
- Replace `DownloadItemWidget` export with `DownloadQueueItem`
- Add exports: `StatusBadge`, `PillButton`, `EmptyState`, `HeaderBar`

## Task List (Ordered)

### Phase 1: Theme Infrastructure
1. Create `ui/theme.py` — define color constants (cyan, green, amber, red, etc.), spacing/radius constants, and `generate_qss(theme)` returning full QSS string using `palette()` tokens
2. Add theme detection utility: `ThemeGenerator.detect_theme() -> str` ("dark" or "light") based on `XDG_COLOR_SCHEME` env var and `QPalette.Window` lightness
3. Update `app.py` — replace `_load_styles` with `ThemeGenerator.generate_qss()` call; detect theme at startup

### Phase 2: Header Bar
4. Create `ui/header_bar.py` — `HeaderBar(QWidget)` with cyan "TR" badge + bold "TubeRip" label on left; flat settings/help buttons on right
5. Create `ui/pill_button.py` — `PillButton(QPushButton)` with pill styling, mode-aware text, disabled state
6. Refactor `main_window.py`: remove `FramelessWindowHint` + drag handlers; replace `_build_title_bar()` with `_build_header()` returning `HeaderBar`

### Phase 3: Input & Action Row
7. Create `ui/status_badge.py` — `StatusBadge(QWidget)` with colored circle + status label; colors driven by status enum
8. Update `ui/widgets.py` `FormatSelector`/`QualitySelector`: simplify items, add `StyledComboBoxDelegate` for two-weight rendering
9. Update `_build_content()` in `main_window.py`: restructure input row with `PillButton` as CTA, restyle `SaveToRow`
10. Add focus-glow effect (`QGraphicsDropShadowEffect`) to URL input

### Phase 4: Queue Items & Empty State
11. Create `ui/empty_state.py` — `EmptyState(QWidget)` with centered icon + "No downloads yet" + subtext
12. Create `ui/download_queue_item.py` — `DownloadQueueItem(QFrame)`:
    - Remove index label; add relative timestamp label
    - Title (bold) + subtitle (format/quality/progress%)
    - Status-driven trailing content:
      - **Downloading**: cyan `StatusBadge` + speed/ETA text + full-width progress bar + pause/cancel buttons
      - **Completed**: green `StatusBadge` + "Location" text + folder button
      - **Queued**: amber `StatusBadge` + pause/resume button
      - **Error**: red `StatusBadge` + error text + dismiss button
      - **Cancelled**: grey `StatusBadge` (no trailing buttons)
    - Methods: `set_title`, `set_subtitle`, `set_progress`, `set_status`, `set_speed_info`, `set_error`, `set_paused`
    - Signals: `pause_requested`, `cancel_requested`, `open_folder_requested`, `dismiss_requested`
13. Update `main_window.py` `_build_content()` to manage empty state + queue list visibility
14. Update `start_download()` to instantiate `DownloadQueueItem`
15. Update `_on_progress`, `_on_status_changed`, `_on_finished`, `_on_pause_item`, `_on_cancel_item` for new widget API

### Phase 5: Responsive Layout
16. Add `resizeEvent` to `MainWindow` — toggle format/quality dropdown layout between horizontal and vertical at ~600px content width

### Phase 6: QSS & Styling
17. Finalize `ui/theme.py` QSS — all colors use `palette()` tokens; cyan (`#11eef9`) hardcoded for accent; status colors for green/amber/red; card-style `QFrame` with `palette(alternate-base)` background and thin `palette(mid)` border
18. Delete `ui/styles.qss` (content moved to `theme.py`)
19. Update `scripts/build.spec` — replace `datas` entry for `styles.qss` with `theme.py` (auto-included as Python module)

### Phase 7: Integration & Cleanup
20. Update `ui/__init__.py` — new exports
21. Update `CHANGELOG.md` — note redesign
22. Run existing tests (`PYTHONPATH=src python3 -m pytest tests/`)
23. Lint check (`python3 -m py_compile` on all changed files; run ruff if installed)

## Widget API Compatibility Matrix

| MainWindow slot | Old `DownloadItemWidget` method | New `DownloadQueueItem` method |
|---|---|---|
| `start_download` | `DownloadItemWidget(index, title)` | `DownloadQueueItem(title)` |
| `_on_title_found` | `set_title(text)` | `set_title(text)` |
| `_on_progress` | `set_progress`, `set_status`, `set_info`, `meta_label.text()` | `set_progress`, `set_status`, `set_subtitle` |
| `_on_speed_info` | `set_speed_info(text)` | `set_speed_info(text)` |
| `_on_status_changed` | `set_status`, `set_error` | `set_status`, `set_error` |
| `_on_finished` | `set_status`, `set_progress` | `set_status`, `set_progress` |
| `_on_pause_item` | `set_paused` (internal via `set_status`) | `set_paused` or status-driven button visibility |
| `_on_cancel_item` | `set_progress(0)` | `set_progress(0)` |
| `_on_open_folder` | N/A (uses signals) | N/A (uses signals) |

Signals remain identical: `pause_requested`, `cancel_requested`, `open_folder_requested`.

## Validation Steps
1. `PYTHONPATH=src python3 -m pytest tests/ -v` — all 15 existing backend tests pass
2. `python3 -m py_compile src/tuberip/ui/*.py src/tuberip/main_window.py src/tuberip/app.py src/tuberip/main.py` — no syntax errors
3. Manual test (Linux): `PYTHONPATH=src python3 src/tuberip/main.py`
   - App opens with native title bar decorations
   - Header bar shows cyan "TR" badge + "TubeRip" label + settings/help buttons
   - URL input has focus glow on focus
   - Format/quality dropdowns render with two-weight items
   - Download button is pill-shaped with cyan fill; disabled (grayed) when no URL
   - Save-to row shows path + folder button
   - Queue items render as cards with state-driven content
   - Adding a URL + clicking download queues an item
   - Empty state shows when queue is empty
   - Resizing to narrow width stacks dropdowns vertically
   - Settings dialog opens (Ctrl+S) and has a manual theme toggle
   - Help dialog opens (Ctrl+/) — *note: currently only `?` button; consider adding Ctrl+/ shortcut*
   - App matches dark cyber-cyan aesthetic on dark desktop; adapts on light desktop

## Risks & Mitigations
- **Risk**: Custom `QStyledItemDelegate` for two-weight combo items may have rendering quirks across Qt versions. **Mitigation**: Keep single-line fallback text; delegate is optional enhancement.
- **Risk**: `palette(alternate-base)` may not differ enough from `palette(window)` in all themes. **Mitigation**: Fallback to explicit light/dark color values in `theme.py` based on detected theme.
- **Risk**: Removing frameless window may cause layout to look different on different DEs. **Mitigation**: Use flexible layouts with `QVBoxLayout`/`QHBoxLayout` and proper size policies — no absolute positioning.
- **Risk**: `QGraphicsDropShadowEffect` can be slow on some compositors. **Mitigation**: Apply only on focus; remove effect when not focused.
- **Risk**: Renaming `DownloadItemWidget` → `DownloadQueueItem` might miss a reference. **Mitigation**: Grep for all references before finalizing; update `__init__.py`, `main_window.py`, and any test files.

## Open Questions (deferred)
1. **QComboBox two-weight**: If the custom delegate proves problematic, fall back to single-line text with clean formatting.
2. **Theme toggle**: The manual toggle in Settings is optional — auto-detection handles most cases.
3. **Keyboard shortcut for Help**: Currently only the `?` button opens help. Consider adding Ctrl+/ as mentioned in the spec.
4. **Error retry**: Requires re-invoking the download pipeline (backend logic) — deferred to post-redesign.
5. **Inter font**: No font asset declared; falls back to system default. Optional enhancement.
