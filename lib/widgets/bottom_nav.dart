import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

const double kFloatingBottomNavHeight = 60.0;
const double kFloatingBottomNavMargin = 12.0;

/// Returns the dynamic bottom clearance needed for scrolling lists and content
/// to comfortably scroll past the floating bottom navigation bar.
double getFloatingBottomNavClearance(BuildContext context) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  return kFloatingBottomNavHeight + kFloatingBottomNavMargin + bottomInset + 16.0;
}

/// Returns the bottom clearance needed specifically for Scaffold Floating Action Buttons (FABs)
/// so they float cleanly with a comfortable gap above the floating bottom navigation bar.
double getFloatingBottomNavFabClearance(BuildContext context) {
  return kFloatingBottomNavHeight + kFloatingBottomNavMargin + 10.0;
}

const _tabs = [
  _TabItem(label: 'Home', icon: LucideIcons.house, route: '/home'),
  _TabItem(label: 'Templates', icon: LucideIcons.layoutGrid, route: '/templates'),
  _TabItem(label: 'Collections', icon: LucideIcons.folderOpen, route: '/collections'),
];

class _TabItem {
  const _TabItem({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<int> _tabHistory = [0];

  void _onTabTapped(int index) {
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
    } else {
      setState(() {
        _tabHistory.remove(index);
        _tabHistory.add(index);
      });
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
          });
          widget.navigationShell.goBranch(_tabHistory.last);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: _BottomNav(
          activeIndex: widget.navigationShell.currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activeIndex, required this.onTap});
  final int activeIndex;
  final void Function(int) onTap;

  static const double _padding = 5.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBottomOffset = kFloatingBottomNavMargin + bottomInset;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: EdgeInsets.fromLTRB(20, 0, 20, navBottomOffset),
        height: kFloatingBottomNavHeight,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: AppRadius.brFull,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          boxShadow: AppShadows.float,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.brFull,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - (_padding * 2);
              final tabWidth = availableWidth / _tabs.length;
              final pillHeight = constraints.maxHeight - (_padding * 2);

              return Stack(
                children: [
                  // Inner sliding pill container for active tab
                  AnimatedPositioned(
                    duration: AppMotion.base,
                    curve: AppMotion.easeOut,
                    left: _padding + (activeIndex * tabWidth),
                    top: _padding,
                    width: tabWidth,
                    height: pillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.brFull,
                        boxShadow: AppShadows.subtle,
                      ),
                    ),
                  ),
                  // Row of interactive tab items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _padding),
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        return SizedBox(
                          width: tabWidth,
                          height: constraints.maxHeight,
                          child: _NavItem(
                            tab: _tabs[i],
                            isActive: i == activeIndex,
                            onTap: () => onTap(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.accentOn;
    final inactiveColor = AppColors.inkMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        splashColor: isActive
            ? Colors.transparent
            : AppColors.accent.withValues(alpha: 0.14),
        highlightColor: isActive
            ? Colors.transparent
            : AppColors.accent.withValues(alpha: 0.06),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Icon(
                      tab.icon,
                      key: ValueKey('${tab.label}_$isActive'),
                      size: 20,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    style: AppText.labelSmall(
                      color: isActive ? activeColor : inactiveColor,
                    ).copyWith(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    child: Text(tab.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
