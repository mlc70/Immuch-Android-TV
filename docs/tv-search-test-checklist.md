# Android TV Search regression checklist

Baseline: upstream Immuch360 `b72a719` (27 October 2026), plus TV Search fixes on branch
`feature/tv-search-navigation-upstream-20261027`.

Test on a real Android/Google TV with a D-pad. These are manual verification
items; passing Flutter unit tests does **not** prove TV behavior.

## Confirmed working in prior APK, verify no regressions
- [ ] Main navigation: Photos, Search, Albums, Library
- [ ] People Search selection / Apply / Clear
- [ ] Other Search filters (Tags, Media Type, Display, Star Rating)

## Upstream TV fixes newly included; verify on TV
- [ ] Location: Country, State, City dropdowns open, scroll, select, retain focus, Apply/Clear
- [ ] Camera: Make and Model dropdowns open, navigate, select, Apply/Clear
- [ ] Date: "In year" opens a year list usable with the D-pad
- [ ] Search overflow (...) opens Smart / Filename / Description / OCR choices, correctly changes type

## Fixes in this branch
- [ ] Search result/filter -> Back returns to main Search suggestions, not to another main tab
- [ ] After Search reset, input is ready to start another query
- [ ] Albums Search typed text can be cleared with a focusable X/clear control
- [ ] Search helper "Press OK to type" is fully visible
- [ ] Search keyboard title reads "Search" rather than "Sunrise on the beach"
- [ ] Custom Date Range can jump to an older Start and End year directly
- [ ] Custom Date Range enables Apply only for Start <= End, and Cancel preserves the previous filter

## Subsequent phase, **not** in this APK
- Photo zoom Up/Down and long-press OK submenu
- Date/time overlay placement and off switch
- Hide photo OCR/TT control on TV
- Add to Album as an explicitly allowed organization action
- TV-specific non-destructive policy and saved rotation behavior

Use the Android TV Test APK workflow artifact. For updates to preserve login,
`TV_TEST_KEYSTORE_BASE64` and `TV_TEST_KEYSTORE_PASSWORD` must be configured
before installing the first persistent test build. See `docs/android-tv-test-apk.md`.
