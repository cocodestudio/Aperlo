---
name: aperlo-ui
description: >
  Design system skill for the Aperlo Flutter app. Produces beautiful, modern,
  animated Flutter UI that matches the established Aperlo aesthetic — inspired
  by the onboarding screen and editor screen. Use this skill whenever you need
  to build, redesign, or polish any screen or component in this project.
applies_to:
  - "**/*.dart"
---

# Aperlo UI / UX Design Skill

This skill defines the exact rules, patterns, and code blueprints used to build
every screen in the Aperlo app. Follow them precisely. Deviations will look
out-of-place next to the existing screens.

---

## 1. Design Philosophy

- **Studio Precision** — Every element earns its place. No noise, no padding
  wasted, no gratuitous decoration.
- **Alive, not busy** — Animation should feel natural, like physics, not like
  CSS transitions from 2012. Use staggered entry, parallax, and spring curves.
- **Data surfaces before chrome** — Content always wins. UI chrome (toolbars,
  nav) should dissolve into the background.
- **Tactile interactions** — Every tappable element must respond immediately to
  touch (scale, color shift, shadow). Zero-latency feedback.
- **Pill and soft geometry** — Prefer brFull (pill) for CTAs and badges,
  br12-br16 for cards, br20 for sheets. Never use harsh 90-degree corners on
  interactive elements.

---

## 2. Token Reference

Always import from lib/core/theme/. Never hardcode colors, radii, or spacing.

### Colors (AppColors)

| Token | Value | Use |
|-------|-------|-----|
| background | #F5F7F5 | ambient page bg |
| surface | #FFFFFF | cards, sheets, bars |
| surfaceMuted | dimmed surface | input bg, muted tiles |
| accent | #1A6B4A | primary actions |
| accentOn | white | text/icons on accent |
| accentTint | very light green | selected states, badge bg |
| accentHover | darker green | pressed accent |
| inkPrimary | #141A14 | headings |
| inkSecondary | #475247 | body text |
| inkMuted | #7D877D | hints, labels |
| inkDisabled | #B0B8B0 | disabled/placeholder |
| borderSubtle | hairline | dividers |
| borderDefault | normal | borders |
| borderStrong | emphasized | drag handles |
| destructive | red | delete actions |
| destructiveTint | light red | delete swipe bg |

### Typography (AppText)

```
AppText.display()                 // Syne, 32px — hero headlines
AppText.headline1()               // Syne, 24px — page titles
AppText.headline2()               // Syne, 20px — section titles
AppText.headline3()               // Syne, 16px — sub-section titles
AppText.labelLarge(color: ...)    // DM Sans 600, 15px — button labels
AppText.labelDefault(color: ...)  // DM Sans 500, 13px
AppText.labelSmall(color: ...)    // DM Sans 500, 11px — tags, badges
AppText.bodyLarge(color: ...)     // DM Sans 400, 16px
AppText.bodyDefault(color: ...)   // DM Sans 400, 14px
AppText.bodySmall(color: ...)     // DM Sans 400, 12px
AppText.mono(color: ...)          // Syne Mono — numbers, codes, hex
```

### Radii (AppRadius)

```
AppRadius.br6     // tags, small chips
AppRadius.br10    // inputs, small cards
AppRadius.br12    // cards
AppRadius.br16    // large cards, dialogs
AppRadius.br20    // bottom sheets (top corners)
AppRadius.brFull  // pills — buttons, badges
AppRadius.full    // 9999 — full circles
```

### Spacing (AppSpacing)
Use s8, s12, s16, s20, s24, s32, s40, s64.

---

## 3. Animation Patterns

### 3.1 Staggered Entry (Onboarding pattern)

Use AnimationController + Interval curves. Stagger each element by ~120ms.
Each element gets a fade + upward slide. Trigger on first frame and on state change.

```dart
_entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

final tagFade = CurvedAnimation(parent: _entryCtrl,
  curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
final tagSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
  .animate(CurvedAnimation(parent: _entryCtrl,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));

// Stagger intervals:
// tag:      0.00 - 0.40 fade, 0.00 - 0.50 slide
// headline: 0.12 - 0.55 fade, 0.12 - 0.60 slide
// body:     0.28 - 0.70 fade, 0.28 - 0.75 slide
// cta:      0.45 - 0.85 fade, 0.45 - 0.90 slide

// Trigger:
WidgetsBinding.instance.addPostFrameCallback((_) => _entryCtrl.forward());
// On page change: _entryCtrl.forward(from: 0);

// Wrap each element:
SlideTransition(
  position: tagSlide,
  child: FadeTransition(opacity: tagFade, child: myWidget),
)
```

