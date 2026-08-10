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
import '../../models/screenshot.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../export/export_screen.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_text_field.dart';
import 'package:uuid/uuid.dart';

class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final screenshotsAsync = ref.watch(screenshotsProvider(collectionId));
    final collection = collectionsAsync.valueOrNull?.where((c) => c.id == collectionId).firstOrNull;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 960 ? 5 : (screenWidth > 720 ? 4 : (screenWidth > 480 ? 3 : 2));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(collection?.name ?? '', style: AppText.headline1()),
            if (screenshotsAsync.valueOrNull != null)
              Text(
                '${screenshotsAsync.valueOrNull!.length} screenshot${screenshotsAsync.valueOrNull!.length != 1 ? 's' : ''}',
                style: AppText.bodySmall(color: AppColors.inkMuted),
              ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s16),
            child: _HeaderAction(
              icon: LucideIcons.ellipsis,
              onTap: () => _showCollectionMenu(context, ref, collection?.name ?? ''),
            ),
          ),
        ],
      ),
      floatingActionButton: (screenshotsAsync.valueOrNull ?? []).isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/templates', extra: collectionId),
              backgroundColor: AppColors.accent,
              elevation: 4,
              highlightElevation: 8,
              shape: const CircleBorder(),
              child: const Icon(LucideIcons.plus, color: AppColors.accentOn),
            ),
      body: screenshotsAsync.when(
        data: (shots) => shots.isEmpty
            ? EmptyState(
                icon: LucideIcons.imagePlus,
                headline: 'No screenshots yet',
                description: 'Add a template to start creating screenshots for this collection.',
                actionLabel: 'Browse templates',
                onAction: () => context.go('/templates', extra: collectionId),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 9 / 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ScreenshotCard(screenshot: shots[i]),
                        childCount: shots.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.s64), // Space for FAB
                  ),
                ],
              ),
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.s16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 9 / 16,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const SkeletonCard(),
        ),
        error: (e, _) => ErrorState(
          headline: 'Failed to load screenshots',
          description: 'We couldn\'t load screenshots for this collection. Please try again.',
          onRetry: () => ref.invalidate(screenshotsProvider(collectionId)),
        ),
      ),
    );
  }

  void _showCollectionMenu(BuildContext context, WidgetRef ref, String currentName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: AppRadius.brFull)
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.pencil),
                title: Text('Rename', style: AppText.labelLarge()),
                onTap: () {
                  Navigator.pop(sheetCtx); 
                  _showRenameDialog(context, ref, currentName);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.download),
                title: Text('Export all', style: AppText.labelLarge()),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final col = ref.read(collectionsProvider).valueOrNull?.where((c) => c.id == collectionId).firstOrNull;
                  if (col == null || col.screenshotIds.isEmpty) {
                    AppToast.show(context, message: 'Collection is empty', type: AppToastType.info);
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ExportSheet(
                      screenshotId: col.screenshotIds.first,
                      screenshotIds: col.screenshotIds,
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Divider(),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.trash2, color: AppColors.destructive),
                title: Text('Delete collection', style: AppText.labelLarge(color: AppColors.destructive)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete(context, ref);
                },
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      useRootNavigator: false,
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
              final col = ref.read(collectionsProvider).valueOrNull
                  ?.where((c) => c.id == collectionId).firstOrNull;
              Navigator.pop(dialogCtx); 
              if (col != null) {
                await ref.read(collectionsNotifierProvider.notifier).rename(col, name);
              }
            },
            child: Text('Save', style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Delete collection?', style: AppText.headline2()),
        content: Text(
          'This will delete the collection and all its screenshots. This cannot be undone.',
          style: AppText.bodyDefault(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              final col = ref.read(collectionsProvider).valueOrNull
                  ?.where((c) => c.id == collectionId).firstOrNull;
              Navigator.pop(dialogCtx); 
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
              if (col != null) {
                await ref.read(collectionsNotifierProvider.notifier).delete(col);
              }
            },
            child: Text('Delete', style: AppText.labelLarge(color: AppColors.destructive)),
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
          color: _pressed ? AppColors.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed ? AppColors.borderDefault : Colors.transparent,
          ),
        ),
        child: Icon(widget.icon, size: 20, color: AppColors.inkSecondary),
      ),
    );
  }
}

// ── Screenshot Card ──────────────────────────────────────────────────────────

class _ScreenshotCard extends ConsumerStatefulWidget {
  const _ScreenshotCard({required this.screenshot});
  final Screenshot screenshot;

  @override
  ConsumerState<_ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends ConsumerState<_ScreenshotCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.screenshot;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push('/editor/${s.id}'),
      onLongPress: () => _showContextMenu(context),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.br12,
            boxShadow: AppShadows.card,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              s.thumbnailUrl.isNotEmpty
                  ? AdaptiveImage(
                      key: ValueKey(s.updatedAt.millisecondsSinceEpoch),
                      imageUrl: s.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : const Center(
                      child: Icon(LucideIcons.image, size: 32, color: AppColors.inkDisabled),
                    ),
              
              // Gradient Overlay
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
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),

              // Screenshot name
              Positioned(
                left: 12, 
                right: 12, 
                bottom: 12,
                child: Text(
                  s.name,
                  style: AppText.labelSmall(color: Colors.white).copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _duplicateScreenshot() async {
    final s = widget.screenshot;
    final newId = const Uuid().v4();
    final newS = s.copyWith(
      id: newId,
      name: '${s.name} copy',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final db = ref.read(localDataServiceProvider);
    await db.saveScreenshot(newS);
    
    final col = ref.read(collectionsProvider).valueOrNull?.where((c) => c.id == s.collectionId).firstOrNull;
    if (col != null) {
      await ref.read(collectionsNotifierProvider.notifier).addScreenshot(col, newId);
    }
  }

  void _showContextMenu(BuildContext context) {
    final s = widget.screenshot;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: AppRadius.brFull)
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.pencil),
                title: Text('Rename', style: AppText.labelLarge()),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showRenameDialog(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.download),
                title: Text('Export', style: AppText.labelLarge()),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ExportSheet(screenshotId: s.id),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.copy),
                title: Text('Duplicate', style: AppText.labelLarge()),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _duplicateScreenshot();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Divider(),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                leading: const Icon(LucideIcons.trash2, color: AppColors.destructive),
                title: Text('Delete', style: AppText.labelLarge(color: AppColors.destructive)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete(context);
                },
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: widget.screenshot.name);
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Rename screenshot', style: AppText.headline2()),
        content: AppTextField(controller: ctrl, hint: 'Screenshot name', autofocus: true),
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
              final updated = widget.screenshot.copyWith(
                name: name,
                updatedAt: DateTime.now(),
              );
              await ref.read(screenshotsNotifierProvider.notifier).save(updated);
            },
            child: Text('Save', style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Delete screenshot?', style: AppText.headline2()),
        content: Text('This cannot be undone.', style: AppText.bodyDefault()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              final s = widget.screenshot;
              final col = ref.read(collectionsProvider).valueOrNull
                  ?.where((c) => c.id == s.collectionId).firstOrNull;
              Navigator.pop(dialogCtx);
              
              if (col != null) {
                await ref.read(collectionsNotifierProvider.notifier).removeScreenshot(col, s.id);
              }
              await ref.read(screenshotsNotifierProvider.notifier).delete(s.id);
            },
            child: Text('Delete', style: AppText.labelLarge(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}
