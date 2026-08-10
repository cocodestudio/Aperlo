import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? leadingIcon;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.isLoading || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null && !widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: disabled ? null : _handleTap,
      child: AnimatedScale(
        scale: _pressed && !disabled ? 0.98 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: widget.isFullWidth ? _buildBody(disabled) : IntrinsicWidth(child: _buildBody(disabled)),
      ),
    );
  }

  Widget _buildBody(bool disabled) {
    final (bg, fg, border) = _resolveColors(disabled);

    final content = widget.isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leadingIcon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 20),
                  child: widget.leadingIcon!,
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              Text(widget.label, style: AppText.labelLarge(color: fg)),
            ],
          );

    return AnimatedContainer(
      duration: AppMotion.fast,
      height: widget.variant == AppButtonVariant.ghost ? 40 : widget.height,
      constraints: const BoxConstraints(minWidth: 120),
      width: widget.isFullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.variant == AppButtonVariant.ghost
            ? AppSpacing.s12
            : AppSpacing.s20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
        border: border != null ? Border.all(color: border, width: 1.5) : null,
      ),
      child: Center(child: content),
    );
  }

  (Color bg, Color fg, Color? border) _resolveColors(bool disabled) {
    if (disabled) {
      return (AppColors.surfaceMuted, AppColors.inkDisabled, null);
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (_pressed ? AppColors.accentHover : AppColors.accent, AppColors.accentOn, null);
      case AppButtonVariant.secondary:
        return (
          _pressed ? AppColors.surfaceMuted : Colors.transparent,
          AppColors.inkPrimary,
          _pressed ? AppColors.borderStrong : AppColors.borderDefault,
        );
      case AppButtonVariant.ghost:
        return (_pressed ? AppColors.accentTint : Colors.transparent, AppColors.accent, null);
      case AppButtonVariant.destructive:
        return (AppColors.destructive, AppColors.accentOn, null);
    }
  }
}

/// Icon-only button with 40×40 tap target
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.semanticLabel,
    this.size = 24,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final bool isActive;
  final String? semanticLabel;
  final double size;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.accentTint
                : _pressed
                    ? AppColors.surfaceMuted
                    : Colors.transparent,
            borderRadius: AppRadius.br10,
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
