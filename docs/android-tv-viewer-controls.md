# Android TV viewer controls — proposed interaction specification

Status: **Design approved in discussion; not yet implemented.** Scope: TV/Google TV remote behavior only. Preserve mobile/touch behavior and keep Immich server assets unchanged. Target server >= Immich 3.3.3.

## Photo viewer (normal mode)

| Remote input | Action |
|---|---|
| D-pad Up | Zoom in one step |
| D-pad Down | Zoom out one step, stopping at Fit |
| D-pad Left / Right | Previous / next photo or asset |
| OK | Reveal existing toolbar/focused controls; toolbar exposes **Photo Options** |
| Back | Exit viewer; when another mode is active, exit that mode first |

Rationale: in upstream `asset_viewer.page.dart`, Up/Down currently reveal and focus the top/bottom toolbars. Replace these shortcuts **only while viewing a normal photo**. The existing OK route already reveals controls. Do not change video behavior.

## Photo Options (TV-only)

- Zoom In, Zoom Out, Reset / Fit
- Rotate Right 90°, Rotate Left 90°; repeated actions cycle through 0°, 90°, 180°, 270°
- Pan Mode (only when zoomed): directional keys pan the visible image; Back exits Pan Mode without leaving photo; OK may return to the options menu.
- Rotation is **display-only**: do not invoke asset editing, upload, or server mutations. Reset transform for each new asset unless a deliberate session-level setting is implemented.
- Always show current zoom factor/rotation when adjustment occurs. Maintain proper fit and centering on aspect-ratio changes after 90° rotation.
- Five-button remote support is mandatory: standard D-pad, OK and Back; never require channel/zoom/mouse keys.
- Preserve smooth large-image rendering by applying transforms to existing rendered photo widget rather than requesting the source asset again for each step.

## Photo date/time label (TV UI change)

Source: `mobile/lib/presentation/widgets/asset_viewer/viewer_top_app_bar.widget.dart` currently uses `NavigationToolbar(centerMiddle: true, middle: _AssetInfoTitle(asset: asset))`. This places the photo date/time in the **top center** whenever the toolbar is visible. The current Viewer settings (and `ViewerConfig`) offer no positioning/visibility preference.

**Proposed TV default**: move the compact date/time display to a lower-left safe-margin overlay, visible only while photo controls are shown, to leave the top center of the image clear. It should be non-focusable so it never intercepts remote inputs. If that area overlaps future photo controls, use a dedicated left-aligned metadata row instead.

**Proposed setting**: TV Photo Info Overlay = `Bottom left` (default), `Off`; consider adding `Top left` only if useful. Keep the existing phone/tablet centered toolbar unchanged. Test against TV overscan margins, portrait/landscape images and with full-screen/hidden controls.

**Status:** confirmed existing position and absence of preference by source review; preferred new placement should be finalized during TV hardware review before implementing.

## Video viewer (playing)

- D-pad Left/Right continue seeking backward/forward; don't change paused-video behavior without further agreement.
- Accelerated seek per rapid series or held repeat: first move **10 seconds**, second **30 seconds**, third and later **60 seconds** per event. Reset to 10 seconds after approximately 1.5 seconds without a seek key.
- Clamp seek target to [0, duration]; display seek direction, accumulated jump and resulting time in a short overlay.
- Dedicated rewind/fast-forward keys should use the same progression where appropriate.
- Press OK to pause/resume, retain Up/Down for video control navigation, keep Back behavior.
- Ignore key-up events for seeking; handle down and repeat events intentionally to avoid accidental double seeks.
- Do not trigger loading of additional gallery assets merely to seek the currently playing video.

## Navigation / focus

- While a Photo Options modal is open, focus cannot escape into the image/asset behind it.
- Back closes the menu and restores focus to its trigger.
- Do not repurpose D-pad keys while an interactive options control holds focus.
- Test whether normal photo mode can transition between toolbar and zoom mode predictably after closing options.

## Tests before releasing an APK

1. Normal photo: Up/Down steps zoom; Left/Right still navigate assets at Fit and while zoomed (unless Pan Mode explicitly selected).
2. Pan Mode: all four directions pan; Back leaves Pan Mode, not the photo.
3. Rotation: four right rotations return to original orientation; no server edit or asset modification requests.
4. Options: focus stays within menu; OK and Back behave predictably.
5. Video: single Right seeks +10; rapid repeats +30, then +60; idle reset to +10; reverse direction and end-of-video clamps behave correctly.
6. Regression: existing video playback and standard mobile/touch interactions remain functional.

## Relevant existing files

- `mobile/lib/presentation/widgets/asset_viewer/asset_viewer.page.dart` — viewer remote keys, media seek
- `mobile/lib/presentation/widgets/asset_viewer/asset_page.widget.dart` — PhotoView controller, zoom and image gestures
- `mobile/lib/presentation/widgets/asset_viewer/viewer_top_app_bar.widget.dart` — TV view-only action visibility
- `mobile/lib/presentation/widgets/asset_viewer/viewer_kebab_menu.widget.dart` — existing mobile actions, currently hidden for TV
- `mobile/lib/presentation/widgets/tv/remote_keys.dart` — seek increment/key classification
- `mobile/test/presentation/widgets/asset_viewer/asset_viewer_keys_test.dart` — viewer key tests

Tracking: separate from draft PR #1 for People filter and Albums sorting. Implement after a reproducible Android TV build/test workflow is available.
