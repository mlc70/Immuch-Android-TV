# Permanent Android TV fork

Supported product: mlc70/Immuch-Android-TV, one universal Android TV APK.
Upstream is a source of reviewed fixes, not a release dependency.

## Evidence and starting point (October 31, 2026)

* Start from combined r13, `76db6885e646fd0482ac538f95736b2d8da027ca`.
  Actions run 41004939321 succeeded, but hardware testing found only the photo
  timestamp improved. Passing old widget tests is not acceptance of Search.
* `feature/tv-all-search-filters` ends at `930c074be`; the combined branch includes
  its work plus the persisted viewer date overlay.
* `feature/tv-search-navigation-upstream-20261027` ends at `b3be6a161`.
* `test/upstream-tv-2026-10-30` ends at `28a2ec018`; it diverges from combined by
  25 fork commits and 1,275 commits on the other side. Do not merge it wholesale.
* The cloned default `immuch360` ends at `283f8bca2`. Current upstream observed
  through GitHub is `bae2254a051e65dbaf9235c508d702eb7221948f`, including Android
  TIFF decoding and watch progress. Review TIFF decoding separately, with media
  fixtures; watch progress is optional and needs settings/schema review. Neither
  is included merely to fix remote navigation.

## Stage 1: supported target and Search foundation

Use `feature/android-tv-permanent`, based on r13. Archive inherited workflows
outside `.github/workflows`, retaining their source for reference. The remaining
workflow generates API/platform/database/translations, tests, analyzes changed
Search code and builds only `--flavor tv --dart-define=IMMUCH_TV_ONLY=true`.
TV builds ignore old layout Off preferences without rewriting saved settings.

Retain application ID `com.aprogsys.immuch360.tvtest` and the optional persistent
signing secrets from r13. Label changes do not migrate or erase data. Without the
same signing certificate an in-place upgrade cannot preserve data: never advise
uninstalling a working installation as a routine upgrade step.

The TV manifest excludes Quest/spatial viewer entry points, home-screen widgets
and phone sharing. Their shared native implementations/dependencies remain until
references are removed safely. OAuth callbacks and server integration are retained.

Search requirements: all eight dialogs (People, Location, Tags, Camera, Date,
Media Type, Rating, Display) must contain focus. Up/Down navigates; OK changes the
draft; Right reaches Apply; Left returns to the previous field; Clear resets the
active filter; Back discards the draft. Date starts with year, month, day for each
endpoint, handles leap days, enforces ordered ranges and an inclusive end day.
Location suggestions use country -> state -> city, clearing both state and visual
values on parent change. Camera does the same for make -> model. Text modes are
Context (if supported), Filename, Description and OCR (if supported).

## Stage 2: hardware acceptance before default-branch promotion

Run the actual Search page on a 960x540 TV with overscan. For every filter, select
a non-default value, Apply, reopen, Clear, reopen, alter and Back. Confirm the
resulting server query and results, not only the label. Test long People/Tags and
city lists beyond the first screen. Verify no arrow or Back operates the page
behind a dialog. Test delayed/empty/error suggestions and a country/make change
after previously selecting a child. Test all supported text modes with the same
query. Record exact branch, SHA, Actions run and APK hash displayed by the build.
New widget tests are evidence of key handling, not a claim of hardware acceptance.

Also verify retained login/server URL, OAuth, server switching, Photos/Albums/
Library, original and thumbnail caches, ordinary and 360 photo/video playback,
and persisted date/time overlay. Promote the branch only after these checks.

## Stage 3: remove unsupported UI incrementally

Trace route and provider imports before removing phone upload, local backup,
editing, deletion, device-gallery and share-host UI. Hide unsupported routes first,
then delete isolated implementations. Keep account/session storage and database
migrations compatible. For each step, rerun Search tests and media/auth checks.

## Stage 4: dependency and repository reduction

Audit native platform registrations and imports before removing iOS, desktop,
Quest packages, permissions or SDKs. Keep Immich API generation, Rust native_core,
Android image/video decoders, networking, caches, shared models and photo viewer.
Only then archive unused platform directories/build tasks and simplify pubspec.
Do not delete server/API source used by code generation simply because the product
is a client. Keep license notices and upstream attribution.

## Release independence

No upstream mobile release, store upload, self-hosted runner, Docker or desktop
workflow runs on this branch. Releases and the default branch remain deliberate
review steps. Every APK identifies its branch/commit on Search, includes its run
in versionName and artifact filename, and has a SHA-256 in the build log.
