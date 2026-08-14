import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

/// Representation of an actionable option item in the redesigned modal sheet.
class AppOptionAction {
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isPrimary;
  final String? badgeText;

  const AppOptionAction({
    required this.label,
    this.description,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.isPrimary = false,
    this.badgeText,
  });
}

/// Redesigned, ultra-modern options modal sheet with bespoke interactive ripple tiles,
/// tinted icon badges, and responsive safe area constraints.
class AppOptionsModalSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? headerIcon;
  final Color? headerColor;
  final List<AppOptionAction> actions;

  const AppOptionsModalSheet({
    super.key,
    this.title,
    this.subtitle,
    this.headerIcon,
    this.headerColor,
    required this.actions,
  });

  /// Static helper to display the sheet smoothly.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    IconData? headerIcon,
    Color? headerColor,
    required List<AppOptionAction> actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => AppOptionsModalSheet(
        title: title,
        subtitle: subtitle,
        headerIcon: headerIcon,
        headerColor: headerColor,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final standardActions = actions.where((a) => !a.isDestructive).toList();
    final destructiveActions = actions.where((a) => a.isDestructive).toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
          boxShadow: AppShadows.float,
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag Handle Pill ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header Card (Optional) ─────────────────────────────────────
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      if (headerIcon != null) ...[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: (headerColor ?? AppColors.accent).withValues(alpha: 0.12),
                            borderRadius: AppRadius.br10,
                            border: Border.all(
                              color: (headerColor ?? AppColors.accent).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            headerIcon,
                            size: 18,
                            color: headerColor ?? AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: AppText.headline2().copyWith(fontSize: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: AppText.bodySmall(color: AppColors.inkMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.x, size: 14, color: AppColors.inkPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 8),
              ],

              // ── Grouped Actions List ───────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Standard Options Group
                      if (standardActions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted.withValues(alpha: 0.4),
                            borderRadius: AppRadius.br16,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: List.generate(standardActions.length, (i) {
                              final action = standardActions[i];
                              final isLast = i == standardActions.length - 1;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _OptionTile(action: action),
                                  if (!isLast)
                                    const Divider(
                                      color: AppColors.borderSubtle,
                                      height: 1,
                                      indent: 56,
                                      endIndent: 16,
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),

                      // Destructive Options Group (Visually separated)
                      if (destructiveActions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.destructive.withValues(alpha: 0.05),
                            borderRadius: AppRadius.br16,
                            border: Border.all(
                              color: AppColors.destructive.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: List.generate(destructiveActions.length, (i) {
                              final action = destructiveActions[i];
                              final isLast = i == destructiveActions.length - 1;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _OptionTile(action: action),
                                  if (!isLast)
                                    Divider(
                                      color: AppColors.destructive.withValues(alpha: 0.15),
                                      height: 1,
                                      indent: 56,
                                      endIndent: 16,
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
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

/// Redesigned individual option tile with modern rounded ripple, glowing feedback,
/// and clear typography.
class _OptionTile extends StatelessWidget {
  final AppOptionAction action;

  const _OptionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDestructive = action.isDestructive;
    final iconBgColor = isDestructive
        ? AppColors.destructive.withValues(alpha: 0.12)
        : action.isPrimary
            ? AppColors.accent.withValues(alpha: 0.14)
            : AppColors.surface;
    final iconColor = isDestructive
        ? AppColors.destructive
        : action.isPrimary
            ? AppColors.accent
            : AppColors.inkPrimary;
    final textColor = isDestructive ? AppColors.destructive : AppColors.inkPrimary;
    final splashColor = isDestructive
        ? AppColors.destructive.withValues(alpha: 0.14)
        : AppColors.accent.withValues(alpha: 0.12);
    final highlightColor = isDestructive
        ? AppColors.destructive.withValues(alpha: 0.06)
        : AppColors.accent.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: splashColor,
        highlightColor: highlightColor,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Leading Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: AppRadius.br10,
                  border: Border.all(
                    color: isDestructive
                        ? AppColors.destructive.withValues(alpha: 0.2)
                        : AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    action.icon,
                    size: 17,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.label,
                      style: AppText.labelLarge(color: textColor).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (action.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.description!,
                        style: AppText.bodySmall(
                          color: isDestructive
                              ? AppColors.destructive.withValues(alpha: 0.75)
                              : AppColors.inkMuted,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              // Badge (Optional)
              if (action.badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                  ),
                  child: Text(
                    action.badgeText!,
                    style: AppText.labelSmall(color: AppColors.accent).copyWith(fontSize: 10),
                  ),
                ),
              ],

              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: isDestructive
                    ? AppColors.destructive.withValues(alpha: 0.4)
                    : AppColors.inkDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
