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

/// Returns the dynamic bottom clearance needed so that Floating Action Buttons (FABs)
/// and scrolling lists comfortably clear the floating bottom navigation bar and
/// the phone's system navigation bar on all devices.
double getFloatingBottomNavClearance(BuildContext context) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  return kFloatingBottomNavHeight + kFloatingBottomNavMargin + bottomInset + 16.0;
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
        body: SafeArea(
          top: false,
          bottom: true,
          child: widget.navigationShell,
        ),
        bottomNavigationBar: _BottomNav(
          activeIndex: widget.navigationShell.currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer(
      {super.key, required this.currentIndex, required this.children});
  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentIndex;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (index) {
        if (index == _currentIndex) {
          // Slide in
          final isMovingRight = _currentIndex > _previousIndex;
          final offset = Tween<Offset>(
            begin: Offset(isMovingRight ? 1.0 : -1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: _controller, curve: Curves.easeOutCubic));

          return SlideTransition(
            position: offset,
            child: widget.children[index],
          );
        } else if (index == _previousIndex && _controller.isAnimating) {
          // Slide out
          final isMovingRight = _currentIndex > _previousIndex;
          final offset = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(isMovingRight ? -1.0 : 1.0, 0.0),
          ).animate(CurvedAnimation(
              parent: _controller, curve: Curves.easeOutCubic));

          return SlideTransition(
            position: offset,
            child: widget.children[index],
          );
        } else {
          // Hidden
          return Offstage(
            offstage: true,
            child: widget.children[index],
          );
        }
      }),
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
    );
  }
}
