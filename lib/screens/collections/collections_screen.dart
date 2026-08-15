import 'dart:math' as math;
import 'package:aperlo/widgets/adaptive_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../export/export_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/collection.dart';
import '../../providers/app_providers.dart';
import '../../widgets/badges.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/options_modal_sheet.dart';
import 'package:uuid/uuid.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

enum _SortMethod { all, recent, alphabetical }

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  _SortMethod _sortMethod = _SortMethod.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 960 ? 4 : (screenWidth > 600 ? 3 : (screenWidth < 340 ? 1 : 2));
    final childAspectRatio = screenWidth < 340 ? 1.5 : 0.98;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Collections', style: AppText.headline1()),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s16),
            child: _HeaderAction(
              icon: LucideIcons.plus,
              onTap: () => _showNewCollectionDialog(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filters ───────────────────────────────────────────────
          Container(
            color: AppColors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s12),
                  child: AppSearchField(
                    controller: _searchCtrl,
                    hint: 'Search collections...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Container(
                  height: 48,
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: 'All',
                          isSelected: _sortMethod == _SortMethod.all,
                          onTap: () => setState(() => _sortMethod = _SortMethod.all),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: 'Recent',
                          isSelected: _sortMethod == _SortMethod.recent,
                          onTap: () => setState(() => _sortMethod = _SortMethod.recent),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: 'Alphabetical',
                          isSelected: _sortMethod == _SortMethod.alphabetical,
                          onTap: () => setState(() => _sortMethod = _SortMethod.alphabetical),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Collections Grid ───────────────────────────────────────────────
          Expanded(
            child: collectionsAsync.when(
              data: (all) {
                var cols = all.where((c) =>
                  _search.isEmpty || c.name.toLowerCase().contains(_search.toLowerCase()),
                ).toList();
                
                if (_sortMethod == _SortMethod.alphabetical) {
                  cols.sort((a, b) => a.name.compareTo(b.name));
                } else {
                  // Recent or All: default is ordered by updatedAt descending from stream
                  cols.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                }

                if (cols.isEmpty) {
                  return EmptyState(
                    icon: _search.isNotEmpty ? LucideIcons.searchX : LucideIcons.folderPlus,
                    headline: _search.isNotEmpty ? 'No matches found' : 'Your first collection',
                    description: _search.isNotEmpty 
                        ? 'We couldn\'t find any collections matching your search.' 
                        : 'Collections keep your screenshots organised. Start one and your work lives here.',
                    actionLabel: _search.isNotEmpty ? null : 'New collection',
                    onAction: _search.isNotEmpty ? null : () => _showNewCollectionDialog(context),
                  );
                }

                return CustomScrollView(
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
                          (context, i) => _CollectionGridCard(collection: cols[i]),
                          childCount: cols.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => GridView.count(
                padding: const EdgeInsets.all(AppSpacing.s16),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: List.generate(6, (_) => const SkeletonBox(width: null, height: double.infinity, radius: BorderRadius.all(Radius.circular(AppRadius.r12)))),
              ),
              error: (e, _) => ErrorState(
                headline: 'Failed to load collections',
                description: 'We couldn\'t load your collections. Check your connection and try again.',
                onRetry: () => ref.invalidate(collectionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewCollectionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('New collection', style: AppText.headline2()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameCtrl, hint: 'Collection name', autofocus: true),
            ],
          ),
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

// ── Header action button ─────────────────────────────────────────────────────

class _HeaderAction extends StatefulWidget {
  const _HeaderAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _pressed ? AppColors.surfaceMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed ? AppColors.borderDefault : AppColors.borderSubtle,
          ),
          boxShadow: _pressed ? AppShadows.subtle : AppShadows.none,
        ),
        child: Icon(widget.icon, size: 20, color: AppColors.inkSecondary),
      ),
    );
  }
}

// ── Collection Card ──────────────────────────────────────────────────────────

class _CollectionGridCard extends ConsumerStatefulWidget {
  const _CollectionGridCard({required this.collection});
  final Collection collection;

  @override
  ConsumerState<_CollectionGridCard> createState() => _CollectionGridCardState();
}

class _CollectionGridCardState extends ConsumerState<_CollectionGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    final screenshotsAsync = ref.watch(screenshotsProvider(c.id));
    
    Widget header = Container(
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r12)),
      ),
      child: Center(child: Icon(LucideIcons.folderOpen, size: 28, color: c.color)),
    );

    screenshotsAsync.whenData((shots) {
      if (shots.isNotEmpty && shots.first.thumbnailUrl.isNotEmpty) {
        header = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r12)),
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
      onLongPress: () => _showContextMenu(context),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: header),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.name,
                      style: AppText.headline3().copyWith(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(LucideIcons.image, size: 11, color: AppColors.inkMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${c.screenshotCount} screenshot${c.screenshotCount != 1 ? 's' : ''}',
                            style: AppText.bodySmall().copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final c = widget.collection;
    final count = c.screenshotIds.length;
    final color = c.color;

    AppOptionsModalSheet.show(
      context,
      title: c.name,
      subtitle: '$count screenshot${count != 1 ? 's' : ''}',
      headerIcon: LucideIcons.folder,
      headerColor: color,
      actions: [
        AppOptionAction(
          label: 'Open collection',
          description: 'View screenshots and templates',
          icon: LucideIcons.folderOpen,
          isPrimary: true,
          onTap: () => context.push('/collections/${c.id}'),
        ),
        AppOptionAction(
          label: 'Rename',
          description: 'Change collection title',
          icon: LucideIcons.pencil,
          onTap: () => _showRenameDialog(context),
        ),
        AppOptionAction(
          label: 'Duplicate',
          description: 'Create an exact clone',
          icon: LucideIcons.copy,
          onTap: _duplicate,
        ),
        AppOptionAction(
          label: 'Export all',
          description: 'Export all screenshots at full resolution',
          icon: LucideIcons.download,
          badgeText: count > 0 ? '$count items' : null,
          onTap: () {
            if (widget.collection.screenshotIds.isEmpty) {
              AppToast.show(context, message: 'Collection is empty', type: AppToastType.info);
              return;
            }
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => ExportSheet(
                screenshotId: widget.collection.screenshotIds.first,
                screenshotIds: widget.collection.screenshotIds,
              ),
            );
          },
        ),
        AppOptionAction(
          label: 'Delete collection',
          description: 'Permanently delete this collection and its screenshots',
          icon: LucideIcons.trash2,
          isDestructive: true,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: widget.collection.name);
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Rename collection', style: AppText.headline2()),
        content: AppTextField(controller: ctrl, hint: 'Collection name', autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx);
              await ref.read(collectionsNotifierProvider.notifier).rename(widget.collection, name);
            },
            child: Text('Save', style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicate() async {
    final name = '${widget.collection.name} copy';
    int colorIdx = collectionColors.indexOf(widget.collection.color);
    if (colorIdx == -1) colorIdx = 0;
    
    final newCol = await ref.read(collectionsNotifierProvider.notifier).create(
      name,
      colorIdx,
    );
    
    final db = ref.read(localDataServiceProvider);
    final screenshots = db.getScreenshots(widget.collection.id);
    
    List<String> newScreenshotIds = [];
    for (var s in screenshots) {
      final newId = const Uuid().v4();
      newScreenshotIds.add(newId);
      final newS = s.copyWith(
        id: newId,
        collectionId: newCol.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.saveScreenshot(newS);
    }
    
    if (newScreenshotIds.isNotEmpty) {
      await db.saveCollection(newCol.copyWith(
        screenshotIds: newScreenshotIds,
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Delete collection?', style: AppText.headline2()),
        content: Text('This will delete "${widget.collection.name}" and all its screenshots. This cannot be undone.', style: AppText.bodyDefault()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(collectionsNotifierProvider.notifier).delete(widget.collection);
            },
            child: Text('Delete', style: AppText.labelLarge(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}
