import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/storage_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.step,
    required this.tag,
    required this.headline,
    required this.body,
    required this.illustration,
  });
  final String step;
  final String tag;
  final String headline;
  final String body;
  final Widget Function(double progress) illustration;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _ctrl = PageController(viewportFraction: 1.0);
  double _pageOffset = 0.0;
  int _page = 0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;

  static final _pages = <_PageData>[
    _PageData(
      step: '01',
      tag: 'Templates',
      headline: 'Studio-quality\ntemplates,\nready to use.',
      body: 'Choose from a growing library of professionally crafted layouts. Each template is designed pixel-by-pixel for app store specs.',
      illustration: (t) => _IllustrationTemplates(progress: t),
    ),
    _PageData(
      step: '02',
      tag: 'Canvas Editor',
      headline: 'Every detail\nin your\ncontrol.',
      body: 'Layer your screenshot, rewrite the copy, adjust every color and position. The canvas gives you full creative control — no code, no exports.',
      illustration: (t) => _IllustrationEditor(progress: t),
    ),
    _PageData(
      step: '03',
      tag: 'Export',
      headline: 'The right size,\nevery time.',
      body: 'Export directly at App Store and Google Play resolutions. Full pixel-perfect quality. Straight to your camera roll in one tap.',
      illustration: (t) => _IllustrationExport(progress: t),
    ),
    _PageData(
      step: '04',
      tag: 'Collections',
      headline: 'Organized\nfor how you\nactually work.',
      body: 'Group screenshots by app, platform, or campaign into collections. Find what you need instantly — even when you have dozens.',
      illustration: (t) => _IllustrationCollections(progress: t),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _setupAnimations();
    _ctrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _entryCtrl.forward());
  }

  void _setupAnimations() {
    _tagFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _headlineFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOut),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.12, 0.6, curve: Curves.easeOutCubic),
    ));

    _bodyFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.28, 0.7, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.28, 0.75, curve: Curves.easeOutCubic),
    ));

    _ctaFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _ctaSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    ));
  }

  void _onScroll() {
    if (_ctrl.page != null) {
      setState(() => _pageOffset = _ctrl.page!);
    }
  }

  Future<void> _finishOnboarding() async {
    await StorageUtil.setHasSeenOnboarding(true);
    if (!mounted) return;
    
    final granted = await StorageUtil.isPermissionGranted();
    if (!mounted) return;
    
    if (granted) {
      context.go('/home');
    } else {
      context.go('/permission');
    }
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Parallax progress for current transition
    final int currentPage = _pageOffset.floor().clamp(0, _pages.length - 1);
    final double localT = (_pageOffset - currentPage).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Illustration layer (full screen) ────────────────────────────
          Positioned.fill(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (_, i) {
                // Each illustration page shifts slightly during swipe for parallax
                final pageProgress = (_pageOffset - i).clamp(-1.0, 1.0);
                return Transform.translate(
                  offset: Offset(pageProgress * 40, 0),
                  child: _pages[i].illustration(
                    i == currentPage ? 1.0 - localT : (i == currentPage + 1 ? localT : 0.0),
                  ),
                );
              },
            ),
          ),

          // ── App name — top left (no re-animation on page change) ────────
          Positioned(
            top: topPadding + 20,
            left: AppSpacing.s24,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Aperlo',
                  style: AppText.labelLarge(color: AppColors.inkPrimary),
                ),
              ],
            ),
          ),

          // ── Skip button (no re-animation on page change) ─────────────────
          Positioned(
            top: topPadding + 16,
            right: AppSpacing.s16,
            child: GestureDetector(
              onTap: _finishOnboarding,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  'Skip',
                  style: AppText.labelLarge(color: AppColors.inkMuted),
                ),
              ),
            ),
          ),

          // ── Bottom content card ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
              padding: EdgeInsets.fromLTRB(
                28,
                28,
                28,
                bottomPadding + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tag
                  SlideTransition(
                    position: _tagSlide,
                    child: FadeTransition(
                      opacity: _tagFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentTint,
                          borderRadius: BorderRadius.circular(AppRadius.r6),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _pages[_page].tag.toUpperCase(),
                            key: ValueKey('tag_$_page'),
                            style: AppText.labelSmall(color: AppColors.accent)
                                .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Headline
                  SlideTransition(
                    position: _headlineSlide,
                    child: FadeTransition(
                      opacity: _headlineFade,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _pages[_page].headline,
                          key: ValueKey('h$_page'),
                          style: AppText.display().copyWith(
                            fontSize: size.width < 360 ? 24 : 27,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Body text
                  SlideTransition(
                    position: _bodySlide,
                    child: FadeTransition(
                      opacity: _bodyFade,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: Text(
                          _pages[_page].body,
                          key: ValueKey('b$_page'),
                          style: AppText.bodyLarge(color: AppColors.inkSecondary)
                              .copyWith(height: 1.6),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CTA row
                  SlideTransition(
                    position: _ctaSlide,
                    child: FadeTransition(
                      opacity: _ctaFade,
                      child: Row(
                        children: [
                          // Step counter — bottom left
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${_page + 1} of ${_pages.length}',
                              key: ValueKey('step_$_page'),
                              style: AppText.mono(color: AppColors.inkDisabled),
                            ),
                          ),
                          const Spacer(),
                          // Next button — circular
                          _NextButton(
                            onTap: _next,
                            isLast: _page == _pages.length - 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next button
// ─────────────────────────────────────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  const _NextButton({required this.onTap, required this.isLast});
  final VoidCallback onTap;
  final bool isLast;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: widget.isLast ? 140 : 52,
          height: 52,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.accentHover : AppColors.accent,
            borderRadius: BorderRadius.circular(widget.isLast ? 14 : 26),
          ),
          child: Center(
            child: widget.isLast
                ? Text(
                    'Get started',
                    style: AppText.labelLarge(color: Colors.white),
                  )
                : const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 01 — Templates
// A grid of template cards fanned out slightly, one highlighted
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationTemplates extends StatefulWidget {
  const _IllustrationTemplates({required this.progress});
  final double progress;

  @override
  State<_IllustrationTemplates> createState() => _IllustrationTemplatesState();
}

class _IllustrationTemplatesState extends State<_IllustrationTemplates>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, _) {
        final float = _floatCtrl.value;
        return CustomPaint(
          painter: _TemplatesPainter(float: float, progress: widget.progress),
          size: Size.infinite,
        );
      },
    );
  }
}

class _TemplatesPainter extends CustomPainter {
  const _TemplatesPainter({required this.float, required this.progress});
  final double float;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines in top area
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final y = 40.0 + i * 50.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i < 7; i++) {
      final x = i * (size.width / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height * 0.30;

    final shadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = Colors.black.withValues(alpha: 0.1);

    // Draw 3 stacked template cards
    void drawTemplateCard({
      required double x,
      required double y,
      required double w,
      required double h,
      required double angle,
      required Color bg,
      required bool isHighlighted,
      double floatY = 0,
    }) {
      canvas.save();
      canvas.translate(x, y + floatY);
      canvas.rotate(angle);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(12),
      );

      if (isHighlighted) {
        canvas.drawRRect(rect.shift(const Offset(0, 4)), shadow);
      }

      final cardPaint = Paint()..color = bg;
      canvas.drawRRect(rect, cardPaint);

      // Phone-mockup inner screen lines
      final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
      final contentPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);

      // Notch
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, -h / 2 + 8), width: w * 0.2, height: 6),
          const Radius.circular(3),
        ),
        contentPaint,
      );

      // Content lines
      for (int i = 0; i < 4; i++) {
        final lineW = i == 0 ? w * 0.65 : (i == 3 ? w * 0.4 : w * 0.55);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -h / 2 + 30 + i * 12.0), width: lineW, height: 4),
            const Radius.circular(2),
          ),
          innerPaint,
        );
      }

      if (isHighlighted) {
        // Checkmark badge
        final badgePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(w / 2 - 10, -h / 2 + 10), 9, badgePaint);
        final checkPaint = Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final path = Path()
          ..moveTo(w / 2 - 15, -h / 2 + 10)
          ..lineTo(w / 2 - 11, -h / 2 + 14)
          ..lineTo(w / 2 - 5, -h / 2 + 6);
        canvas.drawPath(path, checkPaint);
      }

      canvas.restore();
    }

    // Back card (left)
    drawTemplateCard(
      x: cx - 60,
      y: cy,
      w: 110,
      h: 175,
      angle: -0.18,
      bg: const Color(0xFF2D6A4F),
      isHighlighted: false,
      floatY: math.sin(float * math.pi * 2 + 1) * 4,
    );

    // Back card (right)
    drawTemplateCard(
      x: cx + 60,
      y: cy,
      w: 110,
      h: 175,
      angle: 0.15,
      bg: const Color(0xFF1B4332),
      isHighlighted: false,
      floatY: math.sin(float * math.pi * 2 + 2) * 5,
    );

    // Front card (center, highlighted)
    drawTemplateCard(
      x: cx,
      y: cy - 10,
      w: 120,
      h: 190,
      angle: 0,
      bg: AppColors.accent,
      isHighlighted: true,
      floatY: math.sin(float * math.pi * 2) * 6,
    );
  }

  @override
  bool shouldRepaint(_TemplatesPainter old) =>
      old.float != float || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 02 — Canvas Editor
