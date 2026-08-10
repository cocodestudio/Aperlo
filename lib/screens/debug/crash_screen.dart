import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';

class CrashScreen extends StatelessWidget {
  final String? error;
  const CrashScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.destructiveTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.destructive),
                ),
                const SizedBox(height: 32),
                Text('Oops! Something went wrong.', style: AppText.headline1(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  'The app encountered an unexpected error. Please restart the app to continue.',
                  style: AppText.bodyLarge(color: AppColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: error!));
                      AppToast.show(context, message: 'Error copied to clipboard', type: AppToastType.success);
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('Copy Error Log'),
                  ),
                ],
                const SizedBox(height: 48),
                AppButton(
                  label: 'Restart app',
                  onPressed: () {
                    context.go('/splash');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
