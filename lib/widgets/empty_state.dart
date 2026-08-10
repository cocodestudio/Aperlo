import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'app_button.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.headline,
    required this.description,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String headline;
  final String description;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.slow);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));
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

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.illustration != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: widget.illustration!,
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
        Text(
          widget.headline,
          style: AppText.headline2(color: AppColors.inkPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            widget.description,
            style: AppText.bodyDefault(color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.actionLabel != null) ...[
          const SizedBox(height: AppSpacing.s32),
          Center(
            child: AppButton(label: widget.actionLabel!, onPressed: widget.onAction),
          ),
        ],
      ],
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
