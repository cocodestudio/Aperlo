import 'dart:math' as math;
import 'package:aperlo/widgets/adaptive_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../widgets/empty_state.dart';
import '../../widgets/app_text_field.dart';

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

final _templateDetailProvider = FutureProvider.family<Template?, String>((ref, id) async {
  try {
    // 1. Check if template is already loaded in templates list
    final allLoaded = ref.read(templatesProvider(null)).valueOrNull ?? [];
    final found = allLoaded.firstWhereOrNull((t) => t.id == id);
    if (found != null) return found;

    // 2. Fetch directly from Firestore service
    return await ref.read(firestoreServiceProvider).getTemplate(id);
  } catch (e) {
    debugPrint('Error loading template $id: $e');
    final allLoaded = ref.read(templatesProvider(null)).valueOrNull ?? [];
    return allLoaded.firstWhereOrNull((t) => t.id == id);
  }
});

class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({super.key, required this.templateId, this.preselectedCollectionId});
  final String templateId;
  final String? preselectedCollectionId;

  @override
  ConsumerState<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  late String _currentId = widget.templateId;

  void _openFullscreenViewer(String? imageUrl, String templateId) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Hero(
                  tag: 'template_thumb_$templateId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AdaptiveImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(_templateDetailProvider(_currentId));

    return templateAsync.when(
      data: (template) {
        if (template == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.inkPrimary),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            body: const EmptyState(
              headline: 'Template not found',
              description: 'The template you requested is no longer available or was removed.',
              icon: LucideIcons.fileQuestion,
            ),
          );
        }

        return _TemplatePreviewView(
          template: template,
          preselectedCollectionId: widget.preselectedCollectionId,
          onTemplateSelected: (id) => setState(() => _currentId = id),
          onOpenFullscreen: () => _openFullscreenViewer(template.thumbnailUrl, template.id),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.inkPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        body: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.inkPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        body: ErrorState(
          headline: 'Failed to load template',
          description: 'We couldn\'t load the template details. Please try again.',
          onRetry: () => ref.invalidate(_templateDetailProvider(_currentId)),
        ),
      ),
    );
  }
}

// ── Template Preview View ────────────────────────────────────────────────────

class _TemplatePreviewView extends ConsumerStatefulWidget {
  const _TemplatePreviewView({
    required this.template,
    this.preselectedCollectionId,
    required this.onTemplateSelected,
    required this.onOpenFullscreen,
  });

  final Template template;
  final String? preselectedCollectionId;
  final void Function(String id) onTemplateSelected;
  final VoidCallback onOpenFullscreen;

  @override
  ConsumerState<_TemplatePreviewView> createState() => _TemplatePreviewViewState();
}

class _TemplatePreviewViewState extends ConsumerState<_TemplatePreviewView> {
  bool _loading = false;

