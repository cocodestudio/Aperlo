import 'dart:math' as math;
import 'package:aperlo/widgets/adaptive_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/collection.dart';
import '../../providers/app_providers.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/app_text_field.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 960 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        displacement: 80,
        onRefresh: () async {
          ref.invalidate(collectionsProvider);
          ref.invalidate(templatesProvider(null));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  topPad + AppSpacing.s20,
                  AppSpacing.s16,
                  AppSpacing.s8,
                ),
                child: Row(
                  children: [
                    // Logo mark
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Aperlo', style: AppText.headline1()),
                  ],
                ),
              ),
            ),

            // ── Continue working ─────────────────────────────────────────
            const SliverToBoxAdapter(child: _ContinueWorkingSection()),

            // ── Templates section header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20, AppSpacing.s24, AppSpacing.s8, AppSpacing.s12,
                ),
                child: _SectionHeader(
                  title: 'Featured templates',
                  onViewAll: () => context.go('/templates'),
                ),
              ),
            ),

            // ── Featured templates ────────────────────────────────────────
            const SliverToBoxAdapter(child: _FeaturedTemplatesSection()),

            // ── Collections section header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20, 28, AppSpacing.s8, AppSpacing.s12,
                ),
                child: _SectionHeader(
                  title: 'Collections',
                  onViewAll: () => context.go('/collections'),
                ),
              ),
            ),

            // ── Collections grid ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              sliver: collectionsAsync.when(
                data: (collections) => collections.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          icon: LucideIcons.folderPlus,
                          headline: 'Your first collection',
                          description:
                              'Collections keep your screenshots organised. Start one and your work lives here.',
                          actionLabel: 'New collection',
                          onAction: () => _showNewCollectionDialog(context, ref),
                        ),
                      )
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _CollectionCard(
                            collection: collections[i],
                          ),
                          childCount: collections.take(4).length,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 4 / 3,
                        ),
                      ),
                loading: () => SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const SkeletonBox(
                      width: null,
                      height: double.infinity,
                      radius: BorderRadius.all(Radius.circular(AppRadius.r12)),
                    ),
                    childCount: 4,
                  ),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 4 / 3,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(
                    headline: 'Failed to load collections',
                    description: 'We couldn\'t load your recent collections.',
                    onRetry: () => ref.invalidate(collectionsProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s64)),
          ],
        ),
      ),
    );
  }

  void _showNewCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('New collection', style: AppText.headline2()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: nameCtrl, hint: 'Collection name', autofocus: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final colorIdx = math.Random().nextInt(collectionColors.length);
              await ref.read(collectionsNotifierProvider.notifier).create(nameCtrl.text.trim(), colorIdx);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Create', style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Accent mark
        Container(
          width: 3,
          height: 16,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(title, style: AppText.headline3()),
        ),
        Material(
          color: AppColors.accentTint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              onViewAll();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: AppText.labelDefault(color: AppColors.accent).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ── Continue Working Section ─────────────────────────────────────────────────

class _ContinueWorkingSection extends ConsumerWidget {
  const _ContinueWorkingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(recentScreenshotsProvider);

    return screenshotsAsync.when(
      data: (shots) {
        if (shots.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s20, AppSpacing.s20, AppSpacing.s12,
              ),
              child: _SectionHeader(
                title: 'Continue working',
                onViewAll: () => context.go('/collections'),
              ),
            ),
            SizedBox(
              height: 140 * 16 / 9,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                physics: const BouncingScrollPhysics(),
                itemCount: shots.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) =>
                    _RecentScreenshotCard(screenshot: shots[i]),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

// ── Featured Templates Section ───────────────────────────────────────────────

class _FeaturedTemplatesSection extends ConsumerWidget {
  const _FeaturedTemplatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Templates horizontal list (latest 5)
        SizedBox(
          height: 160 * 16 / 9,
          child: templatesAsync.when(
            data: (templates) {
              final featured = templates.take(5).toList();
              if (featured.isEmpty) {
                return const Center(
                  child: Text('No templates'),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: featured.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _FeaturedTemplateCard(template: featured[i]),
              );
            },
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, _) =>
                  const SizedBox(width: 160, child: SkeletonCard()),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ── Collection Card ──────────────────────────────────────────────────────────

class _CollectionCard extends ConsumerStatefulWidget {
  const _CollectionCard({required this.collection});
  final Collection collection;

  @override
  ConsumerState<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends ConsumerState<_CollectionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    final screenshotsAsync = ref.watch(screenshotsProvider(c.id));

    Widget header = Container(
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.r12),
        ),
      ),
      child: Center(
        child: Icon(LucideIcons.folderOpen, size: 28, color: c.color),
      ),
    );

    screenshotsAsync.whenData((shots) {
      if (shots.isNotEmpty && shots.first.thumbnailUrl.isNotEmpty) {
        header = ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.r12),
          ),
          child: AdaptiveImage(
            key: ValueKey(shots.first.updatedAt.millisecondsSinceEpoch),
            imageUrl: shots.first.thumbnailUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      }
    });

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push('/collections/${c.id}'),
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
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(flex: 58, child: header),
              Expanded(
                flex: 42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
                        style: AppText.headline3().copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.image,
                            size: 11,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${c.screenshotCount} screenshot${c.screenshotCount != 1 ? 's' : ''}',
                              style: AppText.bodySmall(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

// ── Recent Screenshot Card ───────────────────────────────────────────────────

class _RecentScreenshotCard extends StatefulWidget {
  const _RecentScreenshotCard({required this.screenshot});
  final dynamic screenshot;

  @override
  State<_RecentScreenshotCard> createState() => _RecentScreenshotCardState();
}

class _RecentScreenshotCardState extends State<_RecentScreenshotCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.screenshot;
    return Semantics(
      button: true,
      label: 'Continue editing ${s.name}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => context.push('/editor/${s.id}'),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: 140,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppShadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: s.thumbnailUrl.isNotEmpty
                        ? AdaptiveImage(
                            key: ValueKey(s.updatedAt.millisecondsSinceEpoch),
                            imageUrl: s.thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: AppColors.surfaceMuted,
                            child: const Center(
                              child: Icon(
                                LucideIcons.image,
                                size: 28,
                                color: AppColors.inkDisabled,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Text(
                      s.name,
                      style: AppText.labelSmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

// ── Featured Template Card ───────────────────────────────────────────────────

class _FeaturedTemplateCard extends StatefulWidget {
  const _FeaturedTemplateCard({required this.template});
  final dynamic template;

  @override
  State<_FeaturedTemplateCard> createState() => _FeaturedTemplateCardState();
}

class _FeaturedTemplateCardState extends State<_FeaturedTemplateCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return Semantics(
      button: true,
      label: 'Use template ${t.name}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => context.go('/templates/${t.id}'),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: 160,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (t.thumbnailUrl.isNotEmpty)
                    AdaptiveImage(
                      imageUrl: t.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Center(
                      child: Icon(
                        LucideIcons.layoutGrid,
                        size: 28,
                        color: AppColors.inkDisabled,
                      ),
                    ),
                  if (t.isPro)
                    const Positioned(top: 8, right: 8, child: ProBadge()),
                  // Template name overlay at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.r12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        t.name ?? '',
                        style: AppText.labelSmall(color: Colors.white)
                            .copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
