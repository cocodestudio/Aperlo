# DESIGN.md — App Store Screenshot Maker
## Premium Flutter App · Light Theme · Complete Design Specification

---

## 1. App Identity

**Working Name:** FrameKit  
**Tagline:** *Screenshot it. Ship it.*  
**Voice:** Precise, confident, quietly professional. Never cutesy. Never corporate. Talks like a senior designer giving a brief — direct, no filler.  
**Audience:** Solo developers, indie app makers, small studios who know what they want and are frustrated that existing tools feel either too basic or too bloated.

---

## 2. Design Philosophy

### 2.1 Core Principles

1. **The canvas is the product.** Every UI element outside the editor canvas exists to serve it. Navigation fades back. Panels feel subordinate. The canvas earns visual dominance.

2. **Whitespace is not empty space.** Margins, padding, and breathing room are used intentionally and asymmetrically — not as formula (8-16-24-32). The eye should land where we intend.

3. **One thing at a time.** Each screen has exactly one primary action. Secondary actions exist but don't compete for attention. This is not Canva-for-everything; it is a specialist tool that respects the user's focus.

4. **Quality signals matter at micro scale.** A 1dp border on a selected template. The 0.2s ease curve on a panel open. The way a badge aligns optically (not mathematically) to its container. These are what separate premium from generic.

5. **No decoration that doesn't earn its place.** Icons, dividers, shadows, and tints only appear when they help the user navigate or understand. Nothing is added "to make it look designed."

6. **High-fidelity output demands high-fidelity input UI.** If the tool produces pixel-perfect screenshots, the tool itself must feel pixel-perfect. There is no tolerance for layout jitter, color inconsistency, or font rendering issues.

### 2.2 Aesthetic Direction

**Studio Precision with Forest Depth.** The UI draws from the physical world of a professional photographic darkroom or print studio: clean white work surfaces, muted green-tinted ambient light, precise instruments. Nothing warm-and-cozy. Nothing cold-and-clinical. It sits between the two with authority.

This maps to:
- A barely-tinted white-to-soft-sage background (not pure white, not cream)
- Deep forest green as the single accent color — underused in creative tools, immediately distinctive
- Near-black type with a subtle green undertone rather than neutral gray
- Zero gradients in UI chrome. Gradients live only inside the canvas.

---

## 3. Color System

### 3.1 Palette — Named Values

```
Background       #F5F7F5    Barely-green off-white. The app's ambient light.
Surface          #FFFFFF    Pure white. Cards, panels, canvases, dialogs.
Surface Raised   #EEF1EE    Slightly deeper. Bottom sheets, overlay headers.
Surface Muted    #E7EBE7    Tinted fill. Inactive tabs, disabled backgrounds.

Border Subtle    #DCE0DC    Hairline edges, dividers.
Border Default   #C8CEC8    Input outlines, card strokes, panel edges.
Border Strong    #A0A8A0    Focused inputs, selected states.

Ink Primary      #141A14    Near-black with green undertone. Body text, labels.
Ink Secondary    #475247    Mid. Descriptions, secondary labels.
Ink Muted        #7D877D    Captions, placeholders, timestamps.
Ink Disabled     #B0B8B0    Inactive text.

Accent           #1A6B4A    Deep forest green. The only accent hue.
Accent Hover     #145A3D    Deeper on press/hover.
Accent Tint      #E8F3ED    Pale green. Selected highlights, tag backgrounds.
Accent On        #FFFFFF    Text on Accent-colored surfaces.

Destructive      #C0392B    Error states, delete actions.
Destructive Tint #FDECEA    Light red backgrounds for error banners.
Warning          #A0660A    Caution states.
Warning Tint     #FDF3E3    Light amber for warning banners.
Success          #1A6B4A    Reuse Accent for success (they share the same green).
```

### 3.2 Semantic Tokens (Flutter naming)

```dart
// Background layer
kColorBackground     = Color(0xFFF5F7F5)
kColorSurface        = Color(0xFFFFFFFF)
kColorSurfaceRaised  = Color(0xFFEEF1EE)
kColorSurfaceMuted   = Color(0xFFE7EBE7)

// Borders
kColorBorderSubtle   = Color(0xFFDCE0DC)
kColorBorderDefault  = Color(0xFFC8CEC8)
kColorBorderStrong   = Color(0xFFA0A8A0)

// Text
kColorInkPrimary     = Color(0xFF141A14)
kColorInkSecondary   = Color(0xFF475247)
kColorInkMuted       = Color(0xFF7D877D)
kColorInkDisabled    = Color(0xFFB0B8B0)

// Accent
kColorAccent         = Color(0xFF1A6B4A)
kColorAccentHover    = Color(0xFF145A3D)
kColorAccentTint     = Color(0xFFE8F3ED)
kColorAccentOn       = Color(0xFFFFFFFF)

// Semantic
kColorDestructive    = Color(0xFFC0392B)
kColorDestructiveTint= Color(0xFFFDECEA)
kColorWarning        = Color(0xFFA0660A)
kColorWarningTint    = Color(0xFFFDF3E3)
```

### 3.3 Canvas Background Options (for user customization inside the editor)

The app ships 12 canvas preset backgrounds for templates. These live separately from UI chrome:

| Name         | Value     | Usage                    |
|--------------|-----------|--------------------------|
| Pearl        | #FAFAFA   | Default neutral           |
| Chalk        | #F0EEE9   | Warm off-white            |
| Slate Night  | #1C2026   | Dark professional         |
| Ink          | #111318   | Near-black editorial      |
| Forest Mist  | #EDF3EE   | Tinted green              |
| Blush        | #F8EEF0   | Soft pink                 |
| Sky          | #EEF4FB   | Soft blue                 |
| Amber        | #FBF3E8   | Warm amber                |
| Plum         | #F2EBF8   | Soft purple               |
| Ocean        | #1A3A5C   | Deep navy                 |
| Terracotta   | #3A1A12   | Deep rust                 |
| Sage         | #2A3D2E   | Deep green                |

---

## 4. Typography System

### 4.1 Typefaces

**Display / Headings: Syne**
- Google Fonts: `Syne`
- Weights used: 700, 800
- Character: Architecturally wide in heavy weights. Geometric but not cold. Brutalist in the best sense — confident, distinctive, zero apology. In the flutter_google_fonts package: `GoogleFonts.syne()`
- Where it appears: Screen titles, section headings, collection names, onboarding headlines, empty state headlines.
- **Critical:** Syne at weight 800 will feel large and dominant. Use sparingly. Never use Syne for body text.

