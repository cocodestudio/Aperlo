import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/storage_util.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/canvas_element.dart';
import '../../providers/app_providers.dart';
import 'property_sheets.dart';
import '../../widgets/dynamic_template.dart';
import '../export/export_screen.dart';
import 'package:go_router/go_router.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.screenshotId});
  final String screenshotId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _isLoading = true;
  bool _showZoomChip = false;
  TemplateData _templateData = const TemplateData();
  String _templateId = 'tpl_minimal_001';
  List<Map<String, dynamic>> _templateLayers = [];
  String _screenshotName = 'Editing';
  String _headlineFont = 'Syne';
  String _subheadlineFont = 'DM Sans';
  double _zoomLevel = 0.75;
  int? _selectedLayerIndex;
  String? _activeSubPanel;
  Timer? _saveDebouncer;
  late final TransformationController _transformCtrl;
  bool _isCanvasCentered = false;

  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  _EditorSnapshot get _currentSnapshot => _EditorSnapshot(
        templateData: _templateData,
        layers: List<Map<String, dynamic>>.from(
            _templateLayers.map((l) => Map<String, dynamic>.from(l))),
      );

  void _pushUndo() {
    _undoStack.add(_currentSnapshot);
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_currentSnapshot);
    final prev = _undoStack.removeLast();
    setState(() {
      _templateData = prev.templateData;
      _templateLayers = prev.layers;
      _selectedLayerIndex = null;
    });
    _save();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_currentSnapshot);
    final next = _redoStack.removeLast();
    setState(() {
      _templateData = next.templateData;
      _templateLayers = next.layers;
      _selectedLayerIndex = null;
    });
    _save();
  }

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    _transformCtrl.addListener(() {
      final scale = _transformCtrl.value.getMaxScaleOnAxis();
      if ((scale - _zoomLevel).abs() > 0.01 && mounted) {
        setState(() => _zoomLevel = scale);
      }
    });
    Future.microtask(() async {
      if (!mounted) return;
      ref.read(editorProvider.notifier).init(EditorState(
        elements: [],
        background: CanvasBackground.defaultBg,
        canvasWidth: 390,
        canvasHeight: 844,
      ));
      final db = ref.read(localDataServiceProvider);
      final doc = await db.getScreenshotDoc(widget.screenshotId);
      if (doc != null && mounted) {
        final templateId = doc['templateId'] as String? ?? _templateId;
        final tpl = await ref.read(firestoreServiceProvider).getTemplate(templateId);
        final cs = Map<String, dynamic>.from(doc['canvasState'] as Map? ?? {});
        setState(() {
          _screenshotName = doc['name'] as String? ?? 'Editing';
          _templateId = templateId;
          _headlineFont = tpl?.headlineFont ?? 'Syne';
          _subheadlineFont = tpl?.subheadlineFont ?? 'DM Sans';

          final savedLayers = cs['layers'] as List?;
          if (savedLayers != null && savedLayers.isNotEmpty) {
            _templateLayers = savedLayers
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            _templateLayers = tpl?.layout ?? [];
          }

          final hcVal = cs['headlineColor'] as int?;
          final scVal = cs['subheadlineColor'] as int?;
          _templateData = TemplateData(
            headline: cs['headline'] as String? ?? _templateData.headline,
            subheadline:
                cs['subheadline'] as String? ?? _templateData.subheadline,
            headlineColor: hcVal != null ? Color(hcVal) : null,
            subheadlineColor: scVal != null ? Color(scVal) : null,
          );

          _isLoading = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isCanvasCentered) {
      _isCanvasCentered = true;
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      
      final viewWidth = size.width;
      final viewHeight = size.height - 60 - 80 - padding.top - padding.bottom;
      
      final scaledWidth = 390 * 0.75;
      final scaledHeight = 844 * 0.75;
      
      final dx = (viewWidth - scaledWidth) / 2;
      final dy = (viewHeight - scaledHeight) / 2;
      
      final mat = Matrix4.identity();
      // ignore: deprecated_member_use
      mat.translate(dx, dy);
      // ignore: deprecated_member_use
      mat.scale(0.75, 0.75, 1.0);
      
      _transformCtrl.value = mat;
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _debouncedSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _save();
    });
  }

  Future<void> _save() async {
    await ref.read(localDataServiceProvider).saveCanvasState(
        widget.screenshotId, {
      'headline': _templateData.headline,
      'subheadline': _templateData.subheadline,
      'layers': _templateLayers,
    });
    await _generateAndUploadThumbnail();
  }

  Future<void> _generateAndUploadThumbnail() async {
    try {
      final boundaryKey = ref.read(activeCanvasKeyProvider);
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 0.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final bytes = byteData.buffer.asUint8List();
      final imgPath = await StorageUtil.getImagesPath();
      final file = File('$imgPath/${widget.screenshotId}.png');
      await file.writeAsBytes(bytes);
      
      await FileImage(file).evict();
      
      await ref.read(localDataServiceProvider)
          .saveScreenshotThumbnail(widget.screenshotId, file.path);
    } catch (e) {
      debugPrint("Failed to generate local thumbnail: $e");
    }
  }

  Future<void> _pickScreenshotImage(int index) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (picked == null || !mounted) return;
      _pushUndo();
      
      final imgPath = await StorageUtil.getImagesPath();
      final ext = picked.path.split('.').last;
      final newPath = '$imgPath/${widget.screenshotId}_${index}_imported.$ext';
      await File(picked.path).copy(newPath);
      
      setState(() => _templateLayers[index]['screenshotPath'] = newPath);
      _save();
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _onTapLayer(int index) {
    final type = _templateLayers[index]['type'] as String? ?? '';
    if (type == 'phone' || type == 'background') return;
    
    setState(() {
      _selectedLayerIndex = index;
      _activeSubPanel = null;
    });
  }

  void _onLongPressLayer(int index) {
    final type = _templateLayers[index]['type'] as String? ?? '';
    if (type == 'phone') {
      setState(() {
        _selectedLayerIndex = index;
        _activeSubPanel = null;
      });
    }
  }

  void _deleteLayer(int index) {
    _pushUndo();
    setState(() {
      _templateLayers.removeAt(index);
      _selectedLayerIndex = null;
    });
    _save();
  }

  void _reorderLayers(int oldIndex, int newIndex) {
    _pushUndo();
    setState(() {
      final item = _templateLayers.removeAt(oldIndex);
      _templateLayers.insert(newIndex, item);
      _selectedLayerIndex = null;
    });
    _save();
  }

  void _showLayersPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scroll) => _LayersPanel(
            layers: _templateLayers,
            selectedIndex: _selectedLayerIndex,
            onReorder: (oldI, newI) {
              _reorderLayers(oldI, newI);
              setSheetState(() {});
            },
            onTap: (index) {
              Navigator.pop(ctx);
              _onTapLayer(index);
            },
            onDelete: (index) {
              _deleteLayer(index);
              setSheetState(() {});
            },
            scrollController: scroll,
          ),
        ),
      ),
    );
  }

  void _handlePanUpdateLayer(int index, Offset delta) {
    if (_selectedLayerIndex != index) return;
    
    final zoomScale = _transformCtrl.value.getMaxScaleOnAxis();
    final dx = (delta.dx / zoomScale) / 390.0;
    final dy = (delta.dy / zoomScale) / 844.0;

    final layer = Map<String, dynamic>.from(_templateLayers[index]);
    
    if (layer.containsKey('cx')) {
      layer['cx'] = (layer['cx'] as num? ?? 0.5) + dx;
    } else {
      final alignX = layer['align_x'] as String? ?? 'left';
      if (alignX == 'right') {
        layer['x'] = (layer['x'] as num? ?? 1.0) + dx;
      } else {
        layer['x'] = (layer['x'] as num? ?? 0.0) + dx;
      }
    }
    
    if (layer.containsKey('cy')) {
      layer['cy'] = (layer['cy'] as num? ?? 0.5) + dy;
    } else {
      final alignY = layer['align_y'] as String? ?? 'top';
      if (alignY == 'bottom') {
        layer['y'] = (layer['y'] as num? ?? 1.0) + dy;
      } else {
        layer['y'] = (layer['y'] as num? ?? 0.0) + dy;
      }
    }
    setState(() {
      _templateLayers[index] = layer;
    });
  }

  void _handlePanEndLayer(int index) {
    _save();
  }

  void _snapLeft(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_x'] = 'left';
    layer['x'] = 0.0;
    layer.remove('cx');
    updateFn(layer);
  }

  void _snapRight(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_x'] = 'right';
    layer['x'] = 0.0;
    layer.remove('cx');
    updateFn(layer);
  }

  void _snapTop(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_y'] = 'top';
    layer['y'] = 0.0;
    layer.remove('cy');
    updateFn(layer);
  }

  void _snapBottom(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_y'] = 'bottom';
    layer['y'] = 0.0;
    layer.remove('cy');
    updateFn(layer);
  }

  void _snapCenterH(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_x'] = 'center';
    layer['cx'] = 0.5;
    layer['x'] = 0.5;
    updateFn(layer);
  }

  void _snapCenterV(Map<String, dynamic> layer, void Function(Map<String, dynamic>) updateFn) {
    layer['align_y'] = 'center';
    layer['cy'] = 0.5;
    layer['y'] = 0.5;
    updateFn(layer);
  }

  void _nudgeLayer(Map<String, dynamic> layer, double dx, double dy, void Function(Map<String, dynamic>) updateFn) {
    if (layer.containsKey('cx') || layer['align_x'] == 'center') {
      layer['cx'] = ((layer['cx'] as num? ?? 0.5) + dx).clamp(-0.5, 1.5);
    } else {
      final alignX = layer['align_x'] as String? ?? 'left';
      if (alignX == 'right') {
        layer['x'] = ((layer['x'] as num? ?? 0.0) - dx).clamp(-0.5, 1.5);
      } else {
        layer['x'] = ((layer['x'] as num? ?? 0.0) + dx).clamp(-0.5, 1.5);
      }
    }

    if (layer.containsKey('cy') || layer['align_y'] == 'center') {
      layer['cy'] = ((layer['cy'] as num? ?? 0.5) + dy).clamp(-0.5, 1.5);
    } else {
      final alignY = layer['align_y'] as String? ?? 'top';
      if (alignY == 'bottom') {
        layer['y'] = ((layer['y'] as num? ?? 0.0) - dy).clamp(-0.5, 1.5);
      } else {
        layer['y'] = ((layer['y'] as num? ?? 0.0) + dy).clamp(-0.5, 1.5);
      }
    }
    updateFn(layer);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        
        if (_activeSubPanel != null || _selectedLayerIndex != null) {
          setState(() {
            _activeSubPanel = null;
            _selectedLayerIndex = null;
          });
          return;
        }

        await _save();
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _EditorAppBar(
                screenshotName: _screenshotName,
                onRename: (newName) async {
                  setState(() => _screenshotName = newName);
                  await ref
                      .read(localDataServiceProvider)
                      .renameScreenshot(widget.screenshotId, newName);
                },
                canUndo: _canUndo,
                canRedo: _canRedo,
                onUndo: _undo,
                onRedo: _redo,
                onExport: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ExportSheet(screenshotId: widget.screenshotId),
                  );
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.background,
                        child: _isLoading 
                            ? const _PremiumLoadingState() 
                            : GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLayerIndex = null;
                                _activeSubPanel = null;
                              });
                              ref.read(editorProvider.notifier).selectElement(null);
                            },
                          child: InteractiveViewer(
                            panEnabled: false,
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            transformationController: _transformCtrl,
                            minScale: 0.25,
                            maxScale: 4.0,
                            onInteractionUpdate: (details) {
                              if (details.scale != 1.0) {
                                setState(() => _showZoomChip = true);
                              }
                            },
                            onInteractionEnd: (_) {
                              Future.delayed(const Duration(milliseconds: 1500),
                                  () {
                                if (mounted) {
                                  setState(() => _showZoomChip = false);
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                RepaintBoundary(
                                  key: ref.watch(activeCanvasKeyProvider),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: AppShadows.card,
                                    ),
                                    child: DynamicTemplate(
                                      layers: _templateLayers,
                                      headline: _templateData.headline,
                                      subheadline: _templateData.subheadline,
                                      headlineColor: _templateData.headlineColor,
                                      subheadlineColor:
                                          _templateData.subheadlineColor,
                                      headlineFont: _headlineFont,
                                      subheadlineFont: _subheadlineFont,
                                      canvasWidth: 390,
                                      canvasHeight: 844,
                                      onPanUpdateLayer: _handlePanUpdateLayer,
                                      onTapLayer: _onTapLayer,
                                      onTapPhone: _pickScreenshotImage,
                                      onPanEndLayer: _handlePanEndLayer,
                                      onLongPressLayer: _onLongPressLayer,
                                      selectedLayerIndex: _selectedLayerIndex,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                            ),
                          ),
                    ),
                    
                    if (_showZoomChip)
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.br10,
                            boxShadow: AppShadows.subtle,
                          ),
                          child: Text(
                            '${(_zoomLevel * 100).round()}%',
                            style: AppText.labelDefault(
                                color: AppColors.inkPrimary),
                          ),
                        ),
                      ),
                      
                    if (_selectedLayerIndex != null)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.brFull,
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _LayersPanel._labelForLayer(_templateLayers[_selectedLayerIndex!]),
                                  style: AppText.labelDefault(),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedLayerIndex = null;
                                    _activeSubPanel = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.x, size: 12, color: AppColors.inkPrimary),
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
              _EditorBottomBar(
                options: _buildContextualOptions(),
                onOpenLayers: _showLayersPanel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubPanel(String panel) {
    if (_selectedLayerIndex == null) return;
    final index = _selectedLayerIndex!;
    final layer = Map<String, dynamic>.from(_templateLayers[index]);

    void updateLayer(Map<String, dynamic> newLayer) {
      _pushUndo();
      setState(() { _templateLayers[index] = newLayer; });
      _debouncedSave();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            void sheetUpdateLayer(Map<String, dynamic> newLayer) {
              updateLayer(newLayer);
              setSheetState(() {});
            }

            final String type = layer['type'] as String? ?? '';
            List<Widget> sections = [];

            if (type == 'text' || type == 'badge' || type == 'feature_row') {
              final rawContent = layer['content'] as String? ?? '';
              final isHeadline = rawContent.contains('{headline}');
              final isSubheadline = rawContent.contains('{subheadline}');
              
              final initialText = isHeadline ? _templateData.headline : isSubheadline ? _templateData.subheadline : rawContent;
                      
              sections = [
                buildSection('Content', [
                  _LayerTextField(
                    key: ValueKey('text_$_selectedLayerIndex'),
                    label: 'Text',
                    initialText: initialText,
                    onChanged: (val) {
                      if (isHeadline) {
                        setState(() { _templateData = TemplateData(headline: val, subheadline: _templateData.subheadline, headlineColor: _templateData.headlineColor, subheadlineColor: _templateData.subheadlineColor); });
                        _debouncedSave();
                      } else if (isSubheadline) {
                        setState(() { _templateData = TemplateData(headline: _templateData.headline, subheadline: val, headlineColor: _templateData.headlineColor, subheadlineColor: _templateData.subheadlineColor); });
                        _debouncedSave();
                      } else {
                        layer['content'] = val; sheetUpdateLayer(layer);
                      }
                    },
                  )
                ]),
                buildSection('Appearance', [
                  PropertyDropdown(label: 'Font Family', value: layer['font_family'] ?? 'DM Sans', items: const ['Syne', 'DM Sans', 'Syne Mono'], onChanged: (v) { layer['font_family'] = v; sheetUpdateLayer(layer); }),
                  StyledInputNumeric(label: 'Font Size', value: ((layer['font_size'] ?? 0.08) as num).toDouble() * 390.0, onChanged: (v) { layer['font_size'] = v / 390.0; sheetUpdateLayer(layer); }),
                  PropertyColorPicker(label: 'Color', hexColor: layer['color'] ?? '#1A6B4A', onChanged: (v) { layer['color'] = v; sheetUpdateLayer(layer); }),
                ]),
                buildSection('Layout', [
                  TextAlignmentControl(
                    value: layer['text_align'] as String? ?? layer['align'] as String? ?? 'left',
                    onChanged: (v) {
                      layer['text_align'] = v;
                      layer['align'] = v;
                      sheetUpdateLayer(layer);
                    },
                  ),
                  PropertySlider(label: 'Letter Spacing', value: (layer['letter_spacing'] ?? 0.0).toDouble(), min: -5.0, max: 20.0, onChanged: (v) { layer['letter_spacing'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Line Height', value: (layer['line_height'] ?? 1.2).toDouble(), min: 0.5, max: 3.0, onChanged: (v) { layer['line_height'] = v; sheetUpdateLayer(layer); }),
                ]),
                buildSection('Position', [
                  PositionPresets(
                    onSnapLeft: () => _snapLeft(layer, sheetUpdateLayer),
                    onSnapRight: () => _snapRight(layer, sheetUpdateLayer),
                    onSnapTop: () => _snapTop(layer, sheetUpdateLayer),
                    onSnapBottom: () => _snapBottom(layer, sheetUpdateLayer),
                    onSnapCenterH: () => _snapCenterH(layer, sheetUpdateLayer),
                    onSnapCenterV: () => _snapCenterV(layer, sheetUpdateLayer),
                  ),
                  StyledPositionNudge(
                    onUp: () => _nudgeLayer(layer, 0, -0.01, sheetUpdateLayer),
                    onDown: () => _nudgeLayer(layer, 0, 0.01, sheetUpdateLayer),
                    onLeft: () => _nudgeLayer(layer, -0.01, 0, sheetUpdateLayer),
                    onRight: () => _nudgeLayer(layer, 0.01, 0, sheetUpdateLayer),
                  ),
                ]),
              ];
            } else if (type == 'image' || type == 'phone') {
              sections = [
                if (type == 'phone') buildSection('Source', [
                  StyledActionTile(label: 'Pick Image', icon: LucideIcons.image, onTap: () {
                    Navigator.pop(ctx);
                    if (_selectedLayerIndex != null) _pickScreenshotImage(_selectedLayerIndex!);
                  }),
                ]),
                if (type == 'phone') buildSection('Mockup Style', [
                  MockupStyleSelector(
                    value: layer['style'] as String? ?? 'dynamic_island',
                    onChanged: (v) { layer['style'] = v; sheetUpdateLayer(layer); },
                  ),
                ]),
                buildSection('Transform', [
                  PropertySlider(label: 'Scale', value: (layer['scale'] ?? 1.0).toDouble(), min: 0.1, max: 3.0, valueFormatter: (v) => '${(v * 100).toInt()}%', onChanged: (v) { layer['scale'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Rotation', value: (layer['rotation'] ?? 0.0).toDouble(), min: -180.0, max: 180.0, valueFormatter: (v) => '${v.toInt()}°', onChanged: (v) { layer['rotation'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Opacity', value: (layer['opacity'] ?? 1.0).toDouble(), min: 0.0, max: 1.0, valueFormatter: (v) => '${(v * 100).toInt()}%', onChanged: (v) { layer['opacity'] = v; sheetUpdateLayer(layer); }),
                ]),
                buildSection('Position', [
                  PositionPresets(
                    onSnapLeft: () => _snapLeft(layer, sheetUpdateLayer),
                    onSnapRight: () => _snapRight(layer, sheetUpdateLayer),
                    onSnapTop: () => _snapTop(layer, sheetUpdateLayer),
                    onSnapBottom: () => _snapBottom(layer, sheetUpdateLayer),
                    onSnapCenterH: () => _snapCenterH(layer, sheetUpdateLayer),
                    onSnapCenterV: () => _snapCenterV(layer, sheetUpdateLayer),
                  ),
                  StyledPositionNudge(
                    onUp: () => _nudgeLayer(layer, 0, -0.01, sheetUpdateLayer),
                    onDown: () => _nudgeLayer(layer, 0, 0.01, sheetUpdateLayer),
                    onLeft: () => _nudgeLayer(layer, -0.01, 0, sheetUpdateLayer),
                    onRight: () => _nudgeLayer(layer, 0.01, 0, sheetUpdateLayer),
                  ),
                ]),
              ];

            } else if (type == 'shape' || type == 'accent_bar' || type == 'divider' || type == 'frosted_panel') {
              sections = [
                buildSection('Appearance', [
                  PropertyColorPicker(label: 'Color', hexColor: layer['color'] ?? '#1A6B4A', onChanged: (v) { layer['color'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Opacity', value: (layer['opacity'] ?? 1.0).toDouble(), min: 0.0, max: 1.0, valueFormatter: (v) => '${(v * 100).toInt()}%', onChanged: (v) { layer['opacity'] = v; sheetUpdateLayer(layer); }),
                  if (type == 'shape' || type == 'frosted_panel') PropertySlider(label: 'Border Radius', value: (layer['border_radius'] ?? 12.0).toDouble(), min: 0.0, max: 100.0, onChanged: (v) { layer['border_radius'] = v; sheetUpdateLayer(layer); }),
                  if (type == 'frosted_panel') PropertySlider(label: 'Blur Amount', value: (layer['blur'] ?? 10.0).toDouble(), min: 0.0, max: 40.0, valueFormatter: (v) => '${v.toInt()} px', onChanged: (v) { layer['blur'] = v; sheetUpdateLayer(layer); }),
                ]),
                buildSection('Transform', [
                  PropertySlider(label: 'Width', value: (layer['width'] ?? 0.8).toDouble(), min: 0.05, max: 1.5, valueFormatter: (v) => '${(v * 100).toInt()}%', onChanged: (v) { layer['width'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Height', value: (layer['height'] ?? 0.8).toDouble(), min: 0.05, max: 1.5, valueFormatter: (v) => '${(v * 100).toInt()}%', onChanged: (v) { layer['height'] = v; sheetUpdateLayer(layer); }),
                  PropertySlider(label: 'Rotation', value: (layer['rotation'] ?? 0.0).toDouble(), min: -180.0, max: 180.0, valueFormatter: (v) => '${v.toInt()}°', onChanged: (v) { layer['rotation'] = v; sheetUpdateLayer(layer); }),
                ]),
                buildSection('Position', [
                  PositionPresets(
                    onSnapLeft: () => _snapLeft(layer, sheetUpdateLayer),
                    onSnapRight: () => _snapRight(layer, sheetUpdateLayer),
                    onSnapTop: () => _snapTop(layer, sheetUpdateLayer),
                    onSnapBottom: () => _snapBottom(layer, sheetUpdateLayer),
                    onSnapCenterH: () => _snapCenterH(layer, sheetUpdateLayer),
                    onSnapCenterV: () => _snapCenterV(layer, sheetUpdateLayer),
                  ),
                  StyledPositionNudge(
                    onUp: () => _nudgeLayer(layer, 0, -0.01, sheetUpdateLayer),
                    onDown: () => _nudgeLayer(layer, 0, 0.01, sheetUpdateLayer),
                    onLeft: () => _nudgeLayer(layer, -0.01, 0, sheetUpdateLayer),
                    onRight: () => _nudgeLayer(layer, 0.01, 0, sheetUpdateLayer),
                  ),
                ]),
              ];
            }

            return PropertySheetLayout(children: sections);
          }
        )
      )
    );
  }

  void _showBackgroundPanel(BuildContext context) {
    int bgIndex = _templateLayers.indexWhere((l) => l['type'] == 'background');
    if (bgIndex == -1) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LayerBackgroundEditSheet(
        layer: _templateLayers[bgIndex],
        onSave: (updated) {
          _pushUndo();
          setState(() => _templateLayers[bgIndex] = updated);
          _save();
        },
      ),
    );
  }

  List<Widget> _buildContextualOptions() {
    if (_selectedLayerIndex == null) {
      return [
        _ToolButton(
          icon: LucideIcons.palette,
          label: 'Background',
          isActive: false,
          onTap: () => _showBackgroundPanel(context),
        ),
      ];
    }

    final layer = _templateLayers[_selectedLayerIndex!];
    final type = layer['type'] as String? ?? '';
    final List<Widget> options = [];

    options.add(_ToolButton(icon: LucideIcons.slidersHorizontal, label: 'Properties', isActive: false, onTap: () => _showSubPanel('edit')));
    if (type != 'background') {
      options.add(_ToolButton(icon: LucideIcons.trash2, label: 'Delete', isActive: false, onTap: () => _deleteLayer(_selectedLayerIndex!)));
    }

    return options;
  }
}

class _EditorSnapshot {
  const _EditorSnapshot({
    required this.templateData,
    required this.layers,
  });

  final TemplateData templateData;
  final List<Map<String, dynamic>> layers;
}

class _PremiumLoadingState extends StatefulWidget {
  const _PremiumLoadingState();

  @override
  State<_PremiumLoadingState> createState() => _PremiumLoadingStateState();
}

class _PremiumLoadingStateState extends State<_PremiumLoadingState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            painter: _PremiumLoadingPainter(progress: _ctrl.value),
            size: const Size(120, 120),
          );
        },
      ),
    );
  }
}

class _PremiumLoadingPainter extends CustomPainter {
  _PremiumLoadingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 20.0 + (ringProgress * 40.0);
      final opacity = 1.0 - ringProgress;
      
      ringPaint.color = AppColors.accent.withValues(alpha: opacity * 0.5);
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }
    
    final diamondPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8 + (progress * 0.2))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final dSize = 12.0 + (progress * 4.0);
    path.moveTo(cx, cy - dSize);
    path.lineTo(cx + dSize, cy);
    path.lineTo(cx, cy + dSize);
    path.lineTo(cx - dSize, cy);
    path.close();
    
    canvas.drawShadow(path, AppColors.accent, 10 + (progress * 10), true);
    canvas.drawPath(path, diamondPaint);
  }

  @override
  bool shouldRepaint(_PremiumLoadingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _EditorAppBar extends StatelessWidget {
  const _EditorAppBar({
    required this.screenshotName,
    required this.onRename,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onExport,
  });

  final String screenshotName;
  final void Function(String) onRename;
  final bool canUndo, canRedo;
  final VoidCallback onUndo, onRedo, onExport;

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: screenshotName);
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: Text('Rename screenshot', style: AppText.headline2()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Screenshot name',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: AppRadius.br10),
            enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.br10,
                borderSide: const BorderSide(
                    color: AppColors.borderDefault, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.br10,
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style:
                      AppText.labelLarge(color: AppColors.inkMuted))),
          TextButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                onRename(val);
              }
            },
            child: Text('Save',
                style: AppText.labelLarge(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s12),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: AppRadius.brFull,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 20),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showRenameDialog(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      screenshotName,
                      style: AppText.labelLarge(color: AppColors.inkSecondary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.pencil, size: 12, color: AppColors.inkMuted),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: canUndo ? onUndo : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(LucideIcons.rotateCcw, size: 20, color: canUndo ? AppColors.inkPrimary : AppColors.inkDisabled),
            ),
          ),
          GestureDetector(
            onTap: canRedo ? onRedo : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(LucideIcons.rotateCw, size: 20, color: canRedo ? AppColors.inkPrimary : AppColors.inkDisabled),
            ),
          ),
          Container(
              width: 1,
              height: 18,
              color: AppColors.borderDefault,
              margin: const EdgeInsets.symmetric(horizontal: 8)),
          GestureDetector(
            onTap: onExport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppRadius.brFull,
              ),
              child: Text('Export', style: AppText.labelLarge(color: AppColors.accentOn)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorBottomBar extends StatelessWidget {
  const _EditorBottomBar({
    required this.options,
    required this.onOpenLayers,
  });

  final List<Widget> options;
  final VoidCallback onOpenLayers;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s16),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brFull,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (options.isNotEmpty) ...[
            ...options,
            Container(
              width: 1,
              height: 32,
              color: AppColors.borderSubtle,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
          _ToolButton(
            icon: LucideIcons.layers,
            label: 'Layers',
            isActive: false,
            onTap: onOpenLayers,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton(
      {required this.icon, required this.label, required this.isActive, required this.onTap});
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.inkMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentTint : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppText.labelSmall(color: color).copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _LayersPanel extends StatelessWidget {
  const _LayersPanel({
    required this.layers,
    required this.selectedIndex,
    required this.onReorder,
    required this.onTap,
    required this.onDelete,
    required this.scrollController,
  });

  final List<Map<String, dynamic>> layers;
  final int? selectedIndex;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onTap;
  final void Function(int index) onDelete;
  final ScrollController scrollController;

  static IconData _iconForType(String type) => switch (type) {
        'background' => LucideIcons.square,
        'text' => LucideIcons.type,
        'phone' => LucideIcons.smartphone,
        'shape' => LucideIcons.shapes,
        'badge' => LucideIcons.tag,
        'feature_row' => LucideIcons.list,
        'image' => LucideIcons.image,
        'frosted_panel' => LucideIcons.layers,
        'accent_bar' => LucideIcons.minus,
        'divider' => LucideIcons.minus,
        _ => LucideIcons.box,
      };

  static String _labelForLayer(Map<String, dynamic> layer) {
    final type = layer['type'] as String? ?? 'layer';
    switch (type) {
      case 'background':
        return 'Background';
      case 'text':
        final c = layer['content'] as String? ?? '';
        if (c.contains('{headline}')) return 'Headline Text';
        if (c.contains('{subheadline}')) return 'Subheadline Text';
        if (c.length > 24) return '${c.substring(0, 24)}…';
        return c.isEmpty ? 'Text' : c;
      case 'phone':
        return 'Device Mockup';
      case 'shape':
        final shape = layer['shape_type'] as String? ?? 'Circle';
        final formattedShape = shape.isNotEmpty ? '${shape[0].toUpperCase()}${shape.substring(1)}' : 'Circle';
        return '$formattedShape Shape';
      case 'badge':
        final c = layer['content'] as String? ?? 'Badge';
        return c.length > 24 ? '${c.substring(0, 24)}…' : c;
      case 'feature_row':
        final icon = layer['icon'] ?? '●';
        final c = layer['content'] as String? ?? 'Feature';
        final formatted = c.length > 24 ? '${c.substring(0, 24)}…' : c;
        return '$icon $formatted';
      case 'image':
        return 'Image';
      case 'frosted_panel':
        return 'Frosted Panel';
      case 'accent_bar':
        return 'Accent Bar';
      case 'divider':
        return 'Divider';
      default:
        return type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reversed = layers.asMap().entries.toList().reversed.toList();

    return PropertySheetLayout(
      children: [
        Row(
          children: [
            Text('Layers', style: AppText.headline2()),
            const Spacer(),
            Text('${layers.length} layer${layers.length != 1 ? 's' : ''}', style: AppText.labelDefault(color: AppColors.inkMuted)),
          ],
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          scrollController: scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversed.length,
          onReorder: (oldI, newI) {
            if (oldI < newI) newI -= 1;
            final totalLen = layers.length;
            final realOld = totalLen - 1 - oldI;
            final realNew = totalLen - 1 - newI;
            onReorder(realOld, realNew);
          },
          itemBuilder: (ctx, i) {
            final entry = reversed[i];
            final realIndex = entry.key;
            final layer = entry.value;
            final type = layer['type'] as String? ?? '';
            final isSelected = selectedIndex == realIndex;
            final isDeletable = type != 'background';

            return Dismissible(
              key: ValueKey('layer_$realIndex'),
              direction: isDeletable ? DismissDirection.endToStart : DismissDirection.none,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppColors.destructiveTint, borderRadius: AppRadius.br12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: const Icon(LucideIcons.trash2, color: AppColors.destructive, size: 20),
              ),
              confirmDismiss: (direction) async {
                onDelete(realIndex);
                return false;
              },
              child: InkWell(
                onTap: () => onTap(realIndex),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentTint : AppColors.surface,
                    borderRadius: AppRadius.br12,
                    border: Border.all(color: isSelected ? AppColors.accent : AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconForType(type),
                          size: 16,
                          color: isSelected ? AppColors.accentOn : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelForLayer(layer),
                              style: AppText.labelLarge(color: isSelected ? AppColors.accent : AppColors.inkPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                              style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      if (isDeletable)
                        GestureDetector(
                          onTap: () => onDelete(realIndex),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(LucideIcons.trash2, size: 16, color: AppColors.destructive),
                          ),
                        ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(LucideIcons.gripVertical, size: 20, color: AppColors.inkDisabled),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LayerTextField extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  final String label;

  const _LayerTextField({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.label = 'Text Content',
  });

  @override
  State<_LayerTextField> createState() => _LayerTextFieldState();
}

class _LayerTextFieldState extends State<_LayerTextField> {
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  String? _lastTypedText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _lastTypedText = widget.initialText;
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(_LayerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText && _lastTypedText != widget.initialText) {
      final selection = _ctrl.selection;
      _ctrl.text = widget.initialText;
      _lastTypedText = widget.initialText;
      if (selection.isValid && selection.end <= _ctrl.text.length) {
        _ctrl.selection = selection;
      } else {
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _isFocused ? AppColors.surface : AppColors.surfaceMuted.withValues(alpha: 0.6),
            borderRadius: AppRadius.br12,
            border: Border.all(
              color: _isFocused ? AppColors.accent : AppColors.borderDefault,
              width: _isFocused ? 1.8 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10),
                child: Icon(
                  LucideIcons.type,
                  size: 18,
                  color: _isFocused ? AppColors.accent : AppColors.inkMuted,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 2,
                  style: AppText.bodyLarge(color: AppColors.inkPrimary).copyWith(
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Enter text content...',
                  ),
                  onChanged: (val) {
                    _lastTypedText = val;
                    setState(() {});
                    widget.onChanged(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
