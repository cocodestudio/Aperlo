import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

const SystemUiOverlayStyle appSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.go('/crash', extra: details.exceptionAsString());
      }
    });
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.go('/crash', extra: error.toString());
      }
    });
    return true;
  };

  SystemChrome.setSystemUIOverlayStyle(appSystemUiOverlayStyle);

  runApp(const ProviderScope(child: AperloApp()));
}

class AperloApp extends ConsumerWidget {
  const AperloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appSystemUiOverlayStyle,
      child: MaterialApp.router(
        title: 'Aperlo',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
        color: AppColors.background,
      ),
    );
  }
}
