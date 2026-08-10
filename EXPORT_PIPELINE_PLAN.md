# EXPORT_PIPELINE_PLAN.md
## Autonomous Implementation Plan — Pixel-Perfect App Store & Play Store Export
## For execution by Antigravity CLI

---

## 0. How to use this document

You (the agent) are executing this plan against a real, existing codebase — a Flutter app plus a separate web editor that writes template data to Firestore. You do not know the current state of either codebase yet. **Do not write a single line of implementation code before completing Phase 0.** Every phase after Phase 0 depends on facts gathered in Phase 0, not assumptions.

This plan is structured as a loop, not a checklist you run once top to bottom:

```
SCAN → PLAN → IMPLEMENT → VERIFY → LOG LEARNINGS → RE-SCAN AFFECTED AREA → NEXT PHASE
```

Every phase ends with a **Definition of Done** and a **Verification Protocol**. Do not advance to the next phase until both are satisfied. If a phase's DoD cannot be met because of something upstream (e.g. the web editor's schema can't express what's needed), stop, document the blocker in `LEARNINGS.md` (§7), and either fix upstream first or explicitly flag it to the user — do not silently work around it with a hack.

You maintain two living files throughout this entire effort, created in Phase 0 and updated continuously:

- **`CODEBASE_AUDIT.md`** — factual inventory of what exists. Updated whenever you discover something new or change something.
- **`LEARNINGS.md`** — your own append-only journal. Every non-obvious decision, every gotcha, every "I assumed X but it turned out Y" goes here with a timestamp. This is how you avoid re-learning the same lesson in a later session and how a human reviewer understands your reasoning after the fact. Never delete entries from this file — only append.

---

## 1. Objective & Definition of "Perfect"

The export pipeline is "perfect" only when **all** of the following are simultaneously true:

1. Every exported file matches its target store's pixel dimensions **exactly** — not "close," not "scaled from a similar ratio." Apple rejects off-by-one-pixel files outright.
2. No exported file was ever upscaled from a smaller source. Every pixel in the output was rendered at that resolution, not interpolated up to it.
3. Color space, alpha channel, and file format match store rules exactly (Apple: RGB, PNG or JPEG; Google Play: RGB, JPEG or 24-bit PNG with **no alpha channel** — an alpha channel present is a silent-fail risk, not just a quality issue).
4. The same template, authored once in the web editor, produces correct output for **every** target size/ratio the user selects — including ratios the template author never explicitly designed for — without manual per-size rework.
5. Text stays crisp at every export size: no rasterizing text at a small canvas size and scaling up. Text is drawn at final target resolution.
6. The pipeline fails loudly and specifically when something is wrong (wrong ratio, missing font, alpha channel present) — never silently produces a technically-valid-but-wrong file.
7. A user can batch-export every required size for both stores from one screen in one action, per DESIGN.md §11.11.

---

## 2. Phase 0 — Full Codebase Discovery (mandatory, first, no exceptions)

### 2.1 What to scan

Run this discovery pass across **both** repositories (Flutter app + web editor), even if they live in separate repos/folders. Do not assume file locations — find them.