// Phone with layers panel open, elements positioned on screen
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationEditor extends StatefulWidget {
  const _IllustrationEditor({required this.progress});
  final double progress;

  @override
  State<_IllustrationEditor> createState() => _IllustrationEditorState();
}

class _IllustrationEditorState extends State<_IllustrationEditor>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) => CustomPaint(
        painter: _EditorPainter(pulse: _pulseCtrl.value, progress: widget.progress),
        size: Size.infinite,
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  const _EditorPainter({required this.pulse, required this.progress});
  final double pulse;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines (same as step 1)
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final y = 40.0 + i * 50.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i < 7; i++) {
      final x = i * (size.width / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height * 0.30;

    // Editor background — dark canvas area on left
    final canvasBg = Paint()..color = const Color(0xFF141A14);
    final editorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 28, cy), width: 160, height: 230),
      const Radius.circular(16),
    );
    canvas.drawRRect(editorRect, canvasBg);

    // Screenshot frame on canvas
    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 28, cy), width: 100, height: 170),
        const Radius.circular(10),
      ),
      framePaint,
    );

    // Element on canvas (text layer, selected)
    final selectedPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8 + pulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 28, cy - 20), width: 72, height: 22),
        const Radius.circular(3),
      ),
      selectedPaint,
    );

    // Resize handles
    final handlePaint = Paint()..color = Colors.white;
    for (final corner in [
      Offset(cx - 28 - 36, cy - 31),
      Offset(cx - 28 + 36, cy - 31),
      Offset(cx - 28 - 36, cy - 9),
      Offset(cx - 28 + 36, cy - 9),
    ]) {
      canvas.drawCircle(corner, 3, handlePaint);
    }

    // Content lines on canvas
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(cx - 28 - 28, cy + 15 + i * 10.0),
        Offset(cx - 28 + (i == 2 ? 12 : 28), cy + 15 + i * 10.0),
        linePaint,
      );
    }

    // Properties panel on right
    final panelPaint = Paint()..color = AppColors.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 62, cy), width: 84, height: 200),
        const Radius.circular(12),
      ),
      panelPaint,
    );

    // Panel header
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 21, cy - 95, 83, 24),
        const Radius.circular(12),
      ),
      Paint()..color = AppColors.accentTint,
    );

    // Panel rows
    final rowBg = Paint()..color = AppColors.background;
    final rowAccent = Paint()..color = AppColors.accent.withValues(alpha: 0.15);
    for (int i = 0; i < 5; i++) {
      final rowY = cy - 58 + i * 30.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 23, rowY, 79, 22),
          const Radius.circular(6),
        ),
        i == 1 ? rowAccent : rowBg,
      );
      // Mini color dot on row
      if (i == 1 || i == 3) {
        canvas.drawCircle(
          Offset(cx + 35, rowY + 11),
          5,
          Paint()..color = i == 1 ? AppColors.accent : const Color(0xFF2D6A4F),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EditorPainter old) =>
      old.pulse != pulse || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 03 — Export
// Screenshot exploding into 2 size variants, flying to phone corners
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationExport extends StatefulWidget {
  const _IllustrationExport({required this.progress});
  final double progress;

  @override
  State<_IllustrationExport> createState() => _IllustrationExportState();
}

class _IllustrationExportState extends State<_IllustrationExport>
    with SingleTickerProviderStateMixin {
  late AnimationController _flyCtrl;

  @override
  void initState() {
    super.initState();
    _flyCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _flyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flyCtrl,
      builder: (context, _) => CustomPaint(
        painter: _ExportPainter(t: _flyCtrl.value, progress: widget.progress),
        size: Size.infinite,
      ),
    );
  }
}

