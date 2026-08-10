import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

/// "PRO" badge
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadius.br6,
      ),
      child: Center(
        child: Text(
          'PRO',
          style: AppText.labelSmall(color: AppColors.accentOn).copyWith(
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Category filter chip (horizontal scroll row usage)
class CategoryChip extends StatefulWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.accentTint : Colors.transparent,
            borderRadius: AppRadius.brFull,
            border: Border.all(
              color: widget.isSelected ? AppColors.accent : AppColors.borderDefault,
            ),
          ),
          child: Center(
            widthFactor: 1.0,
            child: Text(
              widget.label,
              style: AppText.labelDefault(
                color: widget.isSelected ? AppColors.accent : AppColors.inkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status tag: success / warning / error
enum StatusTagVariant { success, warning, error }

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.label, required this.variant});

  final String label;
  final StatusTagVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      StatusTagVariant.success => (AppColors.accentTint, AppColors.accent),
      StatusTagVariant.warning => (AppColors.warningTint, AppColors.warning),
      StatusTagVariant.error => (AppColors.destructiveTint, AppColors.destructive),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brFull),
      child: Text(label, style: AppText.labelDefault(color: fg)),
    );
  }
}

/// Count badge (on nav icons)
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: AppRadius.brFull,
      ),
      child: Center(
        child: Text(
          label,
          style: AppText.labelSmall(color: AppColors.accentOn).copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
