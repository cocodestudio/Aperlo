# UI_CONSISTENCY.md — FrameKit Design Token Reference
> **Always read this file before writing any UI code.**  
> All colors, fonts, spacing, radius, shadow, and animation values come from here. No magic numbers.

---

## Colors (`lib/core/theme/app_colors.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| `AppColors.background` | `#F5F7F5` | Scaffold background, ambient |
| `AppColors.surface` | `#FFFFFF` | Cards, panels, dialogs |
| `AppColors.surfaceRaised` | `#EEF1EE` | Bottom sheets, overlay headers |
| `AppColors.surfaceMuted` | `#E7EBE7` | Inactive tabs, disabled backgrounds |
| `AppColors.borderSubtle` | `#DCE0DC` | Hairline dividers |
| `AppColors.borderDefault` | `#C8CEC8` | Input outlines, card strokes |
| `AppColors.borderStrong` | `#A0A8A0` | Focused inputs, selected states |
| `AppColors.inkPrimary` | `#141A14` | Body text, labels |
| `AppColors.inkSecondary` | `#475247` | Descriptions, secondary labels |
| `AppColors.inkMuted` | `#7D877D` | Captions, placeholders |
| `AppColors.inkDisabled` | `#B0B8B0` | Inactive text |
| `AppColors.accent` | `#1A6B4A` | Deep forest green — the only accent |
| `AppColors.accentHover` | `#145A3D` | Press/hover on accent |
| `AppColors.accentTint` | `#E8F3ED` | Selected highlights, tag backgrounds |
| `AppColors.accentOn` | `#FFFFFF` | Text on accent-colored surfaces |
| `AppColors.destructive` | `#C0392B` | Errors, delete actions |
| `AppColors.destructiveTint` | `#FDECEA` | Error banners |
| `AppColors.warning` | `#A0660A` | Caution states |
| `AppColors.warningTint` | `#FDF3E3` | Warning banners |

---

## Typography (`lib/core/theme/app_text_styles.dart`)

**Typefaces:**
- **Display/Headings:** `GoogleFonts.syne()` — weights 700, 800. Min size: 17sp. NEVER use for body.
- **Body/UI:** `GoogleFonts.dmSans()` — weights 400, 500, 600. NEVER use 700.
- **Mono/Technical:** `GoogleFonts.syneMono()` — weight 400. For specs, IDs, dimensions.

**Case rule:** Sentence case everywhere. "Export screenshot" not "Export Screenshot."

| Style | Family | Weight | Size | Usage |
|-------|--------|--------|------|-------|
| `AppText.display` | Syne | 800 | 32sp | Onboarding headlines |
| `AppText.headline1` | Syne | 700 | 24sp | Screen titles |
| `AppText.headline2` | Syne | 700 | 20sp | Section headers, dialog titles |
| `AppText.headline3` | Syne | 700 | 17sp | Card titles, collection names |
| `AppText.bodyLarge` | DM Sans | 400 | 16sp | Paragraph body |
| `AppText.bodyDefault` | DM Sans | 400 | 14sp | UI descriptions, list items |
| `AppText.bodySmall` | DM Sans | 400 | 13sp | Captions, helper text |
| `AppText.labelLarge` | DM Sans | 600 | 14sp | Button labels, tabs |
| `AppText.labelDefault` | DM Sans | 500 | 13sp | Badge text, tags |
| `AppText.labelSmall` | DM Sans | 500 | 11sp | Timestamps, secondary badges |
| `AppText.mono` | Syne Mono | 400 | 12sp | Export specs, IDs, dimensions |

---

## Spacing (`lib/core/theme/app_spacing.dart`)

Base unit: 4dp

| Token | Value | Common use |
|-------|-------|-----------|
| `AppSpacing.s2` | 2dp | Icon-to-label gap, badge padding |
| `AppSpacing.s4` | 4dp | Stacked labels, chip padding |
| `AppSpacing.s6` | 6dp | Tag internal padding |
| `AppSpacing.s8` | 8dp | Standard internal padding |
| `AppSpacing.s12` | 12dp | Card internal padding (tight) |
| `AppSpacing.s16` | 16dp | **Default screen horizontal margin** |
| `AppSpacing.s20` | 20dp | Prominent items, section headers |
| `AppSpacing.s24` | 24dp | Section gap within screen |
| `AppSpacing.s32` | 32dp | Major section separation |
| `AppSpacing.s40` | 40dp | Above/below screen titles |
| `AppSpacing.s48` | 48dp | Above empty state illustration |
| `AppSpacing.s64` | 64dp | Maximum structural breathing room |

---

## Border Radius (`lib/core/theme/app_radius.dart`)

| Token | Value | Usage |
|-------|-------|-------|
| `AppRadius.r2` | 2dp | Tooltip arrows, nav pill indicator |
| `AppRadius.r6` | 6dp | Tags, badges, chips, keyboard hints |
| `AppRadius.r10` | 10dp | **Input fields** |
| `AppRadius.r12` | 12dp | **Standard cards, collection folders, template cards, bottom sheets** |
| `AppRadius.r16` | 16dp | Large cards, modal dialogs, full-screen bottom sheets |
| `AppRadius.r20` | 20dp | FABs, prominent action buttons |
| `AppRadius.full` | 9999dp | Pills: toggles, filter chips, selected states |

**Sharp edges (radius = 0):**
- Editor canvas border — it's a precision work surface
- Toolbar/panel separators
- Bottom navigation bar background (full bleed)

---