class _ExportPainter extends CustomPainter {
  const _ExportPainter({required this.t, required this.progress});
  final double t;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines (same as step 1)
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final y = 40.0 + i * 50.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i < 7; i++) {
      final x = i * (size.width / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height * 0.29;

    // Central screenshot source
    final sourceShadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 145),
        const Radius.circular(12),
      ),
      sourceShadow,
    );

    // Main card
    final cardPaint = Paint()..color = AppColors.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 145),
        const Radius.circular(12),
      ),
      cardPaint,
    );

    // Content on card
    final whiteLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - 28, cy - 30 + i * 14.0),
        Offset(cx + (i == 3 ? 10 : 28), cy - 30 + i * 14.0),
        whiteLine,
      );
    }

    // Animated fly-out badges for App Store & Google Play
    final phase1 = (math.sin(t * math.pi * 2) + 1) / 2; // 0..1
    final phase2 = (math.sin(t * math.pi * 2 + math.pi) + 1) / 2;

    void drawBadge({
      required Offset pos,
      required String label,
      required String resolution,
      required double alpha,
    }) {
      final badgePaint = Paint()..color = AppColors.surface.withValues(alpha: alpha);
      final badgeShadow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = Colors.black.withValues(alpha: 0.08 * alpha);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: 96, height: 46),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, badgeShadow);
      canvas.drawRRect(rect, badgePaint);

      // Green dot indicator
      canvas.drawCircle(
        Offset(pos.dx - 35, pos.dy - 7),
        4,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );
    }

    drawBadge(
      pos: Offset(cx - 80 - phase1 * 8, cy - 45 - phase1 * 6),
      label: 'App Store',
      resolution: '1290×2796',
      alpha: 0.7 + phase1 * 0.3,
    );
    drawBadge(
      pos: Offset(cx + 80 + phase2 * 8, cy + 40 + phase2 * 6),
      label: 'Play Store',
      resolution: '1080×1920',
      alpha: 0.7 + phase2 * 0.3,
    );

    // Arrow lines from card to badges
    final arrowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 45, cy - 30), Offset(cx - 30, cy - 42), arrowPaint);
    canvas.drawLine(Offset(cx + 45, cy + 30), Offset(cx + 32, cy + 43), arrowPaint);
  }

  @override
  bool shouldRepaint(_ExportPainter old) =>
      old.t != t || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration 04 — Collections
