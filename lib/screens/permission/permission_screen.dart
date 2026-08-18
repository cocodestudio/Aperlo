import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/permissions/app_permissions.dart';
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

  Map<String, bool> _statuses = {};
  bool _isLoading = true;
  bool _isStoragePermanentlyDenied = false;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
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

    // Pulse animation
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

    _refreshStatuses();
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
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final statuses = await AppPermissions.checkAllStatuses();
    bool permanentlyDenied = false;
    for (final item in AppPermissions.items) {
      if (item.isRequired && (statuses[item.id] != true)) {
        permanentlyDenied = await item.checkPermanentlyDenied();
        if (permanentlyDenied) break;
      }
    }

    if (mounted) {
      setState(() {
        _statuses = statuses;
        _isLoading = false;
        _isStoragePermanentlyDenied = permanentlyDenied;
      });
    }
  }

  Future<void> _requestSinglePermission(AppPermissionItem item) async {
    setState(() => _isLoading = true);
    try {
      final granted = await item.requestPermission();
      if (item.id == 'storage' && granted) {
        await StorageUtil.initHiveWithPermissions();
      }
    } catch (_) {}

    await _refreshStatuses();

    // Check if all required permissions are now granted
    final requiredGranted = await AppPermissions.areRequiredPermissionsGranted();
    if (requiredGranted && mounted) {
      _navigateForward();
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);
    try {
      final results = await AppPermissions.requestAll();
      if (results['storage'] == true) {
        await StorageUtil.initHiveWithPermissions();
      }
    } catch (_) {}

    await _refreshStatuses();

    final requiredGranted = await AppPermissions.areRequiredPermissionsGranted();
    if (requiredGranted && mounted) {
      _navigateForward();
    }
  }

  Future<void> _skipWithLimitedAccess() async {
    setState(() => _isLoading = true);
    await StorageUtil.initHiveWithPermissions();
    if (!mounted) return;
    _navigateForward();
  }

  Future<void> _navigateForward() async {
    final hasSeenOnboarding = await StorageUtil.hasSeenOnboarding();
    if (!mounted) return;
    if (hasSeenOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final isCompact = (screenH - topPad - bottomPad) < 700;

    final allRequiredGranted = AppPermissions.items
        .where((e) => e.isRequired)
        .every((e) => _statuses[e.id] == true);

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
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: topPad + (isCompact ? 12 : 24),
                              bottom: bottomPad + (isCompact ? 12 : 24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Icon header ─────────────────────────────
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

                                // ── Headline & explanation ──────────────────
                                FadeTransition(
                                  opacity: _contentFade,
                                  child: SlideTransition(
                                    position: _contentSlide,
                                    child: _ContentSection(
                                      isPermanentlyDenied:
                                          _isStoragePermanentlyDenied,
                                      allGranted: allRequiredGranted,
                                    ),
                                  ),
                                ),

                                SizedBox(height: isCompact ? 16 : 24),

                                // ── Dynamic Permission Cards ────────────────
                                FadeTransition(
                                  opacity: _cardFade,
                                  child: SlideTransition(
                                    position: _cardSlide,
                                    child: Column(
                                      children: AppPermissions.items.map((item) {
                                        final isGranted =
                                            _statuses[item.id] ?? false;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _PermissionCard(
                                            item: item,
                                            isGranted: isGranted,
                                            isLoading: _isLoading,
                                            onAllow: () =>
                                                _requestSinglePermission(item),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                SizedBox(height: isCompact ? 16 : 24),

                                // ── Action CTA buttons ──────────────────────
                                FadeTransition(
                                  opacity: _buttonFade,
                                  child: _ActionButtons(
                                    isLoading: _isLoading,
                                    isPermanentlyDenied:
                                        _isStoragePermanentlyDenied,
                                    allRequiredGranted: allRequiredGranted,
                                    onAllowAll: _requestAllPermissions,
                                    onContinue: _navigateForward,
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
// Icon Section
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
      width: 76,
      height: 76,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseScale, pulseOpacity]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulseScale.value,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent
                        .withValues(alpha: pulseOpacity.value),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.26),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: Colors.white,
                  size: 26,
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
// Content Section
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.isPermanentlyDenied,
    required this.allGranted,
  });

  final bool isPermanentlyDenied;
  final bool allGranted;

  @override
  Widget build(BuildContext context) {
    final headline = isPermanentlyDenied
        ? 'Settings\naccess required'
        : allGranted
            ? 'Permissions\nconfigured'
            : 'Permissions\n& access';

    final body = isPermanentlyDenied
        ? 'Storage access was permanently denied. Please open system settings to enable it, or proceed with limited session storage.'
        : allGranted
            ? 'All required studio permissions are active. You are ready to start creating screenshots.'
            : 'Grant access so Aperlo can safely save exports, load mockup screenshots, and keep you updated on new templates.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: AppText.display().copyWith(fontSize: 28, height: 1.15),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: AppText.bodyDefault(color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission Card
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.item,
    required this.isGranted,
    required this.isLoading,
    required this.onAllow,
  });

  final AppPermissionItem item;
  final bool isGranted;
  final bool isLoading;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppColors.accent.withValues(alpha: 0.3) : AppColors.borderSubtle,
          width: isGranted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: isGranted ? AppColors.accent : AppColors.inkSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppText.labelLarge().copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    _buildBadge(),
                  ],
                ),
              ),
              if (isGranted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.check, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Granted',
                        style: AppText.labelSmall(color: AppColors.accent)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: isLoading ? null : onAllow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Allow',
                        style: AppText.labelSmall(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: AppText.bodySmall(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    if (isGranted) return const SizedBox.shrink();

    if (item.isRequired) {
      return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF0D5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'REQUIRED',
          style: AppText.labelSmall(color: const Color(0xFFB05000))
              .copyWith(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'RECOMMENDED',
        style: AppText.labelSmall(color: AppColors.inkMuted)
            .copyWith(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.isPermanentlyDenied,
    required this.allRequiredGranted,
    required this.onAllowAll,
    required this.onContinue,
    required this.onSkip,
    required this.onOpenSettings,
  });

  final bool isLoading;
  final bool isPermanentlyDenied;
  final bool allRequiredGranted;
  final VoidCallback onAllowAll;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (isPermanentlyDenied) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(
            label: 'Open System Settings',
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

    if (allRequiredGranted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(
            label: 'Continue to Studio',
            icon: LucideIcons.arrowRight,
            isLoading: isLoading,
            onTap: onContinue,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryButton(
          label: 'Grant All Permissions',
          icon: LucideIcons.checkCheck,
          isLoading: isLoading,
          onTap: isLoading ? null : onAllowAll,
        ),
        const SizedBox(height: 10),
        _GhostButton(
          label: 'Skip for now (Limited access)',
          onTap: onSkip,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom styled buttons & Background dots
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppText.labelLarge(color: Colors.white)
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.inkMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: AppText.labelDefault(color: AppColors.inkMuted)
              .copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

class _BackgroundDots extends StatelessWidget {
  const _BackgroundDots();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotMatrixPainter(),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkMuted.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
