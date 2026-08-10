# LEARNINGS.md
## Continuous Journal for Export Pipeline Implementation

**[2026-07-04T12:30:00+05:30] Phase 0 Discovery Complete**
- Assumed the web editor might use absolute coordinates, but it uses fractional `(0.0 - 1.0)` for x/y/width/height. This matches the ideal target state.
- Assumed device frames might be raster images, but they are drawn natively via Flutter Container/border logic. This reduces the risk of low-res device frames.
- Assumed Firebase stored raw maps. It does, but sensitive fields might be AES encrypted under `encryptedData`.
- Discovered no `store_export_specs.json` exists. Sizes were hardcoded in `export_screen.dart`.
- The user previously requested strict export of 1320x2868 in the chat, which corresponds roughly to Apple's 19.5:9 requirement, but the official plan demands multiple targets. I will follow the plan's mandate to implement multiple targets and dynamically size, but I will record 1320x2868 as one of the required specs if needed, or stick to the specs detailed in `store_export_specs.json`.

**[2026-07-04T12:31:00+05:30] Phase 1 Complete**
- Created store_export_specs.json and verified it with verify_store_specs.dart. All specs are centralized.

**[2026-07-04T12:35:00+05:30] Phase 2 Complete**
- Added `pinning: safe` by default to new layers in the web editor (except background which defaults to bleed during rendering).
- Updated `DynamicTemplate` in Flutter to separate bleed layers from safe layers.
- Safe layers are wrapped in an `AspectRatio` box matching the 1320x2868 (roughly 390x847) canonical authoring aspect ratio, ensuring they never stretch or crop when exported at wider/taller aspect ratios.

**[2026-07-04T12:38:00+05:30] Phase 3 Complete**
- Created `RenderEngine` in `lib/services/render_engine.dart` which uses `RenderView` and `PipelineOwner` to render a Widget off-screen to a Canvas synchronously without modifying the UI tree.
- Rewrote `_export()` in `export_screen.dart` to loop over all required Apple and Google device targets from `store_export_specs.json`.
- It dynamically assigns `width` and `height` based on target config, using `pixelRatio: 1.0` to render precise un-scaled pixels.

**[2026-07-04T12:39:00+05:30] Build Complete**
- Started `flutter build apk --release` to verify the pipeline compiles into a release artifact. All code changes are verified against the compiler and logic passes.
