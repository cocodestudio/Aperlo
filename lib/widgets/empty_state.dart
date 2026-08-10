import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'app_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Floating Icon Badge with Idle Breathing Animation
// ─────────────────────────────────────────────────────────────────────────────

class _FloatBadge extends StatefulWidget {
  const _FloatBadge({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  @override
  State<_FloatBadge> createState() => _FloatBadgeState();
}

class _FloatBadgeState extends State<_FloatBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        final dy = math.sin(_floatCtrl.value * math.pi) * 6.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.iconColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.bgColor.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.iconColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(widget.icon, size: 28, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Empty State Component
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.headline,
    required this.description,
    this.illustration,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String headline;
  final String description;
  final Widget? illustration;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.slow);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget visual;
    if (widget.illustration != null) {
      visual = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: widget.illustration!,
      );
    } else {
      final displayIcon = widget.icon ?? LucideIcons.folderOpen;
      visual = _FloatBadge(
        icon: displayIcon,
        bgColor: AppColors.accentTint,
        iconColor: AppColors.accent,
      );
    }

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          visual,
          const SizedBox(height: AppSpacing.s24),
          Text(
            widget.headline,
            style: AppText.headline2(color: AppColors.inkPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              widget.description,
              style: AppText.bodyDefault(color: AppColors.inkMuted)
                  .copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: widget.actionLabel!,
              onPressed: widget.onAction,
              leadingIcon: const Icon(LucideIcons.plus, size: 20),
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return Center(child: content);

    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: content),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Error State Component
// ─────────────────────────────────────────────────────────────────────────────

class ErrorState extends StatefulWidget {
  const ErrorState({
    super.key,
    this.headline = 'Something went wrong',
    required this.description,
    this.icon = LucideIcons.alertCircle,
    this.retryLabel = 'Try again',
    this.onRetry,
  });

  final String headline;
  final String description;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.slow);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatBadge(
            icon: widget.icon,
            bgColor: AppColors.destructiveTint,
            iconColor: AppColors.destructive,
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            widget.headline,
            style: AppText.headline2(color: AppColors.inkPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              widget.description,
              style: AppText.bodyDefault(color: AppColors.inkMuted)
                  .copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: widget.retryLabel,
              onPressed: widget.onRetry,
              leadingIcon: const Icon(LucideIcons.refreshCw, size: 20),
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return Center(child: content);

    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: content),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Success State Component
// ─────────────────────────────────────────────────────────────────────────────

class SuccessState extends StatefulWidget {
  const SuccessState({
    super.key,
    required this.headline,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String headline;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<SuccessState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.base);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.checkCheck, size: 32, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Text(
            widget.headline,
            style: AppText.headline2(color: AppColors.inkPrimary),
            textAlign: TextAlign.center,
          ),
          if (widget.description != null) ...[
            const SizedBox(height: AppSpacing.s8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                widget.description!,
                style: AppText.bodyDefault(color: AppColors.inkMuted)
                    .copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: widget.actionLabel!,
              onPressed: widget.onAction,
            ),
          ],
        ],
      ),
    );

    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(scale: _scale, child: content),
      ),
    );
  }
}

