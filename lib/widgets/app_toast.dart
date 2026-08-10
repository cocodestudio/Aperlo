import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

enum AppToastType { info, success, error }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    Color bgColor = AppColors.surface;
    Color fgColor = AppColors.inkPrimary;
    Color iconColor;
    IconData icon;

    switch (type) {
      case AppToastType.info:
        iconColor = AppColors.inkSecondary;
        icon = LucideIcons.info;
        break;
      case AppToastType.success:
        iconColor = AppColors.accent;
        icon = LucideIcons.checkCircle2;
        break;
      case AppToastType.error:
        bgColor = AppColors.destructiveTint;
        iconColor = AppColors.destructive;
        fgColor = AppColors.destructive;
        icon = LucideIcons.alertCircle;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.br12,
            border: Border.all(color: type == AppToastType.error ? AppColors.destructive.withValues(alpha: 0.2) : AppColors.borderSubtle),
            boxShadow: AppShadows.subtleUp,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppText.bodyDefault(color: fgColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