### 3.2 Press Feedback (every interactive element)

```dart
bool _pressed = false;

GestureDetector(
  onTapDown:   (_) => setState(() => _pressed = true),
  onTapUp:     (_) => setState(() => _pressed = false),
  onTapCancel: () => setState(() => _pressed = false),
  onTap: widget.onTap,
  child: AnimatedScale(
    scale: _pressed ? 0.95 : 1.0,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _pressed ? AppColors.accentHover : AppColors.accent,
        borderRadius: AppRadius.brFull,
      ),
    ),
  ),
)
```

### 3.3 Floating / Idle Animation

For illustrations and decorative elements — gentle breathing effect.

```dart
_floatCtrl = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 4),
)..repeat(reverse: true);

// In build:
final dy = math.sin(_floatCtrl.value * math.pi) * 6.0; // 6px vertical
Transform.translate(offset: Offset(0, dy), child: card)
```

### 3.4 AnimatedSwitcher for content changes

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 280),
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  transitionBuilder: (child, anim) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
          .animate(anim),
      child: child,
    ),
  ),
  child: Text(currentText, key: ValueKey(currentText)),
)
```

### 3.5 AnimatedContainer for state transitions

Always prefer AnimatedContainer over instant Container for color/size changes.
Duration: 150-200ms. Curve: Curves.easeOut.

---

## 4. Layout Patterns

### 4.1 Bottom Sheet / Property Panel

Sheets must hug their content — never leave empty space below.

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: Offset(0, -4))],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,   // KEY: always min!
    children: [
      // Drag handle pill
      Center(child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: BorderRadius.circular(4),
        ),
      )),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    ],
  ),
)
```

### 4.2 Section Headers

```dart
Widget buildSection(String title, List<Widget> children) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title.toUpperCase(),
      style: AppText.labelSmall(color: AppColors.inkMuted)
        .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Divider(color: AppColors.borderSubtle, thickness: 1, height: 1),
    const SizedBox(height: 12),
    ...children,
    const SizedBox(height: 20),
  ]);
}
```

### 4.3 Pill Toggle Group

```dart
// Segmented container: surfaceMuted bg, white pill for active with subtle shadow.
// Do NOT use native SegmentedButton.
TogglePillGroup(
  options: const ['Option A', 'Option B', 'Option C'],
  selectedValue: _selected,
  onChanged: (v) => setState(() => _selected = v),
)
```

### 4.4 Tag / Category Chip

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.accentTint,
    borderRadius: BorderRadius.circular(AppRadius.r6),
  ),
  child: Text(
    tag.toUpperCase(),
    style: AppText.labelSmall(color: AppColors.accent)
      .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
  ),
)
```

### 4.5 Frosted / Glass Overlay Button

```dart
Container(
  width: 44, height: 44,
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.35),
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
  ),
  child: Icon(icon, color: Colors.white, size: 20),
)
```

### 4.6 Scrollable Preview Screen Layout

For screens where a large image must be fully visible (e.g., template preview):

```dart
CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
    // Image area — sized to content aspect ratio, not fixed % of screen
    SliverToBoxAdapter(
      child: SizedBox(
        height: (size.width * (16 / 9)).clamp(0.0, size.height * 0.72),
        child: Image(fit: BoxFit.contain), // ALWAYS contain, never cover
      ),
    ),
    // Info panel
    SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        ),
        // content...
      ),
    ),
  ],
)
```

---

## 5. Custom Component Blueprints

### 5.1 Modern Slider (PropertySlider)

Do NOT use Flutter native Slider. Key traits:
- 6px pill track, AppColors.borderSubtle background
- Gradient active fill: [AppColors.accentTint, AppColors.accent]
- 22px circular thumb: white fill, accent border, glow shadow on drag
- Value shown as animated pill badge: turns accent-colored while dragging
- GestureDetector with onPanStart/Update/End + onTapDown/Up for full coverage
- Thumb clamp: `(fraction * trackWidth - thumbR).clamp(0, trackWidth - thumbR * 2)`

### 5.2 Color Picker (PropertyColorPicker)

- 40px live color preview circle with matching glow shadow
- Custom hex input: surfaceMuted container, hash icon prefix, accent border + glow on focus
- 12 preset color swatches in Wrap, 32px circles, accent border + glow when selected

### 5.3 Action Tile (StyledActionTile)

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.surfaceMuted.withValues(alpha: 0.3),
    border: Border.all(color: AppColors.borderDefault),
    borderRadius: AppRadius.br10,
  ),
  child: Row(children: [
    Icon(icon, color: AppColors.accent),
    SizedBox(width: 12),
    Text(label, style: AppText.labelLarge()),
    Spacer(),
    Icon(LucideIcons.chevronRight, color: AppColors.inkMuted, size: 16),
  ]),
)
```

