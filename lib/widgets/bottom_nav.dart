import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

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
        body: widget.navigationShell,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: AppShadows.subtleUp,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              return Expanded(
                child: _NavItem(
                  tab: _tabs[i],
                  isActive: i == activeIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.tab, required this.isActive, required this.onTap});
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: AppMotion.fast);
    _scale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: AppMotion.spring));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      if (!MediaQuery.of(context).disableAnimations) {
        _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
      }
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.accent : AppColors.inkMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator pill — 4×28, above icon
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.easeInOut,
            width: widget.isActive ? 28 : 0,
            height: 4,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: AppRadius.br2,
            ),
          ),
          ScaleTransition(
            scale: _scale,
            child: Icon(widget.tab.icon, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            widget.tab.label,
            style: widget.isActive
                ? AppText.labelSmall(color: AppColors.accent).copyWith(fontWeight: FontWeight.w600)
                : AppText.labelSmall(),
          ),
        ],
      ),
    );
  }
}