**Body / UI: DM Sans**
- Google Fonts: `DM Sans`
- Weights used: 400, 500, 600
- Character: Low-contrast geometric sans. Warmer than Inter. Designed for legibility at small sizes. Feels human without being playful. `GoogleFonts.dmSans()`
- Where it appears: Everything else — button labels, descriptions, input text, captions, tab labels, bottom nav labels, dialog copy, error messages.

**Mono / Technical: Syne Mono**
- Google Fonts: `Syne Mono`
- Weight: 400
- Character: Consistent with the Syne family, monospaced. Feels intentional rather than fallback-y. `GoogleFonts.syneMono()`
- Where it appears: Export specs (e.g., "1290 × 2796 px"), file sizes, template IDs, keyboard shortcut hints.

### 4.2 Type Scale

All sizes in `sp`. Line heights in multipliers.

| Role            | Family    | Weight | Size  | Line Height | Letter Spacing | Usage                         |
|-----------------|-----------|--------|-------|-------------|----------------|-------------------------------|
| `display`       | Syne      | 800    | 32sp  | 1.15        | -0.5           | Onboarding headlines          |
| `headline1`     | Syne      | 700    | 24sp  | 1.2         | -0.3           | Screen titles                 |
| `headline2`     | Syne      | 700    | 20sp  | 1.25        | -0.2           | Section headers, dialog titles|
| `headline3`     | Syne      | 700    | 17sp  | 1.3         | 0              | Card titles, collection names |
| `bodyLarge`     | DM Sans   | 400    | 16sp  | 1.55        | 0              | Paragraph body text           |
| `bodyDefault`   | DM Sans   | 400    | 14sp  | 1.55        | 0              | UI descriptions, list items   |
| `bodySmall`     | DM Sans   | 400    | 13sp  | 1.5         | 0              | Captions, helper text         |
| `labelLarge`    | DM Sans   | 600    | 14sp  | 1.2         | 0.1            | Button labels, tabs           |
| `labelDefault`  | DM Sans   | 500    | 13sp  | 1.2         | 0.1            | Badge text, tags              |
| `labelSmall`    | DM Sans   | 500    | 11sp  | 1.2         | 0.3            | Timestamps, secondary badges  |
| `mono`          | Syne Mono | 400    | 12sp  | 1.4         | 0              | Export specs, IDs             |

### 4.3 Type Rules

- **Never set Syne below 17sp.** Its character is lost at small sizes and it becomes illegible.
- **DM Sans at 400 is for reading. DM Sans at 600 is for action.** Never use 700 in DM Sans — it competes with Syne for dominance.
- **Sentence case everywhere.** Not Title Case for UI labels. "Export screenshot" not "Export Screenshot." Only proper nouns and the app name are capitalized.
- **Ink Secondary (`#475247`) for all descriptions.** Never Ink Primary for body text below headlines — the contrast would be too harsh for sustained reading.

---

## 5. Spacing & Grid

### 5.1 Base Unit

`1 unit = 4dp`

### 5.2 Named Spacing Values

```
space2   =  2dp   Tightest. Icon-to-label gap, badge padding.
space4   =  4dp   Tight. Between stacked labels. Chip internal padding.
space6   =  6dp   Tag internal padding, compact list rows.
space8   =  8dp   Standard internal padding. Icon-to-text in buttons.
space12  = 12dp   Card internal padding (tight cards). Row padding.
space16  = 16dp   Default screen horizontal margin. Card padding.
space20  = 20dp   Slightly generous card padding.
space24  = 24dp   Section gap within a screen.
space32  = 32dp   Separation between major sections.
space40  = 40dp   Large section gap. Above/below screen titles.
space48  = 48dp   Generous. Above empty state illustration.
space64  = 64dp   Maximum structural breathing room.
```

### 5.3 Screen Margins

- **Phone horizontal margin:** `space16` (16dp) on both sides
- **Horizontal margin for prominent items** (section headers, large CTAs): `space20`
- **Vertical margin from top of AppBar content to first element:** `space24`
- **Bottom padding above NavBar:** `space16`

### 5.4 Grid for Template/Collection Grids

- **Collections Grid:** 2 columns, 12dp gutter, 12dp outer margin
- **Template Browser Grid:** 2 columns, 10dp gutter, 16dp outer margin
- **Elements Panel (Canva-style):** 3 columns, 8dp gutter, 12dp outer margin

---

## 6. Border Radius

Not everything is rounded equally. This is one of the most important rules.

```
radius2   =  2dp   Almost nothing. Used only for tooltip arrows and inner chip highlights.
radius6   =  6dp   Tags, badges, small chips, keyboard hint boxes.
radius10  = 10dp   Input fields. The subtle rounding signals "text entry here."
radius12  = 12dp   Standard cards. Collection folders. Template cards. Bottom sheets.
radius16  = 16dp   Large cards. Modal dialogs. Full-screen bottom sheets.
radius20  = 20dp   FABs. Prominent action buttons.
radiusFull = 9999  Pill-shaped: toggle buttons, filter chips, selected states.
```

**Deliberate sharp edges:**
- The editor canvas border: **0 radius**. The canvas is a work surface, not a card.
- Toolbar/panel separators: 0 radius.
- Bottom navigation bar background: 0 radius (full bleed).

---

## 7. Elevation & Shadow

Shadows use a warm-tinted ink, not pure black, to match the palette.

```dart
// Shadow color base: Color(0xFF141A14) — same as Ink Primary
// All shadows use BoxShadow with this color at low opacity.

kShadowNone    = []
kShadowSubtle  = [BoxShadow(color: Color(0x0A141A14), blurRadius: 4, offset: Offset(0, 1))]
kShadowCard    = [BoxShadow(color: Color(0x12141A14), blurRadius: 12, offset: Offset(0, 3))]
kShadowRaised  = [BoxShadow(color: Color(0x18141A14), blurRadius: 20, offset: Offset(0, 6))]
kShadowFloat   = [BoxShadow(color: Color(0x22141A14), blurRadius: 32, offset: Offset(0, 10))]
```

**Usage:**
- Default resting card: `kShadowCard`
- Hovered/pressed card: `kShadowRaised`
- FAB, floating panels: `kShadowFloat`
- Bottom navigation bar top edge: A `kShadowSubtle` upward — `Offset(0, -1)`
- The editor canvas: `kShadowCard` (it needs to feel like a real document)

**Rule:** Never stack more than one shadow layer. Choose the right level.

---

## 8. Iconography

**Icon Set: Lucide Icons** (`lucide_flutter` package)  
- Why: Clean, consistent stroke width (1.5dp), geometric, extensive library, open source.
- Stroke width in UI: **1.5dp** at 24dp icon size.
- Icon size variants: 16dp (inline/label), 20dp (dense lists), 24dp (standard), 28dp (nav bar active).

