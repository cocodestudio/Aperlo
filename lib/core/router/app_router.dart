import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/collections/collections_screen.dart';
import '../../screens/collections/collection_detail_screen.dart';
import '../../screens/templates/template_browser_screen.dart';
import '../../screens/templates/template_preview_screen.dart';
import '../../screens/editor/editor_screen.dart';
import '../../screens/debug/crash_screen.dart';
import '../../screens/permission/permission_screen.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/storage_util.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

// Expose router as a provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.uri.toString();
      
      if (!Hive.isBoxOpen('settings')) {
        if (loc.startsWith('/splash')) return null;
        if (loc == '/') return '/splash';
        return '/splash?next=${Uri.encodeComponent(loc)}';
      }

      final hasSeenOnboarding = StorageUtil.hasSeenOnboardingSync();

      if (loc == '/splash') return null; // Let splash decide when to move
      if (loc == '/onboarding') {
        if (hasSeenOnboarding) return '/home';
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash', 
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/templates',
                builder: (context, state) => TemplateBrowserScreen(
                  preselectedCollectionId: state.extra as String?,
                ),
                routes: [
                  GoRoute(
                    path: ':templateId',
                    builder: (context, state) => TemplatePreviewScreen(
                      templateId: state.pathParameters['templateId']!,
                      preselectedCollectionId: state.extra as String?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/collections',
                builder: (context, state) => const CollectionsScreen(),
                routes: [
                  GoRoute(
                    path: ':collectionId',
                    builder: (context, state) => CollectionDetailScreen(
                      collectionId: state.pathParameters['collectionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/editor/:screenshotId',
        builder: (context, state) => EditorScreen(
          screenshotId: state.pathParameters['screenshotId']!,
        ),
      ),
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/crash',
        builder: (context, state) => CrashScreen(error: state.extra as String?),
      ),
    ],
  );
});
