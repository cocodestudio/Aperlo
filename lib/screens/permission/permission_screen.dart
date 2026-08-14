import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/storage_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Permission screen
// ─────────────────────────────────────────────────────────────────────────────

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entryCtrl;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonFade;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  _State _state = _State.idle;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _contentFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    ));

    _buttonFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    // Subtle pulse on the icon circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.14, end: 0.28).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_state == _State.denied || _state == _State.rejected)) {
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    final granted = await StorageUtil.isPermissionGranted();
    if (granted && mounted) {
      setState(() => _state = _State.loading);
      await StorageUtil.initHiveWithPermissions();
      if (mounted) _navigateForward();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    setState(() => _state = _State.loading);

    try {
      bool granted = false;

      if (Platform.isAndroid) {
        // Try standard storage first (works on Android ≤ 10)
        var status = await Permission.storage.request();
        if (status.isGranted) {
          granted = true;
        } else {
          // Try MANAGE_EXTERNAL_STORAGE for Android 11+
          var manageStatus =
              await Permission.manageExternalStorage.request();
          granted = manageStatus.isGranted;
        }
      } else {
        granted = true; // Non-Android platforms don't need this
      }

      if (!mounted) return;

      if (granted) {
        // Initialise Hive with the correct public directory
        await StorageUtil.initHiveWithPermissions();
        if (!mounted) return;
        _navigateForward();
      } else {
        // Check if permanently denied
        final isPermanentlyDenied =
            await Permission.storage.isPermanentlyDenied ||
                await Permission.manageExternalStorage.isPermanentlyDenied;

        if (!mounted) return;
        setState(() =>
            _state = isPermanentlyDenied ? _State.denied : _State.rejected);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _State.rejected);
    }
  }

  Future<void> _skipWithLimitedAccess() async {
    setState(() => _state = _State.loading);
    await StorageUtil.initHiveWithPermissions(); // falls back to app data dir
    if (!mounted) return;
    _navigateForward();
  }

  void _navigateForward() {
    final settingsBox = Hive.box('settings');
    final hasSeenOnboarding =
        settingsBox.get('hasSeenOnboarding', defaultValue: false) as bool;
    if (hasSeenOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    // Use smaller proportions on compact screens (< 680px usable height)
    final isCompact = (screenH - topPad - bottomPad) < 680;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
        children: [
          const Positioned.fill(child: _BackgroundDots()),
          LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      // Ensure the column fills the full available height so
                      // Spacer pushes buttons to the bottom when content is short
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 28,
                            right: 28,
                            top: topPad + (isCompact ? 12 : 20),
                            bottom: bottomPad + (isCompact ? 12 : 20),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Icon area ──────────────────────────────────────
                          FadeTransition(
                            opacity: _iconFade,
                            child: SlideTransition(
                              position: _iconSlide,
                              child: _IconSection(
                                pulseScale: _pulseScale,
                                pulseOpacity: _pulseOpacity,
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 14 : 20),

                          // ── Headline & body ────────────────────────────────
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: _ContentSection(state: _state),
                            ),
                          ),

                          SizedBox(height: isCompact ? 16 : 24),

                          // ── Reason cards ───────────────────────────────────
                          FadeTransition(
                            opacity: _cardFade,
                            child: SlideTransition(
                              position: _cardSlide,
                              child: const _ReasonCards(),
                            ),
                          ),

                          const Spacer(),

                          // Gap between cards and buttons
                          SizedBox(height: isCompact ? 16 : 24),

                          // ── CTA buttons ────────────────────────────────────
                          FadeTransition(
                            opacity: _buttonFade,
                            child: _ActionButtons(
                              state: _state,
                              onAllow: _requestPermission,
                              onSkip: _skipWithLimitedAccess,
                              onOpenSettings: openAppSettings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
),
);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State enum
// ─────────────────────────────────────────────────────────────────────────────

enum _State { idle, loading, rejected, denied }

// ─────────────────────────────────────────────────────────────────────────────
// Icon section
// ─────────────────────────────────────────────────────────────────────────────

class _IconSection extends StatelessWidget {
  const _IconSection({
    required this.pulseScale,
    required this.pulseOpacity,
  });

  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseScale, pulseOpacity]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Transform.scale(
                scale: pulseScale.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent
                        .withValues(alpha: pulseOpacity.value),
                  ),
                ),
              ),
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.folderOpen,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content section
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.state});
  final _State state;

  @override
  Widget build(BuildContext context) {
    final headline = switch (state) {
      _State.denied => 'Permission\nrequired',
      _State.rejected => 'Permission\nneeded',
      _ => 'One-time\naccess needed',
    };

    final body = switch (state) {
      _State.denied =>
        'Storage access was permanently denied. Open settings to grant it, or continue with limited access (your data won\'t persist across reinstalls).',
      _State.rejected =>
        'You declined storage access. Your collections and screenshots won\'t survive a reinstall. Allow access to keep your work safe.',
      _ =>
        'Aperlo stores your collections and screenshots in a public folder so your work survives app updates and data clears.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: AppText.display().copyWith(fontSize: 30)),
        const SizedBox(height: 12),
        Text(body,
            style: AppText.bodyLarge(color: AppColors.inkSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reason cards
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonCards extends StatelessWidget {
  const _ReasonCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ReasonTile(
          icon: LucideIcons.shieldCheck,
          title: 'Survives reinstalls',
          body: 'Your data lives outside the app sandbox — a factory reset is the only thing that removes it.',
        ),
        SizedBox(height: 8),
        _ReasonTile(
          icon: LucideIcons.imagePlus,
          title: 'Save screenshots',
          body: 'Exported images are written directly to your Documents folder — no middle steps.',
        ),
        SizedBox(height: 8),
        _ReasonTile(
          icon: LucideIcons.lock,
          title: 'Only Aperlo reads it',
          body: 'Access is limited to the Aperlo folder. Nothing else on your device is touched.',
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.labelLarge()),
                const SizedBox(height: 2),
                Text(body,
                    style: AppText.bodySmall(color: AppColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.onAllow,
    required this.onSkip,
    required this.onOpenSettings,
  });

  final _State state;
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isLoading = state == _State.loading;

    if (state == _State.denied) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(
            label: 'Open settings',
            icon: LucideIcons.settings,
            isLoading: false,
            onTap: onOpenSettings,
          ),
          const SizedBox(height: 10),
          _GhostButton(
            label: 'Continue with limited access',
            onTap: onSkip,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryButton(
          label: state == _State.rejected
              ? 'Allow access'
              : 'Allow storage access',
          isLoading: isLoading,
          onTap: isLoading ? null : onAllow,
        ),
        const SizedBox(height: 10),
        _GhostButton(
          label: 'Continue with limited access',
          onTap: isLoading ? null : onSkip,
        ),
      ],
    );
  }
}

// ── Primary filled button ────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.isLoading,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _pressCtrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) async {
              await _pressCtrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) => Transform.scale(
          scale: _pressScale.value,
          child: child,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.onTap != null
                ? AppColors.accent
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 16,
                        color: widget.onTap != null
                            ? Colors.white
                            : AppColors.inkDisabled,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppText.labelLarge(
                        color: widget.onTap != null
                            ? Colors.white
                            : AppColors.inkDisabled,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Ghost text button ────────────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppText.labelDefault(
            color: onTap != null ? AppColors.inkMuted : AppColors.inkDisabled,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative background dots (subtle, hand-crafted, non-AI feel)
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundDots extends StatelessWidget {
  const _BackgroundDots();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CustomPaint(
      size: Size(size.width, size.height),
      painter: _DotsPainter(),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Sparse dot grid, top-right quadrant only
    const spacing = 28.0;
    const dotR = 1.8;
    final cols = (size.width * 0.55 / spacing).ceil();
    final rows = (size.height * 0.45 / spacing).ceil();

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = size.width - (c * spacing) - spacing;
        final y = (r * spacing) + spacing;
        // Fade dots near the edges
        final edgeFade =
            math.min(1.0, math.min(c / 4.0, (rows - r - 1) / 3.0));
        canvas.drawCircle(
          Offset(x, y),
          dotR,
          paint..color = AppColors.accent.withValues(alpha: 0.06 * edgeFade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
