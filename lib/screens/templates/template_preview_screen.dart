import 'dart:math' as math;
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
import '../../models/collection.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/badges.dart';

class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({super.key, required this.templateId, this.preselectedCollectionId});
  final String templateId;
  final String? preselectedCollectionId;

  @override
  ConsumerState<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  late String _currentId = widget.templateId;

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(_templateDetailProvider(_currentId));
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          templateAsync.when(
            data: (template) => template == null
                ? const Center(child: Text('Template not found'))
                : _TemplatePreviewBody(
                    template: template,
                    preselectedCollectionId: widget.preselectedCollectionId,
                    onTemplateSelected: (id) => setState(() => _currentId = id),
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (e, _) => Center(child: Text('$e', style: AppText.bodyDefault())),
          ),
          
          // ── Top Navigation Bar ─────────────────────────────────────────────
          Positioned(
            top: topPad + AppSpacing.s12,
            left: AppSpacing.s16,
            right: AppSpacing.s16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                _GlassIconButton(
                  icon: LucideIcons.share2,
                  onTap: () {
                    AppToast.show(context, message: 'Sharing coming soon', type: AppToastType.info);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _templateDetailProvider = FutureProvider.family<Template?, String>((ref, id) async {
  return ref.watch(firestoreServiceProvider).getTemplate(id);
});

// ── Glass Icon Button ────────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Template Preview Body ────────────────────────────────────────────────────

class _TemplatePreviewBody extends ConsumerStatefulWidget {
  const _TemplatePreviewBody({required this.template, this.preselectedCollectionId, required this.onTemplateSelected});
  final Template template;
  final String? preselectedCollectionId;
  final void Function(String id) onTemplateSelected;

  @override
  ConsumerState<_TemplatePreviewBody> createState() => _TemplatePreviewBodyState();
}

class _TemplatePreviewBodyState extends ConsumerState<_TemplatePreviewBody> {
  bool _loading = false;

  Future<void> _useTemplate() async {
    final collections = ref.read(collectionsProvider).valueOrNull ?? [];

    if (widget.preselectedCollectionId != null) {
      final col = collections.firstWhere(
        (c) => c.id == widget.preselectedCollectionId,
        orElse: () => collections.first,
      );
      await _createScreenshotInCollection(col.id, col.screenshotCount);
      return;
    }

    if (collections.isEmpty) {
      final newName = await _showCreateCollectionDialog();
      if (newName == null || !mounted) return;
      setState(() => _loading = true);
      try {
        final colorIdx = math.Random().nextInt(collectionColors.length);
        final newCol = await ref.read(collectionsNotifierProvider.notifier).create(newName, colorIdx);
        await _createScreenshotInCollection(newCol.id, 0);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CollectionPickerSheet(collections: collections),
    );
    if (selected == null || !mounted) return;

    final col = collections.firstWhere((c) => c.id == selected);
    await _createScreenshotInCollection(selected, col.screenshotCount);
  }

  Future<void> _createScreenshotInCollection(String collectionId, int count) async {
    setState(() => _loading = true);
    try {
      final collections = ref.read(collectionsProvider).valueOrNull ?? [];
      final col = collections.firstWhere((c) => c.id == collectionId);
      final screenshot = await ref.read(screenshotsNotifierProvider.notifier).create(
        collectionId: collectionId,
        templateId: widget.template.id,
        name: 'Screenshot ${count + 1}',
        order: count,
      );
      await ref.read(collectionsNotifierProvider.notifier).addScreenshot(col, screenshot.id);
      if (mounted) context.push('/editor/${screenshot.id}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showCreateCollectionDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('Create a collection', style: AppText.headline2()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Collection name',
            border: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 2)),
          ),
          style: AppText.bodyDefault(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted))),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx, name);
            },
            child: Text('Create', style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    // Template thumbnails are portrait (9:16). We give the image area a fixed
    // height based on the screen width so the full image fits without cropping.
    final imageAreaHeight = size.width * (16 / 9);
    // Cap it so we always leave room for the handle + title on smaller screens
    final clampedImageHeight = imageAreaHeight.clamp(0.0, size.height * 0.72);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // ── Full-visible thumbnail area ────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: clampedImageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Subtle muted background behind the image
                Container(color: AppColors.surfaceMuted),
                if (template.thumbnailUrl.isNotEmpty)
                  AdaptiveImage(
                    imageUrl: template.thumbnailUrl,
                    fit: BoxFit.contain,
                  )
                else
                  const Center(
                    child: Icon(LucideIcons.layoutGrid, size: 80, color: AppColors.inkDisabled),
                  ),

                // Top gradient fade so nav buttons are readable
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: topPad + 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Info + actions panel ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s20, AppSpacing.s24, AppSpacing.s40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle (visual only — the page itself is scrollable)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.s20),
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: AppRadius.brFull,
                    ),
                  ),
                ),

                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.name, style: AppText.headline1()),
                          const SizedBox(height: AppSpacing.s8),
                          Row(
                            children: [
                              CategoryChip(label: template.category, isSelected: false),
                              const SizedBox(width: 8),
                              CategoryChip(
                                label: template.deviceType.name == 'tablet'
                                    ? 'Tablet'
                                    : template.deviceType.name == 'desktop'
                                        ? 'Desktop'
                                        : 'Phone',
                                isSelected: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (template.isPro)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.s12),
                        child: ProBadge(),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s20),
                Text(
                  template.description,
                  style: AppText.bodyDefault(color: AppColors.inkSecondary),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.s32),

                if (template.isPro)
                  AppButton(
                    label: 'Unlock with PRO',
                    onPressed: () => AppToast.show(context, message: 'PRO feature coming soon', type: AppToastType.info),
                    leadingIcon: const Icon(LucideIcons.lock, size: 20),
                    isFullWidth: true,
                  )
                else
                  AppButton(
                    label: 'Use template',
                    onPressed: _loading ? null : _useTemplate,
                    isLoading: _loading,
                    isFullWidth: true,
                  ),

                const SizedBox(height: AppSpacing.s40),

                // More like this
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('More like this', style: AppText.headline3()),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),

                SizedBox(
                  height: 180 * 16 / 9,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final suggestedAsync = ref.watch(templatesProvider(template.category));
                      return suggestedAsync.when(
                        data: (templates) {
                          final suggested = templates.where((t) => t.id != template.id).take(5).toList();
                          if (suggested.isEmpty) {
                            return Text('No suggestions found.', style: AppText.bodySmall(color: AppColors.inkMuted));
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            itemCount: suggested.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final t = suggested[i];
                              return GestureDetector(
                                onTap: () => widget.onTemplateSelected(t.id),
                                child: Container(
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: AppRadius.br12,
                                    border: Border.all(color: AppColors.borderSubtle),
                                    boxShadow: AppShadows.card,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (t.thumbnailUrl.isNotEmpty)
                                        AdaptiveImage(imageUrl: t.thumbnailUrl, fit: BoxFit.cover)
                                      else
                                        Container(
                                          color: AppColors.surfaceMuted,
                                          child: const Center(
                                            child: Icon(LucideIcons.layoutGrid, size: 28, color: AppColors.inkDisabled),
                                          ),
                                        ),
                                      if (t.isPro)
                                        const Positioned(top: 8, right: 8, child: ProBadge()),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                        error: (_, _) => const SizedBox(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom safe-area padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
      ],
    );
  }
}

// ── Collection Picker Sheet ──────────────────────────────────────────────────

class _CollectionPickerSheet extends StatelessWidget {
  const _CollectionPickerSheet({required this.collections});
  final List collections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.s12),
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: AppRadius.brFull)
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Text('Add to collection', style: AppText.headline2()),
            ),
            const SizedBox(height: AppSpacing.s12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                itemCount: collections.length,
                itemBuilder: (context, i) {
                  final c = collections[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.br12),
                      tileColor: AppColors.surfaceMuted,
                      leading: CircleAvatar(
                        backgroundColor: c.color.withValues(alpha: 0.15),
                        radius: 20,
                        child: Icon(LucideIcons.folderOpen, color: c.color, size: 20),
                      ),
                      title: Text(c.name, style: AppText.labelLarge()),
                      subtitle: Text('${c.screenshotCount} screenshots', style: AppText.bodySmall(color: AppColors.inkMuted)),
                      onTap: () => Navigator.pop(context, c.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ),
      ),
    );
  }
}
