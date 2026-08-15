import 'package:aperlo/widgets/adaptive_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/template.dart';
import '../../providers/app_providers.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';



const _categories = [
  'All', 'Minimal', 'Bold', 'Gradient', 'Dark', '3D Mockup', 
  'Illustration', 'Typography'
];

class TemplateBrowserScreen extends ConsumerStatefulWidget {
  const TemplateBrowserScreen({super.key, this.preselectedCollectionId});
  final String? preselectedCollectionId;

  @override
  ConsumerState<TemplateBrowserScreen> createState() => _TemplateBrowserScreenState();
}

class _TemplateBrowserScreenState extends ConsumerState<TemplateBrowserScreen> {

  final _categoryScrollCtrl = ScrollController();
  final _gridScrollCtrl = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _gridScrollCtrl.addListener(_onScroll);
  }

  void _onScroll() async {
    if (_gridScrollCtrl.position.pixels >= _gridScrollCtrl.position.maxScrollExtent - 200) {
      if (_isLoadingMore) return;
      final selectedCategory = ref.read(selectedCategoryProvider);
      final cat = selectedCategory == 'All' ? null : selectedCategory;
      final notifier = ref.read(templatesProvider(cat).notifier);
      
      if (notifier.hasMore) {
        setState(() => _isLoadingMore = true);
        await notifier.loadMore();
        if (mounted) setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  void dispose() {

    _categoryScrollCtrl.dispose();
    _gridScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final templatesAsync = ref.watch(templatesProvider(selectedCategory == 'All' ? null : selectedCategory));
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 960 ? 5 : (screenWidth > 720 ? 4 : (screenWidth > 480 ? 3 : (screenWidth < 340 ? 1 : 2)));
    final childAspectRatio = screenWidth < 340 ? 3 / 4 : 9 / 16;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Templates', style: AppText.headline1()),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // ── Category Tabs ──────────────────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: ListView.separated(
              controller: _categoryScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) => CategoryChip(
                label: _categories[i],
                isSelected: selectedCategory == _categories[i],
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = _categories[i],
              ),
            ),
          ),
          
          // ── Templates Grid ─────────────────────────────────────────────────
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.layoutGrid,
                    headline: 'No templates found',
                    description: 'We couldn\'t find any templates matching your criteria.',
                  );
                }

                return CustomScrollView(
                  controller: _gridScrollCtrl,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _TemplateCard(
                            template: templates[i],
                            preselectedCollectionId: widget.preselectedCollectionId,
                          ),
                          childCount: templates.length,
                        ),
                      ),
                    ),
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
                          child: Center(
                            child: SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.s16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: 6,
                itemBuilder: (context, _) => const SkeletonCard(),
              ),
              error: (e, _) => ErrorState(
                headline: 'Failed to load templates',
                description: 'We couldn\'t load the template library. Check your connection and try again.',
                onRetry: () => ref.invalidate(templatesProvider(selectedCategory == 'All' ? null : selectedCategory)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Template Card ────────────────────────────────────────────────────────────

class _TemplateCard extends ConsumerStatefulWidget {
  const _TemplateCard({required this.template, this.preselectedCollectionId});
  final Template template;
  final String? preselectedCollectionId;

  @override
  ConsumerState<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends ConsumerState<_TemplateCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final isNew = ref.watch(templateNewBadgeProvider(t));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go('/templates/${t.id}', extra: widget.preselectedCollectionId),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.br12,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.br12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
              if (t.thumbnailUrl.isNotEmpty)
                AdaptiveImage(
                  imageUrl: t.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: AppColors.surfaceMuted,
                  child: const Center(
                    child: Icon(LucideIcons.layoutGrid, size: 32, color: AppColors.inkDisabled)
                  ),
                ),

              // Gradient Overlay for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.r12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  t.name,
                  style: AppText.labelSmall(color: Colors.white).copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // PRO badge
              if (t.isPro)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: ProBadge(),
                ),

              // NEW badge
              if (isNew)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: NewBadge(),
                ),

              // Lock overlay for premium
              if (t.isPro)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inkPrimary.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.lock, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

            ],
            ),
          ),
        ),
      ),
    );
  }
}
