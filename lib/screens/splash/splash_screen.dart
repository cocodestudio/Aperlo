import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/storage_util.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _wordmarkCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _exitCtrl;

  // ── Animations ───────────────────────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotate;
  late final Animation<double> _glowPulse;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  bool _animStarted = false;

  @override
  void initState() {
    super.initState();

    // Background ambient
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Expanding ring burst
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Logo entrance
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Glow pulse (looping)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Wordmark slide-up
    _wordmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Tagline fade
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Bottom dots
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Exit shrink
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // ── Bind animations ────────────────────────────────────────────────────────
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    // Ring 1: immediate burst from center
    _ring1Scale = Tween<double>(begin: 0.6, end: 1.8).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    // Ring 2: delayed burst
    _ring2Scale = Tween<double>(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
      ),
    );

    // Logo: spring scale + fade + slight rotation snap
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );

    // Glow breathe
    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Wordmark
    _wordmarkFade = CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOut);
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOutQuart),
    );

    // Tagline
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic),
    );

    // Dots
    _dotsOpacity = CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeOut);

    // Exit
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animStarted) {
      _animStarted = true;
      if (MediaQuery.of(context).disableAnimations) {
        // Instantly complete all animations
        for (final ctrl in [
          _bgCtrl, _ringCtrl, _logoCtrl,
          _wordmarkCtrl, _taglineCtrl, _dotsCtrl,
        ]) {
          ctrl.value = 1.0;
        }
        _navigate();
      } else {
        _runSequence();
      }
    }
  }

  Future<void> _runSequence() async {
    // Brief settle delay
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Background + rings burst simultaneously
    _bgCtrl.forward();
    _ringCtrl.forward();

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Logo springs in with elasticity
    await _logoCtrl.forward();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Wordmark slides up
    _wordmarkCtrl.forward();

    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    // Tagline fades in
    _taglineCtrl.forward();

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    // Bottom dots appear
    _dotsCtrl.forward();

    // Initialize storage while user admires the splash
    await StorageUtil.initHiveWithPermissions(request: false);

    // Minimum display hold
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    await _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final settingsBox = Hive.box('settings');
    final hasSeenOnboarding =
        settingsBox.get('hasSeenOnboarding', defaultValue: false);

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
      return;
    }

    final bool permissionAlreadyGranted =
        await StorageUtil.isPermissionGranted();

    if (!mounted) return;

    if (!permissionAlreadyGranted) {
      context.go('/permission');
      return;
    }

    context.go('/home');
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _ringCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _wordmarkCtrl.dispose();
    _taglineCtrl.dispose();
    _dotsCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _exitFade,
      child: ScaleTransition(
        scale: _exitScale,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── Ambient radial glow behind logo ──────────────────────────────
              _AmbientGlow(pulse: _glowPulse, bgFade: _bgFade),

              // ── Ring burst ───────────────────────────────────────────────────
              _RingBurst(
                ring1Scale: _ring1Scale,
                ring1Opacity: _ring1Opacity,
                ring2Scale: _ring2Scale,
                ring2Opacity: _ring2Opacity,
              ),

              // ── Decorative corner accents ───────────────────────────────────
              _CornerAccents(fade: _bgFade),

              // ── Center content ───────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo mark
                    AnimatedBuilder(
                      animation: Listenable.merge([_logoCtrl, _glowCtrl]),
                      builder: (context, _) => Transform.rotate(
                        angle: _logoRotate.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value.clamp(0.0, 1.0),
                            child: _AperloLogoMark(glowIntensity: _glowPulse.value),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Wordmark
                    ClipRect(
                      child: SlideTransition(
                        position: _wordmarkSlide,
                        child: FadeTransition(
                          opacity: _wordmarkFade,
                          child: Text(
                            'Aperlo',
                            style: AppText.display().copyWith(
                              fontSize: 38,
                              letterSpacing: -1.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    ClipRect(
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: FadeTransition(
                          opacity: _taglineFade,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 1.5,
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Screenshot it. Ship it.',
                                style: AppText.bodyDefault(
                                  color: AppColors.inkMuted,
                                ).copyWith(
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 18,
                                height: 1.5,
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom dots indicator ─────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 52,
                child: FadeTransition(
                  opacity: _dotsOpacity,
                  child: const _BottomDots(),
                ),
              ),

              // ── Version stamp ─────────────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: FadeTransition(
                  opacity: _dotsOpacity,
                  child: Text(
                    'by CoCode Studio',
                    textAlign: TextAlign.center,
                    style: AppText.mono(
                      color: AppColors.inkDisabled,
                    ).copyWith(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ambient radial glow ──────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.pulse,
    required this.bgFade,
  });

  final Animation<double> pulse;
  final Animation<double> bgFade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, bgFade]),
      builder: (context, _) {
        final intensity = pulse.value * bgFade.value;
        return Positioned.fill(
          child: CustomPaint(
            painter: _GlowPainter(intensity: intensity),
          ),
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);

    // Outer ambient wash
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.10 * intensity),
          AppColors.accentTint.withValues(alpha: 0.06 * intensity),
          AppColors.background.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.72),
      );

    canvas.drawCircle(center, size.width * 0.72, outerPaint);

    // Tight core glow
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentTint.withValues(alpha: 0.55 * intensity),
          AppColors.accentTint.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: 130),
      );

    canvas.drawCircle(center, 130, corePaint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.intensity != intensity;
}

// ── Burst rings ──────────────────────────────────────────────────────────────

class _RingBurst extends StatelessWidget {
  const _RingBurst({
    required this.ring1Scale,
    required this.ring1Opacity,
    required this.ring2Scale,
    required this.ring2Opacity,
  });

  final Animation<double> ring1Scale;
  final Animation<double> ring1Opacity;
  final Animation<double> ring2Scale;
  final Animation<double> ring2Opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ring1Scale, ring2Scale]),
      builder: (context, _) {
        return Positioned.fill(
          child: CustomPaint(
            painter: _RingPainter(
              ring1Scale: ring1Scale.value,
              ring1Opacity: ring1Opacity.value,
              ring2Scale: ring2Scale.value,
              ring2Opacity: ring2Opacity.value,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ring1Scale,
    required this.ring1Opacity,
    required this.ring2Scale,
    required this.ring2Opacity,
  });

  final double ring1Scale;
  final double ring1Opacity;
  final double ring2Scale;
  final double ring2Opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    const baseRadius = 64.0;

    // Ring 1
    if (ring1Opacity > 0) {
      final p1 = Paint()
        ..color = AppColors.accent.withValues(alpha: ring1Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, baseRadius * ring1Scale, p1);
    }

    // Ring 2
    if (ring2Opacity > 0) {
      final p2 = Paint()
        ..color = AppColors.accent.withValues(alpha: ring2Opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, baseRadius * ring2Scale, p2);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ring1Scale != ring1Scale ||
      old.ring1Opacity != ring1Opacity ||
      old.ring2Scale != ring2Scale ||
      old.ring2Opacity != ring2Opacity;
}

// ── Corner accent geometry ───────────────────────────────────────────────────

class _CornerAccents extends StatelessWidget {
  const _CornerAccents({required this.fade});

  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (context, _) => Positioned.fill(
        child: CustomPaint(
          painter: _CornerPainter(opacity: fade.value),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.07 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const padding = 28.0;
    const len = 22.0;

    // Top-left corner
    final tl = const Offset(padding, padding);
    canvas.drawLine(tl, tl + const Offset(len, 0), paint);
    canvas.drawLine(tl, tl + const Offset(0, len), paint);

    // Top-right corner
    final tr = Offset(size.width - padding, padding);
    canvas.drawLine(tr, tr + const Offset(-len, 0), paint);
    canvas.drawLine(tr, tr + const Offset(0, len), paint);

    // Bottom-left corner
    final bl = Offset(padding, size.height - padding);
    canvas.drawLine(bl, bl + const Offset(len, 0), paint);
    canvas.drawLine(bl, bl + const Offset(0, -len), paint);

    // Bottom-right corner
    final br = Offset(size.width - padding, size.height - padding);
    canvas.drawLine(br, br + const Offset(-len, 0), paint);
    canvas.drawLine(br, br + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.opacity != opacity;
}

// ── Aperlo custom logo mark ───────────────────────────────────────────────────

class _AperloLogoMark extends StatelessWidget {
  const _AperloLogoMark({required this.glowIntensity});

  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow shadow layer
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28 * glowIntensity),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.18 * glowIntensity),
                  blurRadius: 56,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),

          // Main app icon
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom dots ──────────────────────────────────────────────────────────────

class _BottomDots extends StatefulWidget {
  const _BottomDots();

  @override
  State<_BottomDots> createState() => _BottomDotsState();
}

class _BottomDotsState extends State<_BottomDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Stagger: each dot lags by 150ms worth of phase
            final phase = (_anim.value - i * 0.22).clamp(0.0, 1.0);
            final pulse = math.sin(phase * math.pi).clamp(0.0, 1.0);
            final size = 4.0 + pulse * 3.0;
            final opacity = 0.3 + pulse * 0.6;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