  void _shareTemplate() {
    HapticFeedback.selectionClick();
    final url = 'https://aperlo.cocodestudio.com/template/${widget.template.id}';
    final text = 'Check out "${widget.template.name}" template on Aperlo:\n$url';
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: widget.template.name,
      ),
    );
  }

  Future<void> _useTemplate() async {
    final collections = ref.read(collectionsProvider).valueOrNull ?? [];

    // If navigated from a specific collection, directly use that collection without prompting
    if (widget.preselectedCollectionId != null && widget.preselectedCollectionId!.isNotEmpty) {
      final targetId = widget.preselectedCollectionId!;
      final col = collections.firstWhereOrNull((c) => c.id == targetId) ?? 
                  ref.read(localDataServiceProvider).getCollection(targetId);
      await _createScreenshotInCollection(targetId, col);
      return;
    }

    if (collections.isEmpty) {
      final newName = await _showCreateCollectionDialog();
      if (newName == null || !mounted) return;
      setState(() => _loading = true);
      try {
        final colorIdx = math.Random().nextInt(collectionColors.length);
        final newCol = await ref.read(collectionsNotifierProvider.notifier).create(newName, colorIdx);
        await _createScreenshotInCollection(newCol.id, newCol);
      } catch (e) {
        if (mounted) AppToast.show(context, message: 'Failed to create collection', type: AppToastType.error);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _CollectionPickerSheet(
        collections: collections,
        onCreateNew: () async {
          final newName = await _showCreateCollectionDialog();
          if (newName != null && mounted) {
            final colorIdx = math.Random().nextInt(collectionColors.length);
            final newCol = await ref.read(collectionsNotifierProvider.notifier).create(newName, colorIdx);
            if (mounted) Navigator.pop(context, newCol.id);
          }
        },
      ),
    );
    if (selectedId == null || !mounted) return;

    final col = collections.firstWhereOrNull((c) => c.id == selectedId) ?? 
                ref.read(localDataServiceProvider).getCollection(selectedId);
    await _createScreenshotInCollection(selectedId, col);
  }

  Future<void> _createScreenshotInCollection(String collectionId, [Collection? collectionData]) async {
    setState(() => _loading = true);
    try {
      Collection? col = collectionData;
      if (col == null) {
        final collections = ref.read(collectionsProvider).valueOrNull ?? [];
        col = collections.firstWhereOrNull((c) => c.id == collectionId) ??
              ref.read(localDataServiceProvider).getCollection(collectionId);
      }

      final count = col?.screenshotCount ?? 0;
      final screenshot = await ref.read(screenshotsNotifierProvider.notifier).create(
        collectionId: collectionId,
        templateId: widget.template.id,
        name: 'Screenshot ${count + 1}',
        order: count,
      );

      if (col != null) {
        await ref.read(collectionsNotifierProvider.notifier).addScreenshot(col, screenshot.id);
      }

      // Increment totalUses for this template in Firestore in the background
      ref.read(firestoreServiceProvider).incrementTemplateUses(widget.template.id);

      if (mounted) context.push('/editor/${screenshot.id}');
    } catch (e, stack) {
      debugPrint('Error creating screenshot: $e\n$stack');
      if (mounted) {
        AppToast.show(context, message: 'Failed to create screenshot', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showCreateCollectionDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        title: Text('New collection', style: AppText.headline2()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: ctrl, hint: 'Collection name', autofocus: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppText.labelLarge(color: AppColors.inkMuted)),
          ),
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

    // ── Dynamic Spec Calculations ──────────────────────────────────────────
    final isTablet = template.deviceType == DeviceType.tablet;
    final isDesktop = template.deviceType == DeviceType.desktop;
    final formatValue = isTablet
        ? '3:4 Tablet'
        : isDesktop
            ? '16:9 Desktop'
            : '9:16 Portrait';
    final formatSub = isTablet
        ? '2048 × 2732 px'
        : isDesktop
            ? '2880 × 1800 px'
            : '1242 × 2688 px';
    final formatIcon = isTablet
        ? LucideIcons.tablet
        : isDesktop
            ? LucideIcons.monitor
            : LucideIcons.smartphone;

    // Aspect ratio & responsive hero dimensions
    final aspectRatio = isTablet ? (3.0 / 4.0) : isDesktop ? (16.0 / 10.0) : (9.0 / 16.0);
    final heroHeight = (size.height * 0.42).clamp(240.0, 400.0);
    final heroWidth = (heroHeight * aspectRatio).clamp(160.0, size.width - 64.0);

    // Typography calculation
    final usedFonts = template.usedFonts;
    final typographyValue = template.typographyDisplay;
    final typographySub = usedFonts.length == 1
        ? 'Google Font'
        : '${usedFonts.length} Google Fonts';

    // Screenshots slot calculation
    final layoutDeviceCount = template.layout.where((l) {
      final type = l['type'] as String? ?? '';
      return type == 'phone' || type == 'image' || type == 'mockup';
    }).length;
    final slotsCount = template.screenshotSlots > 0
        ? template.screenshotSlots
        : (layoutDeviceCount > 0 ? layoutDeviceCount : 1);
    final slotsValue = '$slotsCount ${slotsCount == 1 ? 'Device Slot' : 'Device Slots'}';
    final slotsSub = slotsCount == 1 ? 'Single Device Focus' : '$slotsCount Multi-Device Flow';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _HeaderCircleButton(
            icon: LucideIcons.arrowLeft,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        title: Text(
          'Template Details',
          style: AppText.headline3().copyWith(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _HeaderCircleButton(
              icon: LucideIcons.maximize2,
              onTap: widget.onOpenFullscreen,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s8,
          AppSpacing.s20,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Floating Hero Showcase Stage ────────────────────────────
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                  borderRadius: AppRadius.br20,
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Column(
                  children: [
                    // Floating Canvas Card
                    GestureDetector(
                      onTap: widget.onOpenFullscreen,
                      child: Hero(
                        tag: 'template_thumb_${template.id}',
                        child: Container(
                          width: heroWidth,
                          height: heroHeight,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                blurRadius: 26,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (template.thumbnailUrl.isNotEmpty)
                                AdaptiveImage(
                                  imageUrl: template.thumbnailUrl,
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.layoutGrid,
                                      size: 48,
                                      color: AppColors.inkDisabled,
                                    ),
                                  ),
                                ),

                              // Pro Badge Top Right
                              if (template.isPro)
                                const Positioned(
                                  top: 10,
                                  right: 10,
                                  child: ProBadge(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Interactive Tap to Zoom Pill
                    GestureDetector(
                      onTap: widget.onOpenFullscreen,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.brFull,
                          border: Border.all(color: AppColors.borderSubtle, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.zoomIn, size: 13, color: AppColors.inkMuted),
                            const SizedBox(width: 5),
                            Text(
                              'Tap to preview full canvas',
                              style: AppText.labelSmall(color: AppColors.inkSecondary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s24),

            // ── 2. Template Title & Category Badges ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: AppText.headline1().copyWith(
                          fontSize: 22,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CategoryChip(label: template.category, isSelected: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s16),

            // ── 3. Description ─────────────────────────────────────────────
            if (template.description.isNotEmpty) ...[
              Text(
                template.description,
                style: AppText.bodyDefault(color: AppColors.inkSecondary).copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            // ── 4. Specs Bento Grid ─────────────────────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.15,
              children: [
                _SpecCard(
                  icon: formatIcon,
                  label: 'Format',
                  value: formatValue,
                  subtitle: formatSub,
                ),
                _SpecCard(
                  icon: LucideIcons.type,
                  label: 'Typography',
                  value: typographyValue,
                  subtitle: typographySub,
                ),
                _SpecCard(
                  icon: LucideIcons.images,
                  label: 'Screenshots',
                  value: slotsValue,
                  subtitle: slotsSub,
                ),
                _SpecCard(
                  icon: LucideIcons.sparkles,
                  label: 'Export Quality',
                  value: '4K Ultra HD',
                  subtitle: '300 DPI • Lossless',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s24),

            // ── 5. More Like This ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('More in ${template.category}', style: AppText.headline3()),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),

            SizedBox(
              height: 170,
              child: Consumer(
                builder: (context, ref, _) {
                  final suggestedAsync = ref.watch(templatesProvider(template.category));
                  return suggestedAsync.when(
                    data: (templates) {
                      final suggested = templates.where((t) => t.id != template.id).take(6).toList();
                      if (suggested.isEmpty) {
                        return Center(
                          child: Text(
                            'No other templates in this category.',
                            style: AppText.bodySmall(color: AppColors.inkMuted),
                          ),
                        );
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: suggested.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final t = suggested[i];
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTemplateSelected(t.id);
                            },
                            child: Container(
                              width: 105,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.br12,
                                border: Border.all(color: AppColors.borderSubtle),
                                boxShadow: AppShadows.subtle,
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
                                        child: Icon(LucideIcons.layoutGrid, size: 24, color: AppColors.inkDisabled),
                                      ),
                                    ),
                                  if (t.isPro)
                                    const Positioned(top: 6, right: 6, child: ProBadge()),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      ),
                    ),
                    error: (_, _) => const SizedBox(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s20,
          12,
          AppSpacing.s20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDefault, width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _shareTemplate,
                    child: const Center(
                      child: Icon(
                        LucideIcons.share2,
                        size: 20,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: template.isPro
                    ? AppButton(
                        label: 'Unlock with PRO',
                        onPressed: () => AppToast.show(
                          context,
                          message: 'PRO feature coming soon',
                          type: AppToastType.info,
                        ),
                        leadingIcon: const Icon(LucideIcons.lock, size: 18),
                        isFullWidth: true,
                      )
                    : AppButton(
                        label: 'Use template',
                        onPressed: _loading ? null : _useTemplate,
                        isLoading: _loading,
                        isFullWidth: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spec Bento Card ──────────────────────────────────────────────────────────

class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 17, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppText.labelLarge().copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: AppText.bodySmall(color: AppColors.inkMuted).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Circle Button ─────────────────────────────────────────────────────

class _HeaderCircleButton extends StatefulWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HeaderCircleButton> createState() => _HeaderCircleButtonState();
}

class _HeaderCircleButtonState extends State<_HeaderCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(widget.icon, color: AppColors.inkPrimary, size: 18),
        ),
      ),
    );
  }
}

// ── Collection Picker Sheet ──────────────────────────────────────────────────

class _CollectionPickerSheet extends StatelessWidget {
  const _CollectionPickerSheet({required this.collections, this.onCreateNew});
  final List collections;
  final VoidCallback? onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        boxShadow: AppShadows.float,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle Pill ─────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header Row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentTint,
                      borderRadius: AppRadius.br10,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.folderPlus,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add to collection', style: AppText.headline2().copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('Select destination collection', style: AppText.bodySmall(color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  if (onCreateNew != null)
                    Material(
                      color: AppColors.accentTint,
                      borderRadius: AppRadius.brFull,
                      child: InkWell(
                        borderRadius: AppRadius.brFull,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onCreateNew!();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.plus, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                'New',
                                style: AppText.labelDefault(color: AppColors.accent).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(color: AppColors.borderSubtle, height: 1),

            // ── Collections List ─────────────────────────────────────────
            Flexible(
              child: collections.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      child: Center(
                        child: Text(
                          'No collections yet. Tap "+ New" above to create one.',
                          style: AppText.bodyLarge(color: AppColors.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: collections.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = collections[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted.withValues(alpha: 0.45),
                            borderRadius: AppRadius.br12,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: AppColors.accent.withValues(alpha: 0.12),
                              highlightColor: AppColors.accent.withValues(alpha: 0.05),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, c.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: c.color.withValues(alpha: 0.14),
                                        borderRadius: AppRadius.br10,
                                        border: Border.all(
                                          color: c.color.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(LucideIcons.folderOpen, color: c.color, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: AppText.labelLarge().copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${c.screenshotCount} screenshot${c.screenshotCount != 1 ? 's' : ''}',
                                            style: AppText.bodySmall(color: AppColors.inkMuted).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.inkDisabled),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