## Shadows (`lib/core/theme/app_shadows.dart`)

Shadow color: `Color(0xFF141A14)` (inkPrimary)

| Token | Usage |
|-------|-------|
| `AppShadows.none` | No shadow |
| `AppShadows.subtle` | Bottom nav top edge, small floating chips |
| `AppShadows.card` | **Default card shadow** |
| `AppShadows.raised` | Hovered/pressed cards |
| `AppShadows.float` | FAB, floating panels, dialogs |

**Rule:** Never stack more than one shadow on one element.

---

## Icons (`lucide_flutter` package)

Stroke width: **1.5dp** at 24dp size.

| Size | Usage |
|------|-------|
| 16dp | Inline/label |
| 20dp | Dense lists |
| 24dp | Standard |
| 28dp | Nav bar active |

**Color rules:**
- Active: `AppColors.accent`
- Inactive: `AppColors.inkMuted`
- On accent background: `AppColors.accentOn`
- Destructive: `AppColors.destructive`

---

## Animation (`lib/core/theme/app_motion.dart`)

| Duration | Value | Use |
|----------|-------|-----|
| `AppMotion.instant` | 0ms | State swaps (icon fill toggle) |
| `AppMotion.fast` | 120ms | Button press, checkbox |
| `AppMotion.base` | 220ms | Navigation, panel open/close |
| `AppMotion.slow` | 350ms | Bottom sheet, modal appear |
| `AppMotion.stagger` | 60ms | Per-item list/grid stagger |

| Curve | Value | Use |
|-------|-------|-----|
| `AppMotion.easeOut` | `Curves.easeOutCubic` | Elements entering |
| `AppMotion.easeIn` | `Curves.easeInCubic` | Elements leaving |
| `AppMotion.easeInOut` | `Curves.easeInOutCubic` | Repositioning |
| `AppMotion.spring` | `Curves.elasticOut` | FAB, success pops |

**Always check:** `MediaQuery.of(context).disableAnimations` — if true, use instant transitions.

---

## Bottom Navigation

- 4 items max: Home, Templates, Collections, Profile
- Height: 64dp + system nav inset
- Background: `AppColors.surface`
- Top border: 1dp `AppColors.borderSubtle`
- Active indicator: 4dp × 28dp green pill (`AppRadius.r2`), slides horizontally ABOVE the active icon

---

## Component Rules

### Buttons
- **Primary:** accent bg, white label, 48dp height, radius12, DM Sans 600
- **Secondary:** transparent bg, 1.5dp borderDefault, inkPrimary label, 48dp
- **Ghost:** no bg/border, accent label, 40dp, pressed=accentTint bg
- **Destructive:** destructive bg, white label
- **Icon:** 40×40 tap target, 24dp icon, radius10

### Cards
- Standard: surfaceCard shadow, radius12, 1dp borderSubtle
- Template: radius12, shadowCard, 9:16 aspect ratio
- Screenshot: radius12, shadowCard, 9:16 aspect ratio

### App Bar
- Title: **left-aligned** (never centered)
- No elevation/shadow (page scroll creates separation)
- Background bleeds into page background

### Dialogs
- Barrier: inkPrimary at 30% opacity (NOT pure black)
- Button order: secondary first, primary second (right-aligned)

### Empty States
1. Illustration (max 200dp wide)
2. 24dp gap
3. Headline (Syne 700 20sp)
4. 8dp gap
5. Description (DM Sans 400 14sp inkMuted, max 260dp wide)
6. 32dp gap
7. Primary Button (if action available)

---

## File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_shadows.dart
│   │   ├── app_motion.dart
│   │   └── app_theme.dart
│   └── router/
│       └── app_router.dart
├── models/
│   ├── collection.dart
│   ├── screenshot.dart
│   ├── template.dart
│   ├── user_model.dart
│   └── canvas_element.dart
├── providers/
│   ├── auth_provider.dart
│   ├── collections_provider.dart
│   ├── templates_provider.dart
│   └── editor_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── widgets/
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── collection_card.dart
│   ├── template_card.dart
│   ├── screenshot_card.dart
│   ├── category_chip.dart
│   ├── pro_badge.dart
│   ├── empty_state.dart
│   └── bottom_nav.dart
└── screens/
    ├── splash/splash_screen.dart
    ├── onboarding/onboarding_screen.dart
    ├── auth/auth_screen.dart
    ├── home/home_screen.dart
    ├── collections/collections_screen.dart
    ├── collections/collection_detail_screen.dart
    ├── templates/template_browser_screen.dart
    ├── templates/template_preview_screen.dart
    ├── editor/editor_screen.dart
    ├── export/export_screen.dart
    └── profile/profile_screen.dart
```

---

## DON'TS (from DESIGN.md §15)

1. ❌ No gradients in UI chrome (only inside canvas)
2. ❌ No Poppins, Inter, Plus Jakarta Sans
3. ❌ Never center-align App Bar title
4. ❌ No bottom nav with 5+ items
5. ❌ No rounded corners on editor canvas
6. ❌ No spinner when skeleton loader is possible
7. ❌ No pure `#000000` or `#FFFFFF` for text/backgrounds at page level
8. ❌ No more than 2 typefaces per screen (Syne + DM Sans; Syne Mono only for data)
9. ❌ Never stack 2 shadows on one element
10. ❌ No SnackBar for destructive feedback — use confirmation dialog
11. ❌ Never animate canvas content as a nav transition
12. ❌ Never drop below target pixel dimensions on export
