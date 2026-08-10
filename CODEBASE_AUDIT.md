# CODEBASE_AUDIT.md

## 1. Repo Map & Purpose
### Flutter App
- `lib/main.dart` - Entry point
- `lib/models/template.dart` - Template schema (includes AES decryption logic)
- `lib/widgets/dynamic_template.dart` - Canvas rendering logic (uses a Stack of widgets with absolute fractional coordinates)
- `lib/screens/export/export_screen.dart` - Existing export logic using `RepaintBoundary.toImage` with hardcoded resolutions and aspect-ratio scaling.
- `lib/providers/` - Riverpod state management.
- `test/` - Empty directory (no existing tests).
- `pubspec.yaml` - Dependencies include `image: ^4.1.7`, `file_saver: ^0.2.14`, `gal: ^2.3.2`, `lucide_flutter`.

### Web Editor
- `app.js` - Contains logic for the web-based canvas (HTML/CSS + vanilla JS). Uses fixed 390x844 dimensions.

## 2. Real Firestore Template Schema (from template.dart)
```json
{
  "id": "string",
  "name": "string",
  "category": "string",
  "thumbnailUrl": "string",
  "isPro": false,
  "isDownloaded": false,
  "localPath": "string",
  "fileSizeBytes": 0,
  "deviceType": "phone|tablet|desktop",
  "description": "string",
  "tags": ["string"],
  "screenshotSlots": 1,
  "headlineFont": "string",
  "subheadlineFont": "string",
  "layout": [
    {
      "type": "text|image|shape|deviceFrame|sticker",
      "x": 0.5,
      "y": 0.12,
      "width": 0.8,
      "height": 0.15,
      "scale": 1.0,
      "rotation": 0,
      "color": "#FFFFFF",
      "opacity": 1.0
    }
  ],
  "createdAt": 1700000000
}
```
*Note: Some fields may be encrypted under `encryptedData` in Firestore.*

## 3. Findings vs. Plan Checklist
- **Where/how is canvas rendered:** Flutter uses a `Stack` wrapped in a `Container` (`dynamic_template.dart`). Elements positioned via `Positioned` + `FractionalTranslation`.
- **Existing export code:** `export_screen.dart` exports iOS and Android variants by resizing an offscreen/hidden widget and capturing with `RepaintBoundary`. It has hardcoded dimensions.
- **Coordinate system:** Web editor uses fractional coords (0.0 - 1.0) for x, y, width, height.
- **Web editor multiple ratios:** No, fixed at 390x844.
- **Images/assets referenced:** URLs in Firestore. Local paths if downloaded.
- **Text representation:** `content`, `fontName`, `fontSize` (fractional), `color`.
- **Flutter rendering approach:** `Stack` of `Positioned` elements. Shapes are drawn with `Container` or `CustomPaint`.
- **RepaintBoundary used:** Yes, in `export_screen.dart`.
- **Image/export packages:** `image`, `file_saver`, `gal`, `path_provider`.
- **Flutter/Dart SDK:** SDK `^3.11.0`.
- **Existing tests:** None. `test/` directory is empty.
- **How sizes are determined:** Hardcoded in `export_screen.dart`.
- **Device frames:** Mockups are drawn natively in Flutter (`Container` with borders), not raster PNGs.

## 4. Gap List
- No `store_export_specs.json` exists.
- The web editor only supports one fixed ratio (390x844).
- No safe-zone metadata (`pinning: safe | bleed`) in the `layout` schema.
- Export pipeline does not explicitly handle Google Play alpha channel stripping.
- Export pipeline uses `RepaintBoundary` on a hidden widget tree instead of a proper resolution-independent off-screen renderer.
- No CI/golden tests exist.

## 5. Risk List
- **Aspect Ratio Shift:** Since elements size relative to the canvas height/width, rendering a 19.5:9 template at 2:1 causes shifting. The plan suggests normalizing height/width, which was partially addressed manually but still needs full `pinning` implementation for perfection.
- **Async Rendering:** Currently relies on an arbitrary 300ms delay before `toImage()`. This is a race condition for fonts and images.