**Color Rules:**
- Active/filled icons: `kColorAccent` (#1A6B4A)
- Default/inactive icons: `kColorInkMuted` (#7D877D)
- Icons on accent backgrounds: `kColorAccentOn` (#FFFFFF)
- Destructive action icons: `kColorDestructive` (#C0392B)

**Key Icons (Lucide names):**
```
Home screen         → home
Collections         → folder-open
Templates           → layout-grid
Editor              → edit-3
Export/Download     → download
Add element         → plus-circle
Text tool           → type
Image/Upload        → image-plus
Shapes              → shapes
Stickers            → smile
Background          → palette
Mockup device       → smartphone
Undo                → rotate-ccw
Redo                → rotate-cw
Layer up            → bring-to-front
Layer down          → send-to-back
Delete              → trash-2
Settings            → settings
Profile             → circle-user
Search              → search
Filter              → sliders-horizontal
Check/Selected      → circle-check
Lock/Premium        → lock
Drag handle         → grip-vertical
Close               → x
More options        → ellipsis
```

---

## 9. Motion & Animation

### 9.1 Duration Scale

```
durationInstant   =  0ms   State swaps with no transition (e.g., icon fill toggle)
durationFast      = 120ms  Micro-interactions: button press, checkbox tick
durationBase      = 220ms  Standard navigation, panel open/close
durationSlow      = 350ms  Bottom sheet rise, modal appear
durationStagger   =  60ms  Per-item delay in list/grid stagger animations
```

### 9.2 Easing

```dart
kEaseOut    = Curves.easeOutCubic     // Default for elements entering screen
kEaseIn     = Curves.easeInCubic      // Elements leaving screen
kEaseInOut  = Curves.easeInOutCubic   // Elements repositioning within screen
kSpring     = Curves.elasticOut       // FAB appearance, success state pops
```

### 9.3 Specific Animations

**Template card tap → Editor transition:**  
The tapped template card scales from its grid position with a `Hero` widget, expanding to fill the screen. Duration `durationSlow` with `kEaseOut`. The card's border radius transitions from `radius12` to 0 as the canvas takes over.

**Collection folder open:**  
Folder icon does a brief "open" animation (the folder-open icon replaces folder at 1.1x scale then settles to 1.0x). The list of screenshots slides in from the right at `durationBase`.

**Properties panel (right/bottom panel in editor):**  
Slides up from bottom on mobile. `durationBase`, `kEaseOut`. The canvas area shrinks upward simultaneously rather than being overlapped.

**Bottom navigation active indicator:**  
The green accent pill slides horizontally beneath the new active tab icon. Duration `durationBase`, `kEaseInOut`. Not a fade — a physical slide.

**Export button → Success:**  
The button label morphs to a checkmark icon + "Saved to device" label, then after 2 seconds resets. Transition is a cross-fade at `durationFast`. The checkmark icon pops with `kSpring`.

**Template gallery horizontal scroll:**  
No animation added on top of Flutter's default scroll physics. Use `BouncingScrollPhysics` to give it a natural, native feel.

**Empty state illustration:**  
Fades in with a subtle upward translate (12dp → 0dp) over `durationSlow`. Only plays once on first load.

### 9.4 What NOT to animate

- Do not animate list/grid reordering unless triggered by the user dragging.
- Do not add parallax effects. They cause motion sickness and add no information.
- Do not animate the canvas itself during editing (pan, zoom are physics-based natively).
- Respect `MediaQuery.of(context).disableAnimations` for accessibility.

---

## 10. Component Library

### 10.1 Buttons

**Primary Button**
- Background: `kColorAccent` (#1A6B4A)
- Label: `kColorAccentOn`, `labelLarge`, Syne-less — use DM Sans 600
- Height: 48dp
- Horizontal padding: space20
- Border radius: `radius12`
- Pressed state: background → `kColorAccentHover`, scale 0.98x
- Disabled: background `kColorSurfaceMuted`, label `kColorInkDisabled`
- Min width: 120dp

**Secondary Button**
- Background: transparent
- Border: 1.5dp `kColorBorderDefault`
- Label: `kColorInkPrimary`, DM Sans 600 14sp
- Height: 48dp, same padding as Primary
- Pressed: background `kColorSurfaceMuted`, border `kColorBorderStrong`
- Disabled: all values at disabled equivalents

**Ghost Button (text-only)**
- No background, no border
- Label: `kColorAccent`
- Height: 40dp, padding space12 horizontal
- Pressed: background `kColorAccentTint`
- Used for: "Cancel", "Learn more", secondary navigation actions

**Destructive Button**
- Background: `kColorDestructive`
- Label: white, same specs as Primary
- Pressed: darken 10%

**Icon Button**
- 40dp × 40dp tap target (icon itself 24dp)
- Border radius: radius10
- Default background: transparent
- Hover/pressed: `kColorSurfaceMuted`
- Active/selected: `kColorAccentTint`, icon `kColorAccent`

**FAB (Floating Action Button)**
- Size: 56dp × 56dp
- Background: `kColorAccent`
- Icon: 24dp, white
- Border radius: radius20 (large pill-like)
- Shadow: `kShadowFloat`
- Label FAB variant (extended): adds label at DM Sans 600 14sp

### 10.2 Input Fields

**Text Input**
- Height: 52dp
- Border: 1.5dp `kColorBorderDefault` (radius10)
- Background: `kColorSurface`
- Focused border: 2dp `kColorAccent`
- Error border: 2dp `kColorDestructive`
- Label: Floats above the field at DM Sans 400 12sp `kColorInkMuted` when focused/filled
- Input text: DM Sans 400 15sp `kColorInkPrimary`
- Placeholder: DM Sans 400 15sp `kColorInkDisabled`
- Internal horizontal padding: space16
- Helper text below: DM Sans 400 12sp `kColorInkMuted`, space4 below field

**Search Input (Template Browser)**
- Height: 48dp
- Leading: search icon 20dp `kColorInkMuted`
- Background: `kColorSurfaceMuted`
- Border: none (filled style)
- Border radius: radiusFull (pill search feel)
- Focused: 1.5dp border `kColorAccent`, background `kColorSurface`

### 10.3 Cards

**Collection Card (folder style)**
- Width: fills column (2-column grid)
- Aspect ratio: 4:3
- Background: `kColorSurface`
- Border: 1dp `kColorBorderSubtle`
- Shadow: `kShadowCard`
- Border radius: radius12
- Top 60% of card: solid color block (user chosen or auto-assigned from a 8-color palette). Contains the collection's first screenshot thumbnail at 50% opacity, overlaid.
- Bottom 40%: white. Collection name in Syne 700 15sp + screenshot count in DM Sans 400 12sp `kColorInkMuted`.
- Pressed state: scale 0.97x, `kShadowSubtle`
- Long press: shows a context menu (rename, duplicate, delete, export all)

**Template Card**
- Width: fills column (2-column grid)  
- Aspect ratio: 9:16 (portrait screenshot ratio)
- Border radius: radius12
- No explicit border — shadow provides containment
- Shadow: `kShadowCard`
- Top-right badge: "PRO" tag (if applicable) in DM Sans 600 10sp, `kColorAccent` background, `kColorAccentOn` text, radius4
- On hover/focus: scale 1.02x, shadow → `kShadowRaised`
- Selected/In use: 2dp `kColorAccent` border, `kColorAccentTint` overlay at 15% opacity on top of thumbnail

**Screenshot Card (within a Collection)**
- Width: fills column (2-column grid, same as Template Card)
- Aspect ratio: 9:16
- Border radius: radius12
- Shadow: `kShadowCard`
- Bottom bar (overlaid gradient from transparent → 50% black over bottom 25%): shows screenshot name in DM Sans 500 12sp white text
- Tap: opens editor

**Info Card (generic content card)**
- Padding: space16
- Border radius: radius12
- Shadow: `kShadowCard`
- Background: `kColorSurface`

### 10.4 Badges & Tags

**Count Badge (on nav items)**
- Diameter: 18dp (circle) or auto-width pill if 2+ digits
- Background: `kColorDestructive`
- Text: DM Sans 600 10sp white
- No border
- Position: top-right of icon, offset by -4dp,-4dp

**Category Tag / Filter Chip**
- Height: 32dp
- Padding: space8 horizontal, space4 vertical
- Border radius: radiusFull
- Default: border 1dp `kColorBorderDefault`, text DM Sans 500 13sp `kColorInkSecondary`, background transparent
- Selected: background `kColorAccentTint`, border 1dp `kColorAccent`, text `kColorAccent`
- A single horizontal scroll row, not wrapping

**PRO Badge**
- Height: 18dp, auto-width
- Padding: 4dp horizontal
- Background: `kColorAccent`
- Text: DM Sans 600 10sp `kColorAccentOn`
- Border radius: radius4
- Letter spacing: 0.5

**Status Tag (success / warning / error)**
- Same shape as Category Tag
- Background: respective tint color
- Text: respective color (Accent, Warning, Destructive)
- No border

### 10.5 Bottom Navigation Bar

- Height: 64dp + system nav inset
- Background: `kColorSurface`
- Top border: 1dp `kColorBorderSubtle` (not a shadow — a deliberate hairline)
- 4 items: Home, Templates, Collections, Profile

Per item:
- Icon: 24dp, `kColorInkMuted` when inactive
- Label: DM Sans 500 11sp, `kColorInkMuted` when inactive
- Active: Icon 24dp `kColorAccent`, label `kColorAccent` DM Sans 600 11sp
- Active indicator: a 4dp × 28dp green rounded pill (`radius2`) slides horizontally above the active icon — not under it, above. This is the signature nav indicator.
- Tap animation: icon bounces (scale 1.0 → 1.2 → 1.0) over `durationFast` with `kSpring`.

### 10.6 App Bars

**Standard App Bar**
- Height: 56dp
- Background: `kColorBackground` (no separation — bar bleeds into page background)
- Leading: back arrow (IconButton) or hamburger, `kColorInkPrimary`
- Title: Syne 700 19sp `kColorInkPrimary`, left-aligned (not centered — centered titles read as generic)
- Trailing: 1–2 IconButtons max
- No elevation, no shadow — the page scroll itself creates the visual separation

**Editor App Bar** (special case — see Editor screen)
- Height: 52dp
- Background: `kColorSurface`
- Bottom border: 1dp `kColorBorderSubtle`
- This bar IS visually separated from the canvas area — it's a distinct panel.

### 10.7 Bottom Sheets

**Standard Bottom Sheet**
- Background: `kColorSurface`
- Border radius: radius16 top-left and top-right only (0 on bottom)
- Handle: 36dp × 4dp, `kColorBorderDefault`, centered, 12dp from top
- Top padding: 20dp from top of sheet
- Max height: 85% of screen

**Full-screen Bottom Sheet** (Template Preview, Export)
- Covers 100% height
- Border radius: 0 (full bleed)
- Has its own app bar

### 10.8 Dialogs

- Border radius: radius16
- Background: `kColorSurface`
- Shadow: `kShadowFloat`
- Padding: space24
- Title: Syne 700 18sp `kColorInkPrimary`
- Body: DM Sans 400 14sp `kColorInkSecondary`
- Button row: right-aligned, secondary button first, primary button second
- Barrier: `kColorInkPrimary` at 30% opacity (not pure black — matches the palette)

### 10.9 Empty States

Structure (top to bottom, centered):
1. Illustration (see Asset Requirements §14) — max 200dp wide
2. space24 gap
3. Headline: Syne 700 20sp `kColorInkPrimary`, centered
4. space8 gap
5. Description: DM Sans 400 14sp `kColorInkMuted`, centered, max 260dp wide
6. space32 gap
7. Primary Button (if an action is available)

Copy examples:
- No collections yet → "Your first collection" / "Collections keep your screenshots organized. Start one and your work lives here."
- No templates downloaded → "No templates yet" / "Browse the library and download templates to use them offline."

### 10.10 Loading States

**Skeleton Loader:**
- Uses `kColorSurfaceMuted` as base, `kColorSurfaceRaised` as shimmer highlight
- Shimmer animation: diagonal sweep, 1200ms loop, `kEaseInOut`
- Skeleton shapes mirror the exact card dimensions they'll replace

**Button Loading State:**
- Replace label with a 16dp circular progress indicator (white, strokeWidth 2dp)
- Button stays same width, disabled during load

**Full-screen Load (initial app launch, template download):**
- Show app logo centered on `kColorBackground`
- Below logo: 200dp-wide progress bar (not a spinner), green fill
- No text during loading — the logo says enough

---

## 11. Screen Specifications

---

### 11.1 Splash Screen

**Duration:** 1.5s, then auto-navigate  
**Background:** `kColorBackground` (#F5F7F5)

**Layout (centered):**
- App icon: 80dp × 80dp, border radius radius16. Green background with white mark.
- App name: "FrameKit" in Syne 800 28sp `kColorInkPrimary`, centered, 16dp below icon
- No tagline here. Restraint.

**Animation:**
- Icon fades in (0 → 1 opacity) over 400ms
- App name fades + translates up (8dp → 0) 100ms after icon, over 350ms
- At 1.2s: both fade out together over 300ms → navigate

---

### 11.2 Onboarding (3 screens)

Onboarding appears only on first launch. Skippable via "Skip" text button (Ghost style, top-right).

**Layout per screen:**
- Top 55%: Full-bleed illustration (no padding on sides)
- Bottom 45%: `kColorSurface`, border radius radius20 top corners, content inside
- Horizontal pager with dots indicator (3 dots, active = `kColorAccent` filled 8dp, inactive = `kColorBorderDefault` 6dp)
- "Next" Primary Button, full width with space16 horizontal margin
- Last screen: button becomes "Get started"

**Content:**

**Screen 1 — "Premium templates, ready to go"**
- Illustration: 3 overlapping phone mockup cards (slightly rotated, stacked) with lush template thumbnails
- Headline: Syne 800 26sp
- Body: DM Sans 400 14sp `kColorInkSecondary`, max 2 lines

**Screen 2 — "One collection, infinite screenshots"**
- Illustration: A folder icon exploding into a grid of screenshots
- Headline: Syne 800 26sp
- Body: DM Sans 400 14sp `kColorInkSecondary`

**Screen 3 — "Works offline. Exports perfectly."**
- Illustration: Phone with green download badge → export arrow
- Headline: Syne 800 26sp
- Body: DM Sans 400 14sp `kColorInkSecondary`

---

### 11.3 Auth Screens

**Sign In & Sign Up share a layout. They are NOT separate screens — they use a single screen with a toggle.**

**Background:** `kColorBackground`

**Layout (top to bottom):**
- Back arrow if navigated from onboarding (top-left, 52dp from top)
- 48dp from top (or 24dp from back arrow): App wordmark "FrameKit" in Syne 700 22sp, left-aligned with space20 margin
- 40dp gap
- Toggle row: Two pill tabs — "Sign in" and "Create account". The active tab has `kColorAccentTint` background with `kColorAccent` text (Syne 700 14sp). Inactive: `kColorInkMuted` DM Sans 500 14sp. Container: 1dp `kColorBorderDefault` border, radiusFull.
- 32dp gap
- **Sign In fields:**
  - Email input (space12 gap between fields)
  - Password input (with show/hide icon trailing)
  - "Forgot password?" Ghost button, right-aligned, space4 below password field
- **Sign Up fields (when toggled):**
  - Full name input
  - Email input
  - Password input
  - Confirm password input
- 28dp gap
- Primary Button: "Sign in" / "Create account" (full width, space16 margin)
- 24dp gap
- Divider with "or" centered (hairline, DM Sans 400 13sp `kColorInkMuted`)
- 24dp gap
- Google sign-in Secondary Button: Google logo SVG (18dp) + "Continue with Google" DM Sans 600 14sp, full width
- 16dp gap
- Apple sign-in Secondary Button (iOS only): Apple icon + "Continue with Apple"

**Error states:** Under the relevant field, inline in DM Sans 400 12sp `kColorDestructive`. Never in a banner.

---

### 11.4 Home / Dashboard Screen

**App Bar:**
- Title: "FrameKit" in Syne 700 19sp (not a generic "Home")
- Trailing: Profile avatar (32dp circle, user photo or initials) → taps to Profile screen

**Layout (scrollable):**

**Section 1 — Greeting row** (space24 from app bar)
- "Good morning, Adeel" in DM Sans 500 16sp `kColorInkSecondary` (name from user profile)
- Sub-label: "3 collections · 12 screenshots" in DM Sans 400 13sp `kColorInkMuted`

**Section 2 — Continue working** (space32 from greeting)
- Section header: "Continue working" in Syne 700 16sp `kColorInkPrimary`
- Horizontal scroll row of screenshot cards (the last 3 edited): 140dp wide × auto height (9:16 ratio), shadow `kShadowCard`, border radius radius12
- If none: a dashed border card with "+ Start a collection" centered

**Section 3 — Featured Templates** (space32 from previous)
- Section header: "Featured templates" in Syne 700 16sp + "View all" Ghost button right-aligned
- Horizontal scroll row of Template Cards: 160dp wide, 9:16 ratio, border radius radius12, shadow `kShadowCard`
- Category chips above the row (horizontal scroll, no wrap): "All", "Minimal", "Bold", "Dark", "Colorful", "3D"

**Section 4 — Your Collections** (space32 from previous)
- Section header: "Collections" in Syne 700 16sp + "View all" Ghost button
- 2-column grid (as per Collection Card spec) showing the latest 4 collections
- Below grid: Primary Button "New collection" — space16 horizontal margin, full width

**Bottom padding:** space64 above nav bar (to ensure nothing is hidden)

---

### 11.5 Collections Screen

**App Bar:**
- Title: "Collections" in Syne 700 19sp
- Trailing: "+" Icon Button → triggers new collection dialog

**New Collection Dialog (triggered by "+"):**
- Title: "New collection" (Syne 700 18sp)
- Body: Single input — "Collection name" placeholder
- Color picker row: 8 color swatches (16dp circles, 1dp `kColorBorderDefault` border), selected = 2dp `kColorAccent` outer ring
- Buttons: Cancel (Ghost) + Create (Primary)

**Layout:**
- Search bar (pill style) below app bar, space16 margin, space12 below app bar
- Filter chips row: "All", "Recent", "Alphabetical"
- 2-column grid of Collection Cards, space16 outer margin, 12dp gutter
- Empty state (first launch): centered in remaining space

**Collection Card Long-press Menu (ContextMenu / PopupMenu):**
- Items: "Open", "Rename", "Duplicate", "Export all", [divider], "Delete"
- Delete item: `kColorDestructive` text + trash icon
- Border radius: radius12
- Shadow: `kShadowFloat`

---

### 11.6 Collection Detail Screen

**App Bar:**
- Title: Collection name in Syne 700 19sp
- Subtitle: "4 screenshots" in DM Sans 400 12sp `kColorInkMuted`, directly below title (stacked title variant)
- Trailing: Three-dots menu (rename, export all, delete collection)

**FAB:**
- "+ Add screenshot" extended FAB (bottom-right corner, space16 from edges)
- Tapping navigates to Template Browser

**Layout:**
- 2-column grid of Screenshot Cards
- Cards are the 9:16 ratio thumbnails with bottom gradient + name label
- Each card: tap → editor, long press → context menu (Rename, Duplicate, Delete)

**Ordering:** Most recently edited first. Drag-to-reorder is supported — on long-press-and-hold (>400ms) the card slightly lifts (scale 1.04x, `kShadowFloat`) and a drag handle becomes visible.

---

### 11.7 Template Browser Screen

This is a full-screen browsing experience, not a modal.

**App Bar:**
- Title: "Templates" in Syne 700 19sp
- Trailing: Sort icon (sliders-horizontal)

**Layout:**

**Search bar:** Full-width pill, 16dp margin, space12 below app bar

**Category tabs (horizontal scroll, below search):**
- "All", "Minimal", "Bold", "Gradient", "Dark", "3D Mockup", "Illustration", "Typography", "Web / Desktop"
- Tab style: same as Category Tag chips
- Active tab scrolls to center automatically

**Template grid:**
- 2-column grid
- Card dimensions: fills column, 9:16 ratio
- Template Card spec as per §10.3
- Lazy-loaded with skeleton placeholders during network fetch
- Downloaded templates show a small green checkmark badge (bottom-left of card)
- Premium-only templates show a "PRO" badge and a subtle lock overlay with 50% opacity blur-filter on the preview

**Template state logic:**
- Not downloaded: shows "Download" icon-button overlaid bottom-right (transparent background, `kShadowSubtle`)
- Downloading: progress ring replaces the download icon (green stroke, 18dp)
- Downloaded: checkmark, no overlay
- Premium (not subscribed): lock badge, tapping opens upgrade dialog

**Filter bottom sheet (triggered by sort icon):**
- "Filter templates" header in Syne 700 18sp
- Sections: Device type (Phone, Tablet, Desktop/Web), Store (App Store, Play Store, Both), Style, Color tone
- Each section uses multi-select chips
- "Apply filters" Primary Button (full width) at bottom of sheet

---

### 11.8 Template Preview Screen

Navigated to by tapping a Template Card.

**Layout:**
- Top 60%: Full-bleed template preview (the template's hero screenshot, if it has one). No border radius — full bleed.
- Scrollable bottom panel rising from 60% mark:
  - Handle (spec per §10.7)
  - Template name: Syne 700 20sp
  - Category tag + device type tag (row)
  - DM Sans 400 14sp description, 2 lines max then "Read more" expand
  - space20 gap
  - "Included elements" section: horizontal scroll of element type chips (icons + label) — showing what's customizable in this template
  - space24 gap
  - Preview thumbnails row: small 60dp-wide cards showing all screenshot slots in this template
  - space32 gap
  - If downloaded: "Use template" Primary Button + "Re-download" Ghost button
  - If not downloaded: "Download & use" Primary Button (shows download size in `mono` 11sp below button e.g., "4.2 MB")
  - If premium + no subscription: "Unlock with PRO" Primary Button (same green, not a different color — PRO is a feature, not a paywall punishment)

**App bar (transparent, floating over the illustration):**
- Back arrow: white with a drop shadow (so it's visible over any illustration color)
- Trailing: Share icon (white)

---

### 11.9 Editor Canvas Screen

This is the most important screen. It must feel like a professional tool, not a consumer app.

**Overall Structure:**
```
┌─────────────────────────────────┐
│  Editor App Bar (52dp)          │
├─────────────────────────────────┤
│                                 │
│                                 │
│    Canvas Area (dominant)       │
│    (gestures: pan, pinch-zoom)  │
│                                 │
│                                 │
├─────────────────────────────────┤
│  Tool Bar (56dp)                │
├─────────────────────────────────┤
│  Properties Panel (collapsible) │
│  (slides up from bottom)        │
└─────────────────────────────────┘
```

**Editor App Bar (52dp):**
- Background: `kColorSurface`
- Bottom border: 1dp `kColorBorderSubtle`
- Left: Back arrow (exits, confirms save)
- Center: Collection name in DM Sans 500 14sp `kColorInkSecondary` + "/" + Screenshot name in DM Sans 600 14sp `kColorInkPrimary`. Tapping the name opens a rename input inline.
- Right side (left to right): Undo (rotate-ccw icon), Redo (rotate-cw icon), divider (1dp × 18dp `kColorBorderDefault`), "Export" Primary Button (compact: 36dp height, DM Sans 600 13sp)

**Canvas Area:**
- Background: `kColorBackground` (the app's ambient background shows around the canvas)
- The actual canvas (screenshot) floats centered with `kShadowCard`
- Canvas itself: `kColorSurface` default background (or whatever template sets)
- Canvas has 0 border radius
- When panning: canvas clips to bounds of the view
- Pinch-zoom: minimum 25%, maximum 400%
- Zoom level shown in a floating chip (bottom-left of canvas area): DM Sans 500 12sp `kColorInkPrimary`, `kColorSurface` background, `kShadowSubtle`, radius6. This chip auto-hides after 1.5s of no zoom gesture.
- Selected element: shows blue handles (8dp circles) at corners + midpoints, plus a rotation handle above. Use `kColorAccent` for handles.

**Tool Bar (56dp, above system nav):**
- Background: `kColorSurface`
- Top border: 1dp `kColorBorderSubtle`
- Horizontally scrollable row of tool buttons (left to right):
  - **Elements** (shapes) → opens Elements Panel
  - **Text** (type icon) → adds a text element
  - **Image** (image-plus) → opens image picker
  - **Background** (palette) → opens Background Panel
  - **Device frame** (smartphone) → swaps the device mockup
  - **Stickers** (smile) → opens Sticker Panel
  - divider
  - **Layers** (layers icon) → opens Layers Panel
  - **Align** (align-center-horizontal) → opens Alignment Panel
- Each tool: 52dp wide × 56dp tall. Icon 22dp, label 10sp DM Sans 500 `kColorInkMuted` below. Active/selected tool: icon + label `kColorAccent`, no background.

**Properties Panel (collapsible bottom sheet):**
Appears when an element is selected. Slides up without covering the full canvas (canvas compresses upward).

Properties panels per element type:

*Text element:*
- Font picker (horizontal scroll: DM Sans, Syne, Space Mono, + "More" chip)
- Font size (number input + +/- buttons)
- Color picker (row of swatches)
- Bold / Italic / Underline toggles
- Text alignment (left/center/right/justify row)
- Opacity slider

*Image element:*
- Replace image button
- Fit mode (fill / fit / stretch)
- Border radius slider
- Opacity slider
- Shadow toggle

*Shape element:*
- Fill color picker
- Stroke color picker + stroke width slider
- Border radius slider
- Opacity slider

*Device Frame element:*
- Frame selector (horizontal scroll: iPhone 16 Pro, Pixel 9, Samsung S24, iPad, MacBook, Browser Chrome, etc.)
- Frame color (Silver, Space Black, Gold, etc.)
- Tapping inside the frame opens an image picker to set the app screenshot inside the frame

**Background Panel:**
- Opened via Background tool
- Tabs: "Color", "Gradient", "Image", "Preset"
- Color tab: Full color picker (HEX input + hue/saturation wheel)
- Gradient tab: Linear/Radial toggle, up to 4 color stops, angle input
- Image tab: Upload from device + free-to-use library
- Preset tab: The 12 canvas preset backgrounds from §3.3

**Element Selection State:**
- Selected element shows:
  - Corner + midpoint handles: 8dp white circles with 1.5dp `kColorAccent` stroke
  - Rotation handle: 24dp above top-center with a rotation icon
  - Delete button: trash-2 icon in a 32dp circle (`kColorDestructive` background, white icon), floats near top-right of element
  - Bring forward / Send back: two small icon buttons floating to the left of the element

---

### 11.10 Elements Panel Screen

Triggered from the "Elements" tool button. Slides up as a bottom sheet covering ~75% of screen.

**Header:**
- Search bar (pill, full width)
- Horizontal category chip row: "All", "Shapes", "Lines", "Arrows", "Badges", "Banners", "Stars & Ratings", "Devices", "Social", "Text styles"

**Grid layout:**
- 3-column grid (per §5.4)
- Each cell: white square card (radius8), element preview centered (40dp), tap to add to canvas
- Elements snap to center of canvas on add

**Premium elements:**
- Semi-transparent overlay with lock icon
- Tapping shows upgrade prompt

---

### 11.11 Export Screen

**Full-screen bottom sheet, triggered by "Export" button in Editor App Bar.**

**Header:**
- Title: "Export screenshot" in Syne 700 20sp
- Subtitle: Collection + screenshot name in DM Sans 400 14sp `kColorInkSecondary`

**Preview:**
- Centered thumbnail of the current screenshot (150dp wide, 9:16 ratio, radius12, `kShadowCard`)

**Options:**

*Export format:*
- Horizontal row of chips: PNG (default), JPG, WEBP
- PNG recommended badge below: DM Sans 400 11sp `kColorInkMuted` "PNG preserves transparency and quality"

*Resolution / Size preset:*
- Tab selector: "App Store iOS", "Google Play", "Web", "Custom"
- Below the tab: a scrollable list of size variants for the selected store:

  - App Store iOS: 6.7" (1290×2796), 6.5" (1242×2688), 5.5" (1242×2208), iPad Pro (2048×2732)
  - Google Play: Phone (1080×1920), 7" Tablet (1200×1920), 10" Tablet (1600×1200)
  - Web: 1920×1080 (16:9), 1440×900, 1280×800
  - Custom: width × height inputs

- Each size option: radio-style selection with the pixel dimensions in `mono` 12sp and the device label in DM Sans 500 13sp. Multi-select is allowed (generates all selected sizes in a zip).

*Quality (JPG/WEBP only):*
- Slider: 60–100%, default 95%
- Label: "High quality · ~2.4 MB" updates live as quality changes

**Export button:**
- Primary, full-width, 52dp height
- Label: "Export 3 sizes" (number updates based on selection)
- Pressing shows progress: the button collapses to a progress bar, then expands back with a checkmark + "Saved to Downloads" label

**Batch export note:**
DM Sans 400 12sp `kColorInkMuted` at bottom: "All screenshots in this collection can be exported at once from the collection menu."

---

### 11.12 Profile & Settings Screen

**App Bar:**
- Title: "Account" in Syne 700 19sp

**Layout:**

*Profile card (top):*
- Surface card, space16 padding, radius12
- User avatar (56dp circle) on left
- Name: Syne 700 17sp, email: DM Sans 400 13sp `kColorInkMuted`
- "Edit profile" Ghost button trailing

*Subscription section:*
- PRO badge or "Free plan" label
- If free: "Upgrade to PRO" Primary Button with brief feature list (3 bullet points, DM Sans 400 13sp)
- If PRO: "Manage subscription" Ghost button

*Settings list:*
- Sections use Syne 700 13sp uppercase headers with `kColorInkMuted`
- List items: DM Sans 500 14sp `kColorInkPrimary`, leading icon `kColorInkMuted`, trailing chevron or toggle

Groups:
1. **Preferences** — Default export format, Default canvas size, Auto-save (toggle)
2. **Storage** — "Downloaded templates · 48 MB", "Clear cache" Ghost (destructive) button, "Manage offline content"
3. **Account** — Change password, Linked accounts
4. **Support** — Contact support, Rate the app, Privacy policy, Terms of service
5. **Danger zone** (section labeled with `kColorDestructive` text) — "Delete account"

---

## 12. Illustrations & Asset Requirements

All illustrations are custom SVG. No stock. No icon-only placeholders.

### 12.1 Illustration Style

- **Flat + geometric.** No gradients within illustration elements. No shadows within illustrations.
- **2-color scheme per illustration:** `kColorAccent` (#1A6B4A) + `kColorInkPrimary` (#141A14) + white.
- Illustrations feel like a premium design studio's icon set — sharp, geometric, intentional.
- No human faces or characters (reduces cultural ambiguity, avoids the "stock illustration" look).

### 12.2 Required Illustrations

| Name                   | Used on                          | Description                                           |
|------------------------|----------------------------------|-------------------------------------------------------|
| `empty_collections`    | Collections screen empty state   | Folder with plus icon, minimal lines                 |
| `empty_templates`      | Template Browser filter = 0 results | Grid of blank cards with a magnifying glass         |
| `empty_screenshots`    | Collection Detail empty state    | Phone with arrow pointing into it                    |
| `onboarding_1`         | Onboarding screen 1              | 3 stacked device mockup cards                        |
| `onboarding_2`         | Onboarding screen 2              | Folder exploding into a grid                         |
| `onboarding_3`         | Onboarding screen 3              | Download arrow + export arrow                        |
| `upload_placeholder`   | Inside Device Frame element      | App icon + "Add your screenshot" text                |
| `export_success`       | Export screen success state      | Checkmark inside a rounded square                    |

### 12.3 App Icon

- 1024×1024 master
- Background: `kColorAccent` (#1A6B4A) — solid, no gradient
- Mark: White geometric "F" that also reads as a camera aperture / frame corner. The mark occupies 55% of the icon width, centered.
- Border radius: follows platform conventions (iOS: no radius — applied by OS; Android: radius as per Adaptive Icon spec)
- A `foreground_layer.png` + `background_layer.png` for Android Adaptive Icons

---

## 13. Flutter Implementation Notes

### 13.1 Package Dependencies

```yaml
dependencies:
  google_fonts: ^6.2.1          # Syne, DM Sans, Syne Mono
  lucide_flutter: ^0.257.0      # Icon set
  flutter_riverpod: ^2.5.1      # State management
  go_router: ^13.2.0            # Navigation
  firebase_core: ^2.27.0
  firebase_auth: ^4.19.0
  cloud_firestore: ^4.15.0
  firebase_storage: ^11.7.0
  cached_network_image: ^3.3.1  # Template thumbnail caching
  path_provider: ^2.1.3         # Offline storage paths
  hive_flutter: ^1.1.0          # Local offline data
  image: ^4.1.7                 # High-res image export
  screenshot: ^2.3.0            # Canvas capture
  share_plus: ^9.0.0            # Export sharing
  file_saver: ^0.2.14           # Save to device
  flutter_cache_manager: ^3.3.1 # Template download caching
```

### 13.2 Theme Setup

```dart
ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  fontFamily: GoogleFonts.dmSans().fontFamily,
  scaffoldBackgroundColor: kColorBackground,
  colorScheme: ColorScheme.light(
    primary: kColorAccent,
    onPrimary: kColorAccentOn,
    surface: kColorSurface,
    onSurface: kColorInkPrimary,
    outline: kColorBorderDefault,
    error: kColorDestructive,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kColorBackground,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: kColorInkPrimary),
    titleTextStyle: GoogleFonts.syne(
      fontSize: 19, fontWeight: FontWeight.w700,
      color: kColorInkPrimary,
    ),
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kColorAccent,
      foregroundColor: kColorAccentOn,
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kColorBorderDefault, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kColorBorderDefault, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kColorAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: GoogleFonts.dmSans(fontSize: 15, color: kColorInkDisabled),
  ),
);
```

### 13.3 High-Quality Export Pipeline

**This is a first-class concern — not an afterthought.**

```dart
// Use a RepaintBoundary wrapping the canvas widget with a GlobalKey.
// Capture at a pixel ratio matching the target export resolution.

Future<Uint8List> exportCanvas({
  required GlobalKey canvasKey,
  required double targetWidthPx,
  required double targetHeightPx,
}) async {
  final RenderRepaintBoundary boundary =
      canvasKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // The pixelRatio here is what determines output quality.
  // If the canvas is displayed at 390dp wide and we want 1290px output:
  final double pixelRatio = targetWidthPx / boundary.size.width;

  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}
```

**Rules for export:**
- PNG export: always use `ui.ImageByteFormat.png` — lossless.
- JPG export: compress the PNG output using the `image` package's JPEG encoder with the user's quality setting (default 95).
- Never downsample. Always render at the target pixel dimensions or larger.
- The canvas widget's content should use `@2x` or `@3x` asset variants for device frames and decorative elements.

### 13.4 Offline Architecture

**Firebase → Local (Hive) sync strategy:**

1. Template metadata (name, category, thumbnail URL, element manifest) is stored in Firestore.
2. When a user downloads a template, the app:
   - Downloads all template assets (SVG/PNG elements, font subsets if template-specific) to `getApplicationDocumentsDirectory()/templates/{templateId}/`
   - Saves the template manifest as a JSON file in the same directory
   - Marks the template as `downloaded: true` in a Hive box
3. On editor open: all assets are loaded from local disk. No network request.
4. On template update (Firebase version bump): a sync badge on the template card indicates an update is available. User initiates re-download.

**Hive boxes:**
```
templates_meta     → Map<templateId, TemplateMetaModel>  
collections        → Map<collectionId, CollectionModel>
screenshots        → Map<screenshotId, ScreenshotModel>
user_prefs         → UserPreferencesModel
```

### 13.5 Canvas State Management

- Use **Riverpod** for all editor state.
- `EditorNotifier` holds: list of `CanvasElement` objects, selected element ID, canvas background, zoom level, undo stack.
- Undo/redo: a `List<EditorState>` stack, max 50 items. Push a snapshot on every element mutation.
- Autosave: debounce 2 seconds after last edit → serialize canvas state to Hive.
- Do NOT use setState inside the editor canvas widget. All state flows through Riverpod.

---

## 14. Accessibility

- **Minimum contrast ratio:** 4.5:1 for body text, 3:1 for large text (≥18sp). The defined palette exceeds this everywhere.
- **Touch targets:** Minimum 44dp × 44dp for all interactive elements. Icon buttons use 40dp visual size inside a 48dp touch target using `Semantics` + `GestureDetector` sizing.
- **Semantic labels:** All icon-only buttons have a `Semantics(label: '...')` wrapper.
- **Reduced motion:** Check `MediaQuery.of(context).disableAnimations`. If true, replace all animations with instant state changes.
- **Dynamic text size:** All `sp` values respond to system font scale. Test at 130% and 150% scale. The editor canvas area ignores font scale (canvas content is user-controlled, not system UI).
- **Screen reader (TalkBack/VoiceOver):** The canvas area should be announced as "Screenshot editing canvas. Double-tap to select elements." Elements are announced by their type and position.
- **Color-blind safe:** The accent green (#1A6B4A) is distinguishable from the destructive red (#C0392B) in protanopia simulation. Verified via a color-blind simulator before finalizing.

---

## 15. Design Don'ts

These are explicit prohibitions to maintain the premium standard:

1. **Never use a gradient in any UI chrome element.** (Gradients live only inside the canvas, created by users.)
2. **Never use `Poppins`, `Inter`, or `Plus Jakarta Sans`.** These read as default/AI.
3. **Never center-align the App Bar title.** Left-aligned titles signal confidence.
4. **Never use a bottom navigation bar with more than 4 items.**
5. **Never use rounded corners on the editor canvas itself.** It is a precision work surface.
6. **Never show a loading spinner for anything that can use a skeleton loader instead.**
7. **Never use pure black (`#000000`) or pure white (`#FFFFFF`) for text or backgrounds at the page level.** Use the defined ink and background tokens.
8. **Never use more than two typefaces in a single screen.** Syne + DM Sans. Syne Mono only for data/specs.
9. **Never stack two shadows on the same element.**
10. **Never use a `SnackBar` for destructive action feedback.** Use a dialog that requires explicit confirmation.
11. **Never animate the canvas content as a navigation transition.** Only the UI chrome transitions.
12. **Never let export quality drop below the target pixel dimensions.** If the device cannot render at the required pixelRatio in a single pass, tile-render and stitch.

---

*End of DESIGN.md — v1.0*  
*For Kiro CLI implementation. All color values, font families, spacing values, and component specs are production-ready and derived from this document. No placeholder values.*