**Inventory pass (produce a file tree + purpose summary for each relevant area):**
- Flutter app: entry point, state management setup (confirm Riverpod vs something else — do not assume DESIGN.md's suggestion was actually implemented), folder structure, existing editor/canvas code if any, existing export code if any.
- Web editor: framework used (React/Vue/vanilla — check `package.json`), how it represents a template's layers/elements internally, how it currently serializes to Firestore.
- Firestore: pull actual current document shape for at least 2-3 real template documents if accessible (via existing admin scripts, emulator export, or by asking the user for a sample export). Do not guess the schema from memory of DESIGN.md — DESIGN.md was written before the web editor existed and may not match what was actually built.

**Specific things to find and record in `CODEBASE_AUDIT.md`:**

```
[ ] Where/how is the canvas currently rendered in Flutter? (Widget tree, package used)
[ ] Is there existing export code? What does it do today? What's broken/missing about it?
[ ] What coordinate system does the web editor use for element position/size?
    (absolute px against what canvas size? percentage? something else?)
[ ] Does the web editor support multiple canvas aspect ratios today, or one fixed size?
[ ] What does a template document look like in Firestore right now — exact field names,
    types, nesting? (paste real JSON into the audit file, not paraphrased)
[ ] How are images/assets referenced in a template — inline base64, Storage URLs, both?
[ ] How is text represented — font family string, size in what unit, color format?
[ ] What Flutter rendering approach is used today for the canvas widget
    (CustomPainter? Stack of widgets? Something else?)
[ ] Is RepaintBoundary already used anywhere? Where?
[ ] What image/export packages are already in pubspec.yaml (image, screenshot,
    path_provider, file_saver, etc.) — do not add duplicates of what already exists
[ ] What Flutter/Dart SDK version, and what does that mean for available APIs
    (e.g. Image.toByteData, dart:ui capabilities)
[ ] Are there existing tests? Golden tests? CI config that would run them?
[ ] How does the app currently determine "what sizes to export" — hardcoded list,
    config file, none yet?
[ ] Any existing device-frame / mockup assets — what format (SVG, PNG, vector Flutter
    widgets)? Resolution of source assets — this matters, a low-res PNG device frame
    will cap output quality regardless of pipeline correctness.
```

### 2.2 Output of Phase 0

`CODEBASE_AUDIT.md` containing:
1. Repo map with one-line purpose per relevant file/folder.
2. Real (not assumed) Firestore template schema, pasted verbatim.
3. A gap list: everything in this plan that assumes something the codebase doesn't currently have.
4. A risk list: anything discovered that could block "perfect" per §1 (e.g. low-res device frame assets, a canvas library that can't render off-screen, a web editor that only supports one fixed aspect ratio).

### 2.3 Definition of Done — Phase 0

You can accurately answer, with evidence (file + line reference), every checklist item in §2.1. If any answer is "I couldn't find this / it doesn't exist," that's a valid answer — record it as a gap, don't guess.

**Do not proceed to Phase 3 (or any implementation) until this file exists and is complete.**

---

## 3. Phase 1 — Single Source of Truth for Store Specifications

### 3.1 The problem this solves

Store requirements change (Apple added the 6.9" class and iPhone Air's 1260×2736 panel; Google's rules are range-based, not fixed). If size numbers are hardcoded in multiple places (web editor, Flutter export screen, validation logic), they will drift out of sync. There must be exactly one place these numbers live.

### 3.2 Implementation

Create `store_export_specs.json` — a single versioned config file, checked into the repo (not Firestore — this is app-shipped config, not user data, so it updates with app releases, not remotely):

```json
{
  "specVersion": "2026.07",
  "lastVerified": "2026-07-04",
  "appleAppStore": {
    "requiresExactMatch": true,
    "colorSpace": "RGB",
    "allowedFormats": ["PNG", "JPEG"],
    "alphaChannelAllowed": true,
    "deviceClasses": [
      {
        "id": "iphone_6_9",
        "label": "iPhone 6.9\" (required)",
        "width": 1320, "height": 2868,
        "required": true,
        "coversDevices": ["iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 16 Plus", "iPhone 15 Plus"],
        "alsoAccepted": [
          {"width": 1290, "height": 2796},
          {"width": 1260, "height": 2736, "note": "iPhone Air native panel"}
        ]
      },
      {
        "id": "iphone_6_5",
        "label": "iPhone 6.5\" (fallback only)",
        "width": 1242, "height": 2688,
        "required": false,
        "note": "Only needed if 6.9\" set is not provided"
      },
      {
        "id": "ipad_13",
        "label": "iPad 13\" (required if app supports iPad)",
        "width": 2064, "height": 2752,
        "required": "conditional",
        "alsoAccepted": [{"width": 2048, "height": 2732, "note": "legacy 12.9\" size, still valid"}]
      }
    ],
    "minPerClass": 1,
    "maxPerClass": 10
  },
  "googlePlay": {
    "requiresExactMatch": false,
    "colorSpace": "RGB",
    "allowedFormats": ["PNG_24BIT_NO_ALPHA", "JPEG"],
    "alphaChannelAllowed": false,
    "minSidePx": 320,
    "maxSidePx": 3840,
    "maxAspectRatio": 2.0,
    "maxFileSizeMB": 8,
    "deviceClasses": [
      {
        "id": "phone",
        "label": "Phone (required)",
        "recommendedWidth": 1080, "recommendedHeight": 1920,
        "required": true,
        "minCount": 2,
        "featuringMinCount": 4,
        "featuringMinPx": 1080
      },
      {
        "id": "tablet_7in",
        "label": "7\" tablet",
        "recommendedWidth": 1200, "recommendedHeight": 1920,
        "required": false
      },
      {
        "id": "tablet_10in",
        "label": "10\" tablet",
        "recommendedWidth": 1600, "recommendedHeight": 2560,
        "required": false
      }
    ],
    "featureGraphic": {"width": 1024, "height": 500, "alphaChannelAllowed": false}
  }
}
```

This file is the **only** place pixel numbers live. The Export screen (§11.11 of DESIGN.md), any validation code, and any documentation must read from this file — never redeclare the numbers.

### 3.3 A verification script, not just a config file

Write `scripts/verify_store_specs.dart` (or `.js`/`.ts` if it makes more sense to run from the web editor side — decide based on Phase 0 findings) that:
- Loads `store_export_specs.json`
- Cross-checks it against a short list of assertions you write from the current Apple/Google documentation (you have researched this as of the plan's writing — re-verify current numbers via web search before hardcoding, since these change)
- Is meant to be re-run periodically (flag this to the user: recommend re-running before each store submission cycle, since Apple/Google add device classes over time)

### 3.4 Definition of Done — Phase 1

- `store_export_specs.json` exists, contains every currently-current dimension, and nothing else in the codebase hardcodes a store dimension outside this file.
- `verify_store_specs.dart` runs and passes.
- `LEARNINGS.md` records the date these numbers were verified and the source.

---

## 4. Phase 2 — Canonical Template Coordinate System (the hard problem)

### 4.1 Why this is the crux of the whole plan

Apple's 6.9" ratio is ~1:2.173. Google Play's standard phone ratio is 1:1.778 (9:16). These are **different aspect ratios**. A template authored at one ratio cannot simply be "scaled" to the other without either cropping content or leaving dead space — scaling alone does not solve cross-store export. This is the single most common way screenshot tools produce broken output, and it must be solved architecturally, not papered over per-template.

**Do not solve this by asking template authors to manually rebuild each template per store.** That fails the "learns on its own, best result" bar and doesn't scale to "tons of templates."

### 4.2 The approach: normalized coordinates + safe-zone authoring

1. **Every element's position and size in Firestore is stored as a fraction of canvas dimensions (0.0–1.0), never absolute pixels.** E.g. `{"x": 0.5, "y": 0.12, "width": 0.8, "height": 0.15}` — centered horizontally, near the top, 80% of canvas width. This alone lets one template render correctly at any absolute pixel size that shares its aspect ratio. (Check Phase 0 findings: if the web editor currently stores absolute pixels, this requires a migration — plan for it, don't skip it.)

2. **Aspect ratio is not fully solved by normalization alone** — normalization handles "same ratio, different pixel count" (e.g. 1080×1920 vs 2160×3840). It does not handle "different ratio" (1:2.173 vs 1:1.778). For that:

   - Every template declares a **canonical authoring ratio** (recommend authoring at the tallest/narrowest common ratio in use, currently Apple's 6.9" class ~0.4602, since it's easier to pad a wider canvas than to crop a narrower one).
   - Every element additionally carries a **safe-zone flag**: `"pinning": "safe" | "bleed"`. Safe-pinned elements (text, logos, key UI) must be guaranteed visible at the **narrowest** supported ratio (Google Play's 9:16, which is visually "shorter" relative to width than Apple's 6.9" canvas). Bleed elements (background art, decorative fill) are allowed to be cropped at the edges when rendered at a wider ratio.
   - At export time, for a target ratio narrower/wider than the authoring ratio, the render engine computes a **center-crop or letterbox rule**: background/bleed layers scale-to-fill and crop at edges; safe-pinned layers scale-to-fit within the safe zone and never get cropped.
   - Concretely: define the safe zone as a centered rectangle at, say, 92% width / 90% height of the narrowest supported ratio. Store this margin in `store_export_specs.json` as `"universalSafeZoneMargin": {"horizontal": 0.04, "vertical": 0.05}` so it's tunable in one place, not hardcoded in the renderer.

3. **The web editor must show the safe-zone overlay while authoring**, so template designers see, live, what will and won't survive a cross-store export. This is a web editor UI task, not just a Flutter task — flag it as its own subtask; don't let it get silently dropped because most of this plan is Flutter-side.

### 4.3 Firestore schema (target state — reconcile with Phase 0 findings before writing migration code)

```json
{
  "templateId": "string",
  "canonicalRatio": { "width": 1320, "height": 2868 },
  "backgroundLayer": { "type": "color|gradient|image", "...": "..." },
  "elements": [
    {
      "id": "el_001",
      "type": "text|image|shape|deviceFrame|sticker",
      "pinning": "safe",
      "x": 0.5, "y": 0.12, "width": 0.8, "height": 0.15,
      "rotation": 0,
      "zIndex": 3,
      "properties": { "...": "type-specific, see DESIGN.md §11.9" }
    }
  ],
  "schemaVersion": 2
}
```

`schemaVersion` matters: once real templates exist under an old schema, you need a migration path, not a breaking change. Write a migration function and a fallback reader that can render `schemaVersion: 1` documents if any exist (check Phase 0 findings for whether this is a greenfield schema or one with live data).

### 4.4 Definition of Done — Phase 2

- Firestore schema documented and versioned; migration script exists if old-format documents were found in Phase 0.
- Web editor writes normalized coordinates + pinning metadata.
- Web editor renders a visible safe-zone guide during authoring.
- A single template, authored once, has been manually tested rendering correctly at both a 1:2.173 and a 1:1.778 target in the Flutter app without per-ratio rework.

---

## 5. Phase 3 — High-Fidelity, Resolution-Independent Rendering Engine

### 5.1 The core rule

**The export render must never be a screenshot of what's on the user's screen.** Capturing the visible on-screen canvas via `RepaintBoundary.toImage(pixelRatio: ...)` at whatever pixelRatio math gets you close to the target is the naive approach and it is not good enough for "perfect" — it ties output fidelity to the device's actual screen density and the widget's on-screen logical size, both of which vary per device and introduce rounding error at large scale factors.

**Correct approach:** build the canvas widget tree **off-screen**, sized in logical pixels to exactly match the target export resolution at a controlled `pixelRatio` (typically 1.0, since the widget's logical size already equals the target physical pixel size), then capture it. This decouples export quality entirely from whatever device the export is triggered on.

### 5.2 Implementation sketch (validate against actual Flutter/Dart version found in Phase 0)

```dart
Future<Uint8List> renderTemplateAtResolution({
  required TemplateModel template,
  required int targetWidthPx,
  required int targetHeightPx,
}) async {
  // Build the canvas as an off-screen widget sized exactly to target px,
  // using logical pixels == physical pixels (pixelRatio 1.0 at capture time).
  final GlobalKey repaintKey = GlobalKey();

  final Widget offscreenCanvas = RepaintBoundary(
    key: repaintKey,
    child: SizedBox(
      width: targetWidthPx.toDouble(),
      height: targetHeightPx.toDouble(),
      child: CanvasRenderer(
        template: template,
        // CanvasRenderer resolves every element's normalized x/y/w/h
        // against these exact target dimensions -- not against
        // whatever the editor screen size was.
      ),
    ),
  );

  // Mount off-screen (e.g. via an Overlay entry positioned off-canvas,
  // or a hidden route) -- confirm the exact off-screen-mount mechanism
  // against what's idiomatic for the Flutter version in use.
  await _mountOffscreen(offscreenCanvas);
  await _waitForAllImagesAndFontsToLoad(); // see 5.3 -- do not skip this

  final RenderRepaintBoundary boundary =
      repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
  final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await _unmountOffscreen();

  return bytes!.buffer.asUint8List();
}
```

### 5.3 Non-negotiable correctness details (each of these has silently broken export pipelines before — verify all of them explicitly, don't assume Flutter handles it for you)

- **Wait for asset decode completion before capture.** `Image.network`/`Image.file` widgets can report "built" before the actual bitmap is decoded and painted. Capturing one frame too early silently produces a blank or half-rendered layer. Use `precacheImage` for every image element and `await` it before calling `toImage`.
- **Wait for font loading.** `google_fonts` package loads fonts asynchronously on first use; if a font hasn't finished loading, text renders in a fallback font silently — no error thrown. Explicitly await font load (or pre-bundle template fonts as assets rather than fetching at runtime, which Phase 0 should determine is feasible given offline requirements anyway).
- **No JPEG for intermediate steps.** Compose everything as PNG (lossless) internally; only convert to JPEG as the final step if the user's chosen export format requires it, and only once.
- **Strip alpha channel correctly for Google Play PNGs**, not by hoping the encoder does it — explicitly flatten the image onto an opaque background of the template's actual background color before encoding for Play, so there's no transparent-edge artifacting.
- **Do not resize a rendered bitmap after the fact to hit a target size.** If you need a different resolution, re-render the widget tree at that resolution from source data — never resample a rendered PNG. This is the difference between "designed at this resolution" and "scaled to this resolution," which is exactly what §1.2 forbids.
- **Device frame / mockup assets must be vector (SVG rendered at target size) or supplied at a source resolution higher than the largest target** (2064×2752 for iPad). If Phase 0 found raster device-frame assets below this resolution, that's a blocking gap — flag it, don't silently ship soft device frames.
- **Batch exports must render sequentially or with bounded concurrency**, not all at once — off-screen widget trees at 2000px+ dimensions are memory-heavy; unbounded parallel rendering will OOM on lower-end devices. Cap concurrent renders (start with 2, tune empirically) and dispose each `ui.Image` after encoding.

### 5.4 Definition of Done — Phase 3

- A template renders identically (pixel-diffable, not just "looks similar") whether exported from a small phone or a large tablet — proving output is decoupled from device screen density.
- A golden test exists (§6) proving no visible artifacts from async image/font loading race conditions, run at least 20 times in CI to catch intermittent races (these bugs are often flaky, not deterministic).
- Memory profiling shows no OOM when batch-exporting all required sizes for both stores in one action on a mid-tier test device.

---

## 6. Phase 4 — Multi-Target Batch Export Pipeline

### 6.1 Behavior

From the Export screen (DESIGN.md §11.11), the user selects one or more target device classes across both stores. The pipeline:

1. Reads target list from `store_export_specs.json` (never hardcoded).
2. For each target, calls `renderTemplateAtResolution` (Phase 3) at that exact pixel size.
3. Applies store-specific post-processing: alpha-strip for Play, format conversion, quality setting for JPEG.
4. Validates the output (Phase 5) **before** writing it to disk or letting the user believe export succeeded.
5. Writes all outputs to a per-export folder, named clearly: `iphone_6_9_1320x2868.png`, `play_phone_1080x1920.png` — never ambiguous generic names like `export1.png`.
6. If exporting multiple files, offers a zip bundle (per DESIGN.md's multi-select export UI).

### 6.2 Definition of Done — Phase 4

- Selecting "all required sizes for both stores" in one action produces a correct, validated file for every required size, with zero manual per-size steps.
- Filenames are unambiguous and self-documenting.

---

## 7. Phase 5 — Automated Validation (the safety net)

Every exported file passes through a validator **before** being surfaced to the user as complete. This is what makes failures loud instead of silent (§1.6).

```dart
class ExportValidationResult {
  final bool passed;
  final List<String> failures;
}

ExportValidationResult validateExport({
  required Uint8List fileBytes,
  required ExportTargetSpec target, // pulled from store_export_specs.json
}) {
  final failures = <String>[];
  final decoded = img.decodeImage(fileBytes)!;

  if (decoded.width != target.expectedWidth || decoded.height != target.expectedHeight) {
    failures.add('Dimension mismatch: got ${decoded.width}x${decoded.height}, '
        'expected ${target.expectedWidth}x${target.expectedHeight}');
  }
  if (target.store == Store.googlePlay) {
    final aspect = decoded.width / decoded.height;
    final maxRatio = 2.0;
    if (aspect > maxRatio || (1 / aspect) > maxRatio) {
      failures.add('Aspect ratio ${aspect.toStringAsFixed(3)} exceeds Play\'s 2:1 cap');
    }
    if (decoded.hasAlpha) {
      failures.add('Alpha channel present -- Google Play rejects PNGs with alpha');
    }
  }
  if (fileBytes.lengthInBytes > target.maxFileSizeBytes) {
    failures.add('File size ${fileBytes.lengthInBytes} exceeds ${target.maxFileSizeBytes}');
  }

  return ExportValidationResult(passed: failures.isEmpty, failures: failures);
}
```

If validation fails, the Export screen shows the **specific failure reason** to the user (or logs it for you to fix, if triggered from an automated test) — never a generic "export failed."

### 7.1 Definition of Done — Phase 5

- No file can reach the user's device/Downloads folder without passing validation.
- Every possible failure mode listed in §1 has a corresponding automated check here.

---

## 8. Phase 6 — Golden/Regression Testing

Set up Flutter golden tests (`flutter test --update-goldens` workflow) for:
- At least 3 representative templates × both canonical ratios (Apple 6.9", Play 9:16) × both a text-heavy and an image-heavy variant.
- Re-run on every change to `CanvasRenderer` or the export pipeline. A golden test failure here is a real regression, not noise — investigate every one, don't `--update-goldens` reflexively without checking the diff.

Add a CI step (check Phase 0 findings for existing CI config; extend it, don't replace it) that runs `verify_store_specs.dart` + golden tests + the batch-export-then-validate flow against a fixture template, on every PR touching the editor, renderer, or export code.

### Definition of Done — Phase 6

- Golden tests exist and are wired into CI.
- A deliberate regression (e.g. temporarily reintroducing a resample-after-render step) is caught by the test suite before merging — verify this by actually trying it once, then reverting.

---

## 9. Continuous Self-Verification Loop (how you "learn on your own")

You do not have memory across sessions unless you write it down. This is how you make the second week of work better than the first, and how a different session of you (or a human) can pick this up without re-deriving everything:

1. **After every phase, before moving to the next, re-read `CODEBASE_AUDIT.md` and `LEARNINGS.md` in full.** Confirm your next steps still match reality — code discovered in Phase 0 may have changed if you touched it in Phase 1 or 2.
2. **Every time an assumption from this plan turns out to be wrong** (e.g. "I assumed the web editor stored percentages but it stores absolute px"), record it in `LEARNINGS.md` with: what you assumed, what was actually true, what you changed as a result. This is not busywork — it's the mechanism that prevents repeating the same wrong turn.
3. **Every time you hit a store-requirement fact you had to look up**, record the source and date in `LEARNINGS.md`. Store requirements drift; a future session needs to know when this was last verified and re-check if it's been more than ~2 months.
4. **Before declaring the whole plan complete**, re-run the full Definition of Done checklist for every phase in sequence, not just the last one — a later phase's implementation can silently break an earlier phase's guarantee (e.g. a later performance optimization that reintroduces upscaling).
5. **If you find yourself about to hardcode a number that appears in `store_export_specs.json`, stop.** That's the single most common way this kind of pipeline rots over time. Read from the config, always.

---

## 10. Anti-Patterns — do not do these regardless of how convenient they seem mid-task

- ❌ Scaling one rendered bitmap to produce multiple output sizes.
- ❌ Hardcoding pixel dimensions anywhere outside `store_export_specs.json`.
- ❌ Capturing the on-screen editor canvas via `RepaintBoundary` at whatever pixelRatio math happens to land near the target, instead of building a dedicated off-screen render at the exact target size.
- ❌ Assuming an image or font finished loading because the widget "built."
- ❌ Encoding a Google Play PNG without explicitly verifying/stripping the alpha channel.
- ❌ Treating a template's authoring ratio as the only ratio it will ever export at.
- ❌ Silent export failures — every failure must produce a specific, actionable message.
- ❌ Skipping Phase 0 because "the plan already describes the architecture" — the plan describes the *target* architecture; Phase 0 is what tells you the *actual current* state and the gap between them.
- ❌ Updating `LEARNINGS.md` after the fact from memory instead of in the moment a decision is made.

---

## 11. Final Definition of Done — the whole plan

- [ ] `CODEBASE_AUDIT.md` complete and accurate.
- [ ] `store_export_specs.json` is the single source of truth; verification script passes.
- [ ] Template schema uses normalized coordinates + safe-zone pinning; web editor authors against it with a visible safe-zone guide.
- [ ] Off-screen, resolution-independent rendering engine implemented; asset/font race conditions explicitly handled.
- [ ] Batch export produces every required size for both stores in one user action, correctly named.
- [ ] Every exported file passes automated validation (dimensions, aspect ratio, alpha, format, file size) before being surfaced as successful.
- [ ] Golden tests cover representative templates across both canonical ratios and are wired into CI.
- [ ] `LEARNINGS.md` contains a dated, sourced record of every store-spec fact and every non-obvious decision made during implementation.
- [ ] A manual end-to-end test: author one new template in the web editor, sync to Firestore, download in the Flutter app, batch-export all required sizes for both stores, and confirm every file uploads successfully in a real (or sandboxed) App Store Connect / Play Console session.

---

*End of EXPORT_PIPELINE_PLAN.md — v1.0*  
*Execute phases in order. Do not skip Phase 0. Update CODEBASE_AUDIT.md and LEARNINGS.md continuously, not retroactively.*
