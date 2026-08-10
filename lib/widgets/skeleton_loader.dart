import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double? width;
  final double height;
  final BorderRadius? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: widget.radius ?? AppRadius.br6,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1.5, -0.5),
            end: const Alignment(1.5, 0.5),
            colors: [
              AppColors.surfaceMuted,
              Color.lerp(AppColors.surfaceMuted, AppColors.surfaceRaised, _shimmer.value)!,
              AppColors.surfaceMuted,
            ],
          ),
          borderRadius: widget.radius ?? AppRadius.br6,
        ),
      ),
    );
  }
}

/// Card-shaped skeleton for template/screenshot grids
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.aspectRatio = 9 / 16});
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: SkeletonBox(width: null, height: double.infinity, radius: AppRadius.br12),
    );
  }
}