### 5.4 Numeric Stepper (StyledInputNumeric)

Minus button | value display | Plus button.
All 40px, AppRadius.br10, surfaceMuted buttons, bordered value container.

### 5.5 Primary Button (AppButton)

```dart
AppButton(label: 'Use template', onPressed: fn, isFullWidth: true)
```

- Radius: AppRadius.brFull (pill shape — always)
- Height: 48px default
- Variants: primary (accent fill), secondary (outlined), ghost (text), destructive

### 5.6 Visual Option Selector (MockupStyleSelector pattern)

For choosing between named variants (e.g., mockup styles, icon styles):
- Use a Wrap of GestureDetector cards, NOT a Dropdown
- Each card: small visual preview (skeleton/icon) + label underneath
- Selected state: accentTint bg + accent border + heavier label weight
- Animate with AnimatedContainer (150ms)

---

## 6. Illustration / CustomPainter Pattern

For decorative illustrations (onboarding, empty states, loading):

1. Create StatefulWidget with SingleTickerProviderStateMixin
2. Repeating AnimationController (reverse: true) for idle float
3. CustomPainter for actual drawing
4. Use Canvas APIs: drawRRect, drawCircle, drawPath, drawShadow
5. All colors from AppColors, all sizes from Size parameter (never hardcoded)
6. Accept a `progress` double (0.0-1.0) from page transitions for parallax

```dart
class _MyIllustrationState extends State<_MyIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;

  @override void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override void dispose() { _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) => CustomPaint(
        painter: _MyPainter(float: _floatCtrl.value, progress: widget.progress),
        size: Size.infinite,
      ),
    );
  }
}
```

---

## 7. Do's and Don'ts

### Do
- Use AnimatedContainer, AnimatedScale, SlideTransition, FadeTransition
- Use GestureDetector for custom tap regions (not InkWell / ElevatedButton)
- Wrap every bottom sheet with mainAxisSize: MainAxisSize.min
- Give every section a buildSection(title, children) header
- Use ValueKey on AnimatedSwitcher children
- Use BouncingScrollPhysics on all scroll views
- Use AppText.mono() for numeric values (slider values, hex codes)
- Show values as animated pill badges that react to interaction state
- Use BoxFit.contain for portrait thumbnails
- Run flutter analyze --no-fatal-infos before handing off

### Don't
- Never use native Slider, SegmentedButton, DropdownButton as-is
- Never hardcode colors or font sizes
- Never use StatefulWidget for global state (use Riverpod)
- Never leave empty space below content in a bottom sheet
- Never use BoxFit.cover for portrait-aspect content
- Never animate persistent chrome (header, app name) on content changes
- Never use gradients in UI chrome (only on canvas/illustration elements)
- Never use ElevatedButton or TextButton as primary CTAs

---

## 8. Screen Structure Template

```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Column(children: [
      // App bar (56px, surface bg, subtle bottom border)
      Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
        child: Row(children: [/* back, title, actions */]),
      ),

      // Main scrollable content
      Expanded(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              sliver: SliverList(delegate: SliverChildListDelegate([...])),
            ),
          ],
        ),
      ),

      // Bottom action bar (60px, surface bg, subtle top border)
      Container(
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(children: [/* tool buttons */]),
      ),
    ]),
  ),
)
```

---

## 9. Workflow for New Screens

1. **Read** lib/core/theme/ — understand all tokens before writing a line.
2. **Sketch** the layout in sections: header / body / bottom bar / sheets.
3. **Build chrome first** — app bar, bottom bar, safe areas.
4. **Add content** — use buildSection(), PropertySheetLayout, tokens everywhere.
5. **Add animation last** — entry stagger, press feedback, idle float.
6. **Run** flutter analyze --no-fatal-infos — fix all errors and warnings.

---

## 10. Key Reference Files

| File | Purpose |
|------|---------|
| lib/core/theme/app_colors.dart | All color tokens |
| lib/core/theme/app_text_styles.dart | All typography |
| lib/core/theme/app_radius.dart | All border radii |
| lib/core/theme/app_spacing.dart | All spacing constants |
| lib/core/theme/app_motion.dart | Animation durations/curves |
| lib/core/theme/app_shadows.dart | Box shadow presets |
| lib/widgets/app_button.dart | AppButton, AppIconButton |
| lib/screens/onboarding/onboarding_screen.dart | Reference: stagger, parallax, CustomPainter |
| lib/screens/editor/editor_screen.dart | Reference: sheets, toolbar, property panels |
| lib/screens/editor/property_sheets.dart | All property widget blueprints |
