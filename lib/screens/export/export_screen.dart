import 'package:aperlo/services/render_engine.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';

import '../../widgets/dynamic_template.dart';

class _ExportThumbData {
  const _ExportThumbData({
    required this.id,
    required this.name,
    this.imagePath,
  });
  final String id;
  final String name;
  final String? imagePath;
}

// Top-level worker function for isolate computation
Future<Uint8List> _encodeJpgWorker(Map<String, dynamic> args) async {
  final bytes = args['bytes'] as Uint8List;
  final quality = args['quality'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded != null) {
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }
  return bytes;
}

class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({
    super.key,
    required this.screenshotId,
    this.screenshotIds = const [],
  });
  final String screenshotId;
  final List<String> screenshotIds;

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  String _format = 'PNG';
  double _quality = 95;
  bool _exporting = false;
  bool _exported = false;
  ui.Image? _previewImage;

  bool _exportAppStore = true;
  bool _exportGooglePlay = true;
  bool _targetPhones = true;
  bool _targetTablets = true;
  final double _fallbackWidth = 390;
  final double _fallbackHeight = 844;

  final GlobalKey _fallbackBoundaryKey = GlobalKey();
  List<Map<String, dynamic>>? _fallbackLayers;
  String? _fallbackHeadlineFont;
  String? _fallbackSubheadlineFont;
  String? _fallbackHeadline;
  String? _fallbackSubheadline;
  Color? _fallbackHeadlineColor;
  Color? _fallbackSubheadlineColor;
  ImageProvider? _fallbackScreenshotImage;

  // For Export All
  List<String> get _idsToExport => widget.screenshotIds.isNotEmpty
      ? widget.screenshotIds
      : [widget.screenshotId];
  int _exportIndex = 0;
  int _exportTotal = 1;

  List<_ExportThumbData> _thumbnails = [];

  @override
  void initState() {
    super.initState();
    _exportTotal = _idsToExport.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreview();
      _loadThumbnails();
    });
  }

  Future<void> _loadThumbnails() async {
    if (_idsToExport.length <= 1) return;

    final db = ref.read(localDataServiceProvider);
    List<_ExportThumbData> thumbs = [];
    for (var id in _idsToExport) {
      final doc = await db.getScreenshotDoc(id);
      if (doc != null) {
        thumbs.add(
          _ExportThumbData(
            id: id,
            name: doc['name'] ?? 'Screenshot',
            imagePath: doc['thumbnailUrl'] ?? doc['thumbnailPath'],
          ),
        );
      }
    }
    if (mounted) setState(() => _thumbnails = thumbs);
  }

  Future<void> _loadPreview() async {
    try {
      final boundaryKey = ref.read(activeCanvasKeyProvider);
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 0.5);
        if (mounted) setState(() => _previewImage = image);
      } else {
        await _loadFallbackData(widget.screenshotId);
      }
    } catch (e) {
      debugPrint("Failed to load preview: $e");
    }
  }

  Future<void> _loadFallbackData(String sid) async {
    final db = ref.read(localDataServiceProvider);
    final doc = await db.getScreenshotDoc(sid);
    if (doc != null) {
      final tplId = doc['templateId'];
      final tpl = await ref.read(firestoreServiceProvider).getTemplate(tplId);
      final cs = Map<String, dynamic>.from(doc['canvasState'] as Map? ?? {});
      final layers = List<Map<String, dynamic>>.from(
        (cs['layers'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
            tpl?.layout ??
            [],
      );

      final headline = cs['headline'] as String? ?? 'Your headline here';
      final subheadline =
          cs['subheadline'] as String? ??
          'A short description that tells users what they get';
      final imagePath = cs['screenshotImagePath'] as String?;

      ImageProvider? screenshotImage;
      if (imagePath != null && File(imagePath).existsSync()) {
        screenshotImage = FileImage(File(imagePath));
      }

      if (mounted) {
        setState(() {
          _fallbackLayers = layers;
          _fallbackHeadlineFont = tpl?.headlineFont ?? 'Syne';
          _fallbackSubheadlineFont = tpl?.subheadlineFont ?? 'DM Sans';
          _fallbackHeadline = headline;
          _fallbackSubheadline = subheadline;
          _fallbackHeadlineColor = cs['headlineColor'] != null
              ? Color(cs['headlineColor'])
              : null;
          _fallbackSubheadlineColor = cs['subheadlineColor'] != null
              ? Color(cs['subheadlineColor'])
              : null;
          _fallbackScreenshotImage = screenshotImage;
        });

        // Wait for render
        await Future.delayed(const Duration(milliseconds: 300));
        final fallbackBoundary =
            _fallbackBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (fallbackBoundary != null) {
          final image = await fallbackBoundary.toImage(pixelRatio: 0.5);
          if (mounted) setState(() => _previewImage = image);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _export() async {
    if ((!_exportAppStore && !_exportGooglePlay) ||
        (!_targetPhones && !_targetTablets)) {
      if (mounted) {
        AppToast.show(context, message: 'Please select at least one Target Store and one Target Device.', type: AppToastType.error);
      }
      return;
    }

    setState(() => _exporting = true);

    try {
      final db = ref.read(localDataServiceProvider);

      // Load specs
      final specsStr = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/config/store_export_specs.json');
      final specs = jsonDecode(specsStr);
      final List appleDevices = specs['appleAppStore']['deviceClasses'];
      final List googleDevices = specs['googlePlay']['deviceClasses'];

      final targets = <Map<String, dynamic>>[];

      if (_exportAppStore) {
        for (var d in appleDevices) {
          bool isTablet = (d['id'] as String).contains('ipad');
          if ((isTablet && _targetTablets) || (!isTablet && _targetPhones)) {
            targets.add({
              'suffix': 'iOS_${d['id']}',
              'width': d['width'],
              'height': d['height'],
            });
          }
        }
      }

      if (_exportGooglePlay) {
        for (var d in googleDevices) {
          if (d['recommendedWidth'] != null) {
            bool isTablet = (d['id'] as String).contains('tablet');
            if ((isTablet && _targetTablets) || (!isTablet && _targetPhones)) {
              targets.add({
                'suffix': 'Android_${d['id']}',
                'width': d['recommendedWidth'],
                'height': d['recommendedHeight'],
              });
            }
          }
        }
      }

      for (int i = 0; i < _idsToExport.length; i++) {
        if (mounted) setState(() => _exportIndex = i + 1);
        final sid = _idsToExport[i];

        await _loadFallbackData(sid);

        String collectionName = 'Collection';
        String screenshotName = 'Screenshot';
        final doc = await db.getScreenshotDoc(sid);
        if (doc != null) {
          screenshotName = doc['name'] ?? 'Screenshot';
          final collectionId = doc['collectionId'];
          if (collectionId != null) {
            final col = db.getCollection(collectionId);
            if (col != null) collectionName = col.name;
          }
        }

        collectionName = collectionName
            .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '')
            .replaceAll(' ', '_');
        screenshotName = screenshotName
            .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '')
            .replaceAll(' ', '_');
        final baseFilename = '${collectionName}_$screenshotName';

        final renderFutures = targets.map((t) async {
          final width = t['width'] as int;
          final height = t['height'] as int;

          final templateWidget = DynamicTemplate(
            canvasWidth: width.toDouble(),
            canvasHeight: height.toDouble(),
            layers: _fallbackLayers ?? [],
            headline: _fallbackHeadline ?? 'Your headline here',
            subheadline:
                _fallbackSubheadline ??
                'A short description that tells users what they get',
            headlineFont: _fallbackHeadlineFont ?? 'Syne',
            subheadlineFont: _fallbackSubheadlineFont ?? 'DM Sans',
            headlineColor: _fallbackHeadlineColor,
            subheadlineColor: _fallbackSubheadlineColor,
            screenshotImage: _fallbackScreenshotImage,
          );

          final image = await RenderEngine.renderTemplateAtResolution(
            templateWidget: templateWidget,
            pixelWidth: width,
            pixelHeight: height,
          );

          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) return;

          Uint8List bytes = byteData.buffer.asUint8List();
          String ext = 'png';
          if (_format == 'JPG') {
            bytes = await compute(_encodeJpgWorker, {
              'bytes': bytes,
              'quality': _quality.toInt(),
            });
            ext = 'jpg';
          }

          final filename =
              '${baseFilename}_${t['suffix']}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$filename');
          await tempFile.writeAsBytes(bytes);
          await Gal.putImage(tempFile.path);
        }).toList();

        await Future.wait(renderFutures);
      }
    } catch (e) {
      debugPrint("Export error: $e");
      if (mounted) {
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
            contentPadding: const EdgeInsets.all(AppSpacing.s24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.destructiveTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.alertCircle, size: 28, color: AppColors.destructive),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text('Export failed', style: AppText.headline2(color: AppColors.inkPrimary), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s8),
                Text('An unexpected error occurred while exporting. Please check storage permissions and try again.', style: AppText.bodyDefault(color: AppColors.inkMuted), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s24),
                AppButton(
                  label: 'Dismiss',
                  onPressed: () => Navigator.pop(ctx),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exported = true;
        });
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _exported = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_fallbackLayers != null)
          Positioned(
            left: -9999, // offscreen
            top: -9999,
            child: RepaintBoundary(
              key: _fallbackBoundaryKey,
              child: SizedBox(
                width: _fallbackWidth,
                height: _fallbackHeight,
                child: DynamicTemplate(
                  canvasWidth: _fallbackWidth,
                  canvasHeight: _fallbackHeight,
                  layers: _fallbackLayers!,
                  headline: _fallbackHeadline ?? 'Your headline here',
                  subheadline:
                      _fallbackSubheadline ??
                      'A short description that tells users what they get',
                  headlineFont: _fallbackHeadlineFont ?? 'Syne',
                  subheadlineFont: _fallbackSubheadlineFont ?? 'DM Sans',
                  screenshotImage: _fallbackScreenshotImage,
                ),
              ),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.r20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export screenshot${_idsToExport.length > 1 ? 's' : ''}',
                          style: AppText.headline2(),
                        ),
                        Text(
                          'Select format and size',
                          style: AppText.bodySmall(),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: AppColors.inkMuted,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s24,
                    0,
                    AppSpacing.s24,
                    AppSpacing.s24,
                  ),
                  children: [
                    // Preview section
                    if (_idsToExport.length > 1)
                      // Strip of thumbnails for Export All
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _thumbnails.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(width: AppSpacing.s12),
                          itemBuilder: (ctx, i) {
                            final thumb = _thumbnails[i];
                            return Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70 * 16 / 9,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: AppRadius.br6,
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child:
                                      thumb.imagePath != null &&
                                          thumb.imagePath!.isNotEmpty &&
                                          File(thumb.imagePath!).existsSync()
                                      ? Image.file(
                                          File(thumb.imagePath!),
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child: Icon(
                                            LucideIcons.image,
                                            color: AppColors.inkDisabled,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    thumb.name,
                                    style: AppText.labelSmall(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      // Single preview
                      Center(
                        child: Container(
                          width: 100,
                          height: 100 * 16 / 9,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadius.br12,
                            boxShadow: AppShadows.card,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _previewImage != null
                              ? RawImage(
                                  image: _previewImage,
                                  fit: BoxFit.contain,
                                )
                              : const Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    size: 32,
                                    color: AppColors.inkDisabled,
                                  ),
                                ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.s32),

                    // Target Store selector
                    Text('Target Store', style: AppText.headline3()),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: _StoreSelectCard(
                            title: 'App Store',
                            subtitle: 'iOS Devices',
                            isSelected: _exportAppStore,
                            onTap: () => setState(
                              () => _exportAppStore = !_exportAppStore,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: _StoreSelectCard(
                            title: 'Google Play',
                            subtitle: 'Android Devices',
                            isSelected: _exportGooglePlay,
                            onTap: () => setState(
                              () => _exportGooglePlay = !_exportGooglePlay,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Target Device selector
                    Text('Target Device', style: AppText.headline3()),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: _StoreSelectCard(
                            title: 'Phones',
                            subtitle: '6.5" & 6.9"',
                            isSelected: _targetPhones,
                            onTap: () =>
                                setState(() => _targetPhones = !_targetPhones),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: _StoreSelectCard(
                            title: 'Tablets',
                            subtitle: 'iPad / 10"',
                            isSelected: _targetTablets,
                            onTap: () => setState(
                              () => _targetTablets = !_targetTablets,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Format selector
                    Text('Format', style: AppText.headline3()),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: ['PNG', 'JPG']
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryChip(
                                label: f,
                                isSelected: _format == f,
                                onTap: () => setState(() {
                                  _format = f;
                                }),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'PNG preserves transparency and quality',
                      style: AppText.labelSmall(),
                    ),

                    // Quality slider (JPG)
                    if (_format != 'PNG') ...[
                      const SizedBox(height: AppSpacing.s16),
                      Row(
                        children: [
                          Text('Quality', style: AppText.headline3()),
                          const Spacer(),
                          Text(
                            'High quality · ~${(_quality / 100 * 3.5 + 0.5).toStringAsFixed(1)} MB',
                            style: AppText.labelSmall(),
                          ),
                        ],
                      ),
                      Slider(
                        value: _quality,
                        min: 60,
                        max: 100,
                        divisions: 40,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _quality = v),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.s32),

                    // Export button
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: _exported
                          ? Container(
                              key: const ValueKey('success'),
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.accentTint,
                                borderRadius: AppRadius.br12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.circleCheck,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Saved to gallery',
                                    style: AppText.labelLarge(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AppButton(
                              key: const ValueKey('export'),
                              label: _exporting && _exportTotal > 1
                                  ? 'Exporting $_exportIndex of $_exportTotal...'
                                  : 'Export ${_exportTotal > 1 ? '$_exportTotal screenshots' : 'screenshot'}',
                              onPressed: _export,
                              isLoading: _exporting,
                              isFullWidth: true,
                              height: 52,
                            ),
                    ),

                    const SizedBox(height: AppSpacing.s16),
                    if (_idsToExport.length == 1)
                      Text(
                        'Tip: Export all screenshots at once from the collection menu.',
                        style: AppText.bodySmall(),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreSelectCard extends StatelessWidget {
  const _StoreSelectCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppRadius.br12,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.borderDefault,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 16,
                  color: isSelected ? AppColors.accent : AppColors.inkDisabled,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.labelLarge(
                      color: isSelected
                          ? AppColors.inkPrimary
                          : AppColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                subtitle,
                style: AppText.labelSmall(
                  color: isSelected ? AppColors.accent : AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