// Folder grid with colored labels, one open showing screenshots inside
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationCollections extends StatefulWidget {
  const _IllustrationCollections({required this.progress});
  final double progress;

  @override
  State<_IllustrationCollections> createState() => _IllustrationCollectionsState();
}

class _IllustrationCollectionsState extends State<_IllustrationCollections>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimCtrl,
      builder: (context, _) => CustomPaint(
        painter: _CollectionsPainter(shim: _shimCtrl.value, progress: widget.progress),
        size: Size.infinite,
      ),
    );
  }
}

class _CollectionsPainter extends CustomPainter {
  const _CollectionsPainter({required this.shim, required this.progress});
  final double shim;
  final double progress;

  static const _collectionColors = [
    Color(0xFF1A6B4A), // accent
    Color(0xFF2563EB), // blue
    Color(0xFF7C3AED), // purple
    Color(0xFFDB2777), // pink
    Color(0xFFD97706), // amber
    Color(0xFF059669), // emerald
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines (same as step 1)
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final y = 40.0 + i * 50.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i < 7; i++) {
      final x = i * (size.width / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height * 0.295;

    final shadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = Colors.black.withValues(alpha: 0.08);

    // Draw a 2x3 grid of collection cards
    const cols = 3;
    const rows = 2;
    const cardW = 80.0;
    const cardH = 88.0;
    const gap = 10.0;

    final totalW = cols * cardW + (cols - 1) * gap;
    final totalH = rows * cardH + (rows - 1) * gap;
    final startX = cx - totalW / 2;
    final startY = cy - totalH / 2;

    int colorIdx = 0;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cardX = startX + col * (cardW + gap) + cardW / 2;
        final cardY = startY + row * (cardH + gap) + cardH / 2;
        final isHighlighted = row == 0 && col == 1;
        final color = _collectionColors[colorIdx % _collectionColors.length];

        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cardX, cardY), width: cardW, height: cardH),
          const Radius.circular(12),
        );

        canvas.drawRRect(rect, shadow);

        // Card bg
        canvas.drawRRect(rect, Paint()..color = AppColors.surface);

        // Color accent strip at top of card
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cardX - cardW / 2, cardY - cardH / 2, cardW, 28),
            const Radius.circular(12),
          ),
          Paint()..color = color.withValues(alpha: 0.15),
        );

        // Small folder icon dot
        canvas.drawCircle(
          Offset(cardX - 22, cardY - cardH / 2 + 14),
          7,
          Paint()..color = color,
        );

        // Name line
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cardX + 5, cardY - cardH / 2 + 14), width: 36, height: 5),
            const Radius.circular(3),
          ),
          Paint()..color = color.withValues(alpha: 0.5),
        );

        // Thumbnail mocks
        for (int t = 0; t < 3; t++) {
          final tw = (cardW - 20) / 3;
          final tx = cardX - cardW / 2 + 8 + t * (tw + 3) + tw / 2;
          final ty = cardY + 12;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(tx, ty), width: tw - 1, height: 38),
              const Radius.circular(4),
            ),
            Paint()..color = color.withValues(alpha: isHighlighted ? (0.18 + shim * 0.08) : 0.1),
          );
        }

        // Screenshot count badge
        if (isHighlighted) {
          final badgePaint = Paint()..color = color;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cardX + 28, cardY - cardH / 2 + 7), width: 20, height: 14),
              const Radius.circular(7),
            ),
            badgePaint,
          );
        }

        colorIdx++;
      }
    }
  }

  @override
  bool shouldRepaint(_CollectionsPainter old) =>
      old.shim != shim || old.progress != progress;
}
