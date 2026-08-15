import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _activePropertyCategory;
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
      _activePropertyCategory = null;
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
      _activePropertyCategory = null;
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
    if (type == 'background') return;

    setState(() {
      _selectedLayerIndex = index;
      _activePropertyCategory = null;
    });
  }

  void _onLongPressLayer(int index) {
    final type = _templateLayers[index]['type'] as String? ?? '';
    if (type == 'phone') {
      setState(() {
        _selectedLayerIndex = index;
        _activePropertyCategory = null;
      });
    }
  }

  void _deleteLayer(int index) {
    if (index < 0 || index >= _templateLayers.length) return;
    _pushUndo();
    setState(() {
      _templateLayers.removeAt(index);
      _selectedLayerIndex = null;
      _activePropertyCategory = null;
    });
    _save();
  }

  void _duplicateLayer(int index) {
    if (index < 0 || index >= _templateLayers.length) return;
    _pushUndo();
    final cloned = Map<String, dynamic>.from(_templateLayers[index]);
    if (cloned.containsKey('x') && cloned['x'] is num) {
      cloned['x'] = (cloned['x'] as num).toDouble() + 0.03;
    }
    if (cloned.containsKey('y') && cloned['y'] is num) {
      cloned['y'] = (cloned['y'] as num).toDouble() + 0.03;
    }
    setState(() {
      _templateLayers.insert(index + 1, cloned);
      _selectedLayerIndex = index + 1;
      _activePropertyCategory = null;
    });
    _save();
  }

  void _toggleVisibility(int index) {
    if (index < 0 || index >= _templateLayers.length) return;
    _pushUndo();
    final layer = Map<String, dynamic>.from(_templateLayers[index]);
    final currentVisible = layer['visible'] as bool? ?? true;
    layer['visible'] = !currentVisible;
    setState(() {
      _templateLayers[index] = layer;
    });
    _save();
  }

  void _toggleLock(int index) {
    if (index < 0 || index >= _templateLayers.length) return;
    _pushUndo();
    final layer = Map<String, dynamic>.from(_templateLayers[index]);
    final currentLocked = layer['locked'] as bool? ?? false;
    layer['locked'] = !currentLocked;
    setState(() {
      _templateLayers[index] = layer;
    });
    _save();
  }

  void _reorderLayers(int oldIndex, int newIndex) {
    _pushUndo();
    setState(() {
      final item = _templateLayers.removeAt(oldIndex);
      _templateLayers.insert(newIndex, item);
      _selectedLayerIndex = null;
      _activePropertyCategory = null;
    });
    _save();
  }

  void _showLayersPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
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
            onDuplicate: (index) {
              _duplicateLayer(index);
              setSheetState(() {});
            },
            onToggleVisibility: (index) {
              _toggleVisibility(index);
              setSheetState(() {});
            },
            onToggleLock: (index) {
              _toggleLock(index);
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
        layer['x'] = (layer['x'] as num? ?? 0.0) - dx;
      } else {
        layer['x'] = (layer['x'] as num? ?? 0.0) + dx;
      }
    }

    if (layer.containsKey('cy')) {
      layer['cy'] = (layer['cy'] as num? ?? 0.5) + dy;
    } else {
      final alignY = layer['align_y'] as String? ?? 'top';
      if (alignY == 'bottom') {
        layer['y'] = (layer['y'] as num? ?? 0.0) - dy;
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
    final bgIndex = _templateLayers.indexWhere((l) => l['type'] == 'background');
    final activeLayerIndex = _activePropertyCategory == 'background' 
        ? (bgIndex != -1 ? bgIndex : null) 
        : _selectedLayerIndex;
    final selectedLayer = (activeLayerIndex != null && activeLayerIndex >= 0 && activeLayerIndex < _templateLayers.length)
        ? _templateLayers[activeLayerIndex]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        if (_activePropertyCategory != null || _selectedLayerIndex != null) {
          setState(() {
            _activePropertyCategory = null;
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
                    useRootNavigator: true,
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
                                _activePropertyCategory = null;
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
                                    _activePropertyCategory = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
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

                    // Floating Live Compact Property Dock
                    if (_activePropertyCategory != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 8,
                        child: _FloatingPropertyDock(
                          category: _activePropertyCategory!,
                          selectedLayerIndex: activeLayerIndex,
                          layer: selectedLayer,
                          templateData: _templateData,
                          onClose: () => setState(() => _activePropertyCategory = null),
                          onUpdateLayer: (updatedLayer) {
                            final idxToUpdate = activeLayerIndex;
                            if (idxToUpdate != null && idxToUpdate >= 0 && idxToUpdate < _templateLayers.length) {
                              _pushUndo();
                              setState(() {
                                _templateLayers[idxToUpdate] = updatedLayer;
                              });
                              _debouncedSave();
                            }
                          },
                          onUpdateTemplateData: (updatedData) {
                            setState(() {
                              _templateData = updatedData;
                            });
                            _debouncedSave();
                          },
                          onPickImage: () {
                            if (_selectedLayerIndex != null) {
                              _pickScreenshotImage(_selectedLayerIndex!);
                            }
                          },
                          onSnapLeft: (l) => _snapLeft(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onSnapRight: (l) => _snapRight(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onSnapTop: (l) => _snapTop(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onSnapBottom: (l) => _snapBottom(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onSnapCenterH: (l) => _snapCenterH(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onSnapCenterV: (l) => _snapCenterV(l, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
                          onNudge: (l, dx, dy) => _nudgeLayer(l, dx, dy, (u) {
                            if (_selectedLayerIndex != null) {
                              _pushUndo();
                              setState(() => _templateLayers[_selectedLayerIndex!] = u);
                              _debouncedSave();
                            }
                          }),
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



  List<Widget> _buildContextualOptions() {
    if (_selectedLayerIndex == null) {
      return [
        _ToolButton(
          icon: LucideIcons.palette,
          label: 'Background',
          isActive: _activePropertyCategory == 'background',
          onTap: () {
            setState(() {
              _activePropertyCategory =
                  _activePropertyCategory == 'background' ? null : 'background';
            });
          },
        ),
      ];
    }

    final layer = _templateLayers[_selectedLayerIndex!];
    final type = layer['type'] as String? ?? '';
    final List<Widget> options = [];

    void toggleCategory(String cat) {
      setState(() {
        _activePropertyCategory = _activePropertyCategory == cat ? null : cat;
      });
    }

    if (type == 'text' || type == 'badge' || type == 'feature_row') {
      options.add(_ToolButton(icon: LucideIcons.type, label: 'Content', isActive: _activePropertyCategory == 'content', onTap: () => toggleCategory('content')));
      options.add(_ToolButton(icon: LucideIcons.palette, label: 'Style', isActive: _activePropertyCategory == 'style', onTap: () => toggleCategory('style')));
      options.add(_ToolButton(icon: LucideIcons.alignCenter, label: 'Align', isActive: _activePropertyCategory == 'align', onTap: () => toggleCategory('align')));
      options.add(_ToolButton(icon: LucideIcons.move, label: 'Position', isActive: _activePropertyCategory == 'position', onTap: () => toggleCategory('position')));
    } else if (type == 'phone' || type == 'image') {
      if (type == 'phone') {
        options.add(_ToolButton(icon: LucideIcons.smartphone, label: 'Mockup', isActive: _activePropertyCategory == 'mockup_style', onTap: () => toggleCategory('mockup_style')));
      }
      options.add(_ToolButton(icon: LucideIcons.box, label: '3D & Scale', isActive: _activePropertyCategory == 'transform', onTap: () => toggleCategory('transform')));
      options.add(_ToolButton(icon: LucideIcons.move, label: 'Position', isActive: _activePropertyCategory == 'position', onTap: () => toggleCategory('position')));
    } else if (type == 'shape' || type == 'accent_bar' || type == 'divider' || type == 'frosted_panel') {
      options.add(_ToolButton(icon: LucideIcons.palette, label: 'Appearance', isActive: _activePropertyCategory == 'appearance', onTap: () => toggleCategory('appearance')));
      options.add(_ToolButton(icon: LucideIcons.scaling, label: 'Size', isActive: _activePropertyCategory == 'transform', onTap: () => toggleCategory('transform')));
      options.add(_ToolButton(icon: LucideIcons.move, label: 'Position', isActive: _activePropertyCategory == 'position', onTap: () => toggleCategory('position')));
    } else {
      options.add(_ToolButton(icon: LucideIcons.slidersHorizontal, label: 'Style', isActive: _activePropertyCategory == 'style', onTap: () => toggleCategory('style')));
    }

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
      useRootNavigator: true,
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
          Material(
            color: AppColors.surfaceMuted,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(LucideIcons.arrowLeft, size: 20),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.br10,
              child: InkWell(
                borderRadius: AppRadius.br10,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showRenameDialog(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canUndo ? () { HapticFeedback.lightImpact(); onUndo(); } : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.rotateCcw, size: 20, color: canUndo ? AppColors.inkPrimary : AppColors.inkDisabled),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canRedo ? () { HapticFeedback.lightImpact(); onRedo(); } : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.rotateCw, size: 20, color: canRedo ? AppColors.inkPrimary : AppColors.inkDisabled),
              ),
            ),
          ),
          Container(
              width: 1,
              height: 18,
              color: AppColors.borderDefault,
              margin: const EdgeInsets.symmetric(horizontal: 4)),
          Material(
            color: AppColors.accent,
            borderRadius: AppRadius.brFull,
            child: InkWell(
              borderRadius: AppRadius.brFull,
              onTap: () {
                HapticFeedback.lightImpact();
                onExport();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Export', style: AppText.labelLarge(color: AppColors.accentOn)),
              ),
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom > 0 ? 8 : 16),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brFull,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: options,
                ),
              ),
            ),
            if (options.isNotEmpty)
              Container(
                width: 1,
                height: 32,
                color: AppColors.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            _ToolButton(
              icon: LucideIcons.layers,
              label: 'Layers',
              isActive: false,
              onTap: onOpenLayers,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingPropertyDock extends StatelessWidget {
  const _FloatingPropertyDock({
    required this.category,
    required this.selectedLayerIndex,
    required this.layer,
    required this.templateData,
    required this.onClose,
    required this.onUpdateLayer,
    required this.onUpdateTemplateData,
    required this.onPickImage,
    required this.onSnapLeft,
    required this.onSnapRight,
    required this.onSnapTop,
    required this.onSnapBottom,
    required this.onSnapCenterH,
    required this.onSnapCenterV,
    required this.onNudge,
  });

  final String category;
  final int? selectedLayerIndex;
  final Map<String, dynamic>? layer;
  final TemplateData templateData;
  final VoidCallback onClose;
  final ValueChanged<Map<String, dynamic>> onUpdateLayer;
  final ValueChanged<TemplateData> onUpdateTemplateData;
  final VoidCallback onPickImage;
  final ValueChanged<Map<String, dynamic>> onSnapLeft, onSnapRight, onSnapTop, onSnapBottom, onSnapCenterH, onSnapCenterV;
  final void Function(Map<String, dynamic> layer, double dx, double dy) onNudge;

  String _titleForCategory() {
    switch (category) {
      case 'content': return 'Text Content';
      case 'style': return 'Text Style';
      case 'align': return 'Alignment';
      case 'mockup_style': return 'Mockup & Source';
      case 'transform': return '3D & Dimensions';
      case 'appearance': return 'Appearance';
      case 'position': return 'Position & Alignment';
      case 'background': return 'Background Style';
      default: return 'Properties';
    }
  }

  Widget _buildContent(BuildContext context) {
    if (layer == null) return const SizedBox.shrink();
    final l = Map<String, dynamic>.from(layer!);
    final type = l['type'] as String? ?? '';

    switch (category) {
      case 'content':
        final rawContent = l['content'] as String? ?? '';
        final isHeadline = rawContent.contains('{headline}');
        final isSubheadline = rawContent.contains('{subheadline}');
        final initialText = isHeadline
            ? templateData.headline
            : isSubheadline
                ? templateData.subheadline
                : rawContent;
        return _LayerTextField(
          key: ValueKey('text_$selectedLayerIndex'),
          label: 'Text',
          initialText: initialText,
          onChanged: (val) {
            if (isHeadline) {
              onUpdateTemplateData(TemplateData(
                headline: val,
                subheadline: templateData.subheadline,
                headlineColor: templateData.headlineColor,
                subheadlineColor: templateData.subheadlineColor,
              ));
            } else if (isSubheadline) {
              onUpdateTemplateData(TemplateData(
                headline: templateData.headline,
                subheadline: val,
                headlineColor: templateData.headlineColor,
                subheadlineColor: templateData.subheadlineColor,
              ));
            } else {
              l['content'] = val;
              onUpdateLayer(l);
            }
          },
        );

      case 'style':
        return Column(
          children: [
            StyledInputNumeric(
              label: 'Font Size',
              value: ((l['font_size'] ?? 0.08) as num).toDouble() * 390.0,
              onChanged: (v) {
                l['font_size'] = v / 390.0;
                onUpdateLayer(l);
              },
            ),
            const SizedBox(height: 12),
            PropertyColorPicker(
              label: 'Text Color',
              hexColor: l['color'] ?? '#1A6B4A',
              onChanged: (v) {
                l['color'] = v;
                onUpdateLayer(l);
              },
            ),
          ],
        );

      case 'align':
        return TextAlignmentControl(
          value: l['text_align'] as String? ?? l['align'] as String? ?? 'left',
          onChanged: (v) {
            l['text_align'] = v;
            l['align'] = v;
            onUpdateLayer(l);
          },
        );

      case 'mockup_style':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StyledActionTile(
              label: 'Pick Image',
              icon: LucideIcons.image,
              onTap: onPickImage,
            ),
            MockupStyleSelector(
              value: l['style'] as String? ?? 'dynamic_island',
              onChanged: (v) {
                l['style'] = v;
                onUpdateLayer(l);
              },
            ),
          ],
        );

      case 'transform':
        if (type == 'phone' || type == 'image') {
          return Column(
            children: [
              PropertySlider(
                label: 'Scale',
                value: (l['scale'] ?? 1.0).toDouble(),
                min: 0.1,
                max: 3.0,
                valueFormatter: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) { l['scale'] = v; onUpdateLayer(l); },
              ),
              if (type == 'phone')
                PropertySlider(
                  label: 'Mockup Height',
                  value: (l['aspect_ratio'] ?? (19.5 / 9)).toDouble(),
                  min: 1.0,
                  max: 3.0,
                  valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
                  onChanged: (v) { l['aspect_ratio'] = v; onUpdateLayer(l); },
                ),
              PropertySlider(
                label: 'Z-Axis Rotation',
                value: (l['rotation'] ?? 0.0).toDouble(),
                min: -180.0,
                max: 180.0,
                valueFormatter: (v) => '${v.toInt()}°',
                onChanged: (v) { l['rotation'] = v; onUpdateLayer(l); },
              ),
              PropertySlider(
                label: 'X-Axis 3D Tilt',
                value: (l['rotation_x'] ?? 0.0).toDouble(),
                min: -60.0,
                max: 60.0,
                valueFormatter: (v) => '${v.toInt()}°',
                onChanged: (v) { l['rotation_x'] = v; onUpdateLayer(l); },
              ),
              PropertySlider(
                label: 'Y-Axis 3D Turn',
                value: (l['rotation_y'] ?? 0.0).toDouble(),
                min: -60.0,
                max: 60.0,
                valueFormatter: (v) => '${v.toInt()}°',
                onChanged: (v) { l['rotation_y'] = v; onUpdateLayer(l); },
              ),
              PropertySlider(
                label: 'Opacity',
                value: (l['opacity'] ?? 1.0).toDouble(),
                min: 0.0,
                max: 1.0,
                valueFormatter: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) { l['opacity'] = v; onUpdateLayer(l); },
              ),
            ],
          );
        } else {
          return Column(
            children: [
              PropertySlider(
                label: 'Width',
                value: (l['width'] ?? 0.8).toDouble(),
                min: 0.05,
                max: 1.5,
                valueFormatter: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) { l['width'] = v; onUpdateLayer(l); },
              ),
              PropertySlider(
                label: 'Height',
                value: (l['height'] ?? 0.8).toDouble(),
                min: 0.05,
                max: 1.5,
                valueFormatter: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) { l['height'] = v; onUpdateLayer(l); },
              ),
              PropertySlider(
                label: 'Rotation',
                value: (l['rotation'] ?? 0.0).toDouble(),
                min: -180.0,
                max: 180.0,
                valueFormatter: (v) => '${v.toInt()}°',
                onChanged: (v) { l['rotation'] = v; onUpdateLayer(l); },
              ),
            ],
          );
        }

      case 'appearance':
        return Column(
          children: [
            PropertyColorPicker(
              label: 'Color',
              hexColor: l['color'] ?? '#1A6B4A',
              onChanged: (v) { l['color'] = v; onUpdateLayer(l); },
            ),
            const SizedBox(height: 12),
            PropertySlider(
              label: 'Opacity',
              value: (l['opacity'] ?? 1.0).toDouble(),
              min: 0.0,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) { l['opacity'] = v; onUpdateLayer(l); },
            ),
            if (type == 'shape' || type == 'frosted_panel')
              PropertySlider(
                label: 'Border Radius',
                value: (l['border_radius'] ?? 12.0).toDouble(),
                min: 0.0,
                max: 100.0,
                onChanged: (v) { l['border_radius'] = v; onUpdateLayer(l); },
              ),
            if (type == 'frosted_panel')
              PropertySlider(
                label: 'Blur Amount',
                value: (l['blur'] ?? 10.0).toDouble(),
                min: 0.0,
                max: 40.0,
                valueFormatter: (v) => '${v.toInt()} px',
                onChanged: (v) { l['blur'] = v; onUpdateLayer(l); },
              ),
          ],
        );

      case 'position':
        return Column(
          children: [
            PositionPresets(
              onSnapLeft: () => onSnapLeft(l),
              onSnapRight: () => onSnapRight(l),
              onSnapTop: () => onSnapTop(l),
              onSnapBottom: () => onSnapBottom(l),
              onSnapCenterH: () => onSnapCenterH(l),
              onSnapCenterV: () => onSnapCenterV(l),
            ),
            const SizedBox(height: 16),
            StyledPositionNudge(
              onUp: () => onNudge(l, 0, -0.01),
              onDown: () => onNudge(l, 0, 0.01),
              onLeft: () => onNudge(l, -0.01, 0),
              onRight: () => onNudge(l, 0.01, 0),
            ),
          ],
        );

      case 'background':
        return _BackgroundDockControlView(
          layer: l,
          onUpdateLayer: onUpdateLayer,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = (MediaQuery.of(context).size.height * 0.45).clamp(220.0, 360.0);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 520),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: AppRadius.br20,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: AppShadows.float,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _titleForCategory().toUpperCase(),
                style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, size: 14, color: AppColors.inkPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borderSubtle, thickness: 1, height: 1),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDockControlView extends StatefulWidget {
  const _BackgroundDockControlView({
    required this.layer,
    required this.onUpdateLayer,
  });

  final Map<String, dynamic> layer;
  final ValueChanged<Map<String, dynamic>> onUpdateLayer;

  @override
  State<_BackgroundDockControlView> createState() => _BackgroundDockControlViewState();
}

class _BackgroundDockControlViewState extends State<_BackgroundDockControlView> {
  int _tabIndex = 0; // 0: Solid, 1: Gradient, 2: Split

  @override
  Widget build(BuildContext context) {
    final l = Map<String, dynamic>.from(widget.layer);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TogglePillGroup(
          options: const ['Solid', 'Gradient', 'Split'],
          selectedValue: _tabIndex == 0 ? 'Solid' : (_tabIndex == 1 ? 'Gradient' : 'Split'),
          onChanged: (val) {
            setState(() {
              if (val == 'Solid') {
                _tabIndex = 0;
              } else if (val == 'Gradient') {
                _tabIndex = 1;
              } else {
                _tabIndex = 2;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        if (_tabIndex == 0) ...[
          PropertyColorPicker(
            label: 'Solid Color',
            hexColor: l['color'] as String? ?? '#FAF9F6',
            onChanged: (c) {
              l['color'] = c;
              l.remove('gradient');
              l.remove('split_at');
              widget.onUpdateLayer(l);
            },
          ),
        ] else if (_tabIndex == 1) ...[
          PropertyColorPicker(
            label: 'Start Color',
            hexColor: (l['gradient'] as List?)?[0] as String? ?? '#0082FF',
            onChanged: (c) {
              if (l['gradient'] == null) l['gradient'] = ['#0082FF', '#0040A3'];
              l['gradient'][0] = c;
              l.remove('color');
              l.remove('split_at');
              widget.onUpdateLayer(l);
            },
          ),
          const SizedBox(height: 8),
          PropertyColorPicker(
            label: 'End Color',
            hexColor: (l['gradient'] as List?)?[1] as String? ?? '#0040A3',
            onChanged: (c) {
              if (l['gradient'] == null) l['gradient'] = ['#0082FF', '#0040A3'];
              l['gradient'][1] = c;
              l.remove('color');
              l.remove('split_at');
              widget.onUpdateLayer(l);
            },
          ),
        ] else ...[
          PropertyColorPicker(
            label: 'Top Color',
            hexColor: l['top_color'] as String? ?? '#FAF9F6',
            onChanged: (c) {
              l['top_color'] = c;
              if (l['split_at'] == null) l['split_at'] = 0.5;
              l.remove('color');
              l.remove('gradient');
              widget.onUpdateLayer(l);
            },
          ),
          const SizedBox(height: 8),
          PropertyColorPicker(
            label: 'Bottom Color',
            hexColor: l['bottom_color'] as String? ?? '#F5F7F5',
            onChanged: (c) {
              l['bottom_color'] = c;
              if (l['split_at'] == null) l['split_at'] = 0.5;
              l.remove('color');
              l.remove('gradient');
              widget.onUpdateLayer(l);
            },
          ),
          const SizedBox(height: 8),
          PropertySlider(
            label: 'Split Ratio',
            value: (l['split_at'] as num?)?.toDouble() ?? 0.5,
            min: 0.1,
            max: 0.9,
            valueFormatter: (v) => '${(v * 100).toInt()}%',
            onChanged: (v) {
              l['split_at'] = v;
              widget.onUpdateLayer(l);
            },
          ),
        ],
      ],
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
    return Material(
      color: isActive ? AppColors.accentTint : Colors.transparent,
      borderRadius: AppRadius.brFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        splashColor: isActive
            ? Colors.transparent
            : AppColors.accent.withValues(alpha: 0.14),
        highlightColor: isActive
            ? Colors.transparent
            : AppColors.accent.withValues(alpha: 0.06),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(label, style: AppText.labelSmall(color: color).copyWith(fontSize: 10)),
            ],
          ),
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
    required this.onDuplicate,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.scrollController,
  });

  final List<Map<String, dynamic>> layers;
  final int? selectedIndex;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onTap;
  final void Function(int index) onDelete;
  final void Function(int index) onDuplicate;
  final void Function(int index) onToggleVisibility;
  final void Function(int index) onToggleLock;
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
        return 'Background Canvas';
      case 'text':
        final c = layer['content'] as String? ?? '';
        if (c.contains('{headline}')) return 'Headline Text';
        if (c.contains('{subheadline}')) return 'Subheadline Text';
        if (c.length > 22) return '${c.substring(0, 22)}…';
        return c.isEmpty ? 'Text Block' : c;
      case 'phone':
        final style = layer['mockup_style'] as String? ?? 'Flat';
        return 'Phone Mockup ($style)';
      case 'shape':
        final shape = layer['shape_type'] as String? ?? 'Circle';
        final formattedShape = shape.isNotEmpty ? '${shape[0].toUpperCase()}${shape.substring(1)}' : 'Circle';
        return '$formattedShape Shape';
      case 'badge':
        final c = layer['content'] as String? ?? 'Badge';
        return c.length > 22 ? '${c.substring(0, 22)}…' : c;
      case 'feature_row':
        final icon = layer['icon'] ?? '●';
        final c = layer['content'] as String? ?? 'Feature';
        final formatted = c.length > 22 ? '${c.substring(0, 22)}…' : c;
        return '$icon $formatted';
      case 'image':
        return 'Image Element';
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

  static String _subtitleForLayer(Map<String, dynamic> layer) {
    final type = layer['type'] as String? ?? 'layer';
    final opacity = ((layer['opacity'] as num? ?? 1.0) * 100).toInt();
    final isLocked = layer['locked'] as bool? ?? false;
    final isVisible = layer['visible'] as bool? ?? true;

    final List<String> details = [];
    if (!isVisible) details.add('Hidden');
    if (isLocked) details.add('Locked');

    switch (type) {
      case 'text':
        final fontSize = (((layer['font_size'] ?? 0.08) as num) * 390).round();
        details.add('${fontSize}px');
        break;
      case 'phone':
        final scale = (((layer['scale'] ?? 1.0) as num) * 100).round();
        details.add('$scale% scale');
        break;
      case 'shape':
        final shape = layer['shape_type'] as String? ?? 'shape';
        details.add(shape);
        break;
      default:
        break;
    }

    if (opacity < 100) details.add('$opacity% opacity');
    return details.isEmpty ? type.toUpperCase() : details.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final reversed = layers
        .asMap()
        .entries
        .where((e) => e.value['type'] != 'background')
        .toList()
        .reversed
        .toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
          boxShadow: AppShadows.float,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
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

              // ── Studio Header ─────────────────────────────────────────────
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
                        LucideIcons.layers,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Layers',
                                style: AppText.headline2().copyWith(fontSize: 17),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTint,
                                  borderRadius: BorderRadius.circular(AppRadius.r6),
                                ),
                                child: Text(
                                  '${reversed.length} items',
                                  style: AppText.labelSmall(color: AppColors.accent).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Top-to-bottom depth stack • Drag to adjust hierarchy',
                            style: AppText.bodySmall(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, size: 14, color: AppColors.inkPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.borderSubtle, height: 1),

              // ── Reorderable Layer List ─────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reversed.length,
                        onReorderStart: (_) {
                          HapticFeedback.mediumImpact();
                        },
                        proxyDecorator: (Widget child, int index, Animation<double> animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final t = Curves.easeOutCubic.transform(animation.value);
                              final scale = ui.lerpDouble(1.0, 1.025, t)!;
                              final elevation = ui.lerpDouble(0.0, 14.0, t)!;
                              return Transform.scale(
                                scale: scale,
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: elevation,
                                  shadowColor: AppColors.accent.withValues(alpha: 0.3),
                                  borderRadius: AppRadius.br12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: AppRadius.br12,
                                      border: Border.all(color: AppColors.accent, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.18),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        onReorder: (oldI, newI) {
                          if (oldI < newI) newI -= 1;
                          final realOld = reversed[oldI].key;
                          final realNew = reversed[newI].key;
                          onReorder(realOld, realNew);
                        },
                        itemBuilder: (ctx, i) {
                          final entry = reversed[i];
                          final realIndex = entry.key;
                          final layer = entry.value;
                          final type = layer['type'] as String? ?? '';
                          final isSelected = selectedIndex == realIndex;
                          final isLocked = layer['locked'] as bool? ?? false;
                          final isVisible = layer['visible'] as bool? ?? true;
                          final zIndexNum = reversed.length - i;

                          return Container(
                            key: ValueKey('layer_$realIndex'),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentTint.withValues(alpha: 0.8)
                                  : AppColors.surfaceMuted.withValues(alpha: 0.45),
                              borderRadius: AppRadius.br12,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.borderSubtle,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: AppColors.accent.withValues(alpha: 0.12),
                                highlightColor: AppColors.accent.withValues(alpha: 0.05),
                                onTap: () => onTap(realIndex),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: Row(
                                    children: [
                                      // 1. Z-Index Depth Badge
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.surface,
                                          borderRadius: AppRadius.br6,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accent
                                                : AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$zIndexNum',
                                            style: AppText.mono(
                                              color: isSelected
                                                  ? AppColors.accentOn
                                                  : AppColors.inkMuted,
                                            ).copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // 2. Type Icon Badge
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.accent.withValues(alpha: 0.15)
                                              : AppColors.surface,
                                          borderRadius: AppRadius.br10,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accent.withValues(alpha: 0.3)
                                                : AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _iconForType(type),
                                            size: 15,
                                            color: isSelected
                                                ? AppColors.accent
                                                : isVisible
                                                    ? AppColors.inkPrimary
                                                    : AppColors.inkDisabled,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // 3. Label & Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _labelForLayer(layer),
                                              style: AppText.labelLarge(
                                                color: isVisible
                                                    ? AppColors.inkPrimary
                                                    : AppColors.inkDisabled,
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _subtitleForLayer(layer),
                                              style: AppText.bodySmall(
                                                color: isSelected
                                                    ? AppColors.accent
                                                    : AppColors.inkMuted,
                                              ).copyWith(fontSize: 10.5),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 4. Micro-Actions Row
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Visibility Toggle
                                          _LayerIconButton(
                                            icon: isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                                            isActive: !isVisible,
                                            activeColor: AppColors.inkDisabled,
                                            tooltip: isVisible ? 'Hide layer' : 'Show layer',
                                            onTap: () => onToggleVisibility(realIndex),
                                          ),
                                          // Lock Toggle
                                          _LayerIconButton(
                                            icon: isLocked ? LucideIcons.lock : LucideIcons.unlock,
                                            isActive: isLocked,
                                            activeColor: AppColors.accent,
                                            tooltip: isLocked ? 'Unlock layer' : 'Lock layer',
                                            onTap: () => onToggleLock(realIndex),
                                          ),
                                          // Duplicate
                                          _LayerIconButton(
                                            icon: LucideIcons.copy,
                                            tooltip: 'Duplicate layer',
                                            onTap: () => onDuplicate(realIndex),
                                          ),
                                          // Delete
                                          _LayerIconButton(
                                            icon: LucideIcons.trash2,
                                            isDestructive: true,
                                            tooltip: 'Delete layer',
                                            onTap: () => onDelete(realIndex),
                                          ),
                                          const SizedBox(width: 4),

                                          // 5. Reorder Drag Grip Handle
                                          ReorderableDragStartListener(
                                            index: i,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius: AppRadius.br6,
                                                border: Border.all(color: AppColors.borderSubtle),
                                              ),
                                              child: const Icon(
                                                LucideIcons.gripVertical,
                                                size: 16,
                                                color: AppColors.inkSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),

                      // ── Pinned Base Background Foundation Card ───────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted.withValues(alpha: 0.3),
                          borderRadius: AppRadius.br12,
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.br6,
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Center(
                                child: Text(
                                  '#0',
                                  style: AppText.mono(color: AppColors.inkDisabled).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.br10,
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.square, size: 15, color: AppColors.inkMuted),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Canvas Foundation (Background)',
                                    style: AppText.labelLarge(color: AppColors.inkSecondary).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'CANVAS ROOT • ALWAYS AT BOTTOM',
                                    style: AppText.mono(color: AppColors.inkDisabled).copyWith(fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.br6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.lock, size: 12, color: AppColors.inkMuted),
                                  const SizedBox(width: 4),
                                  Text('Base', style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}

/// Compact interactive icon button inside layer items for quick micro-actions.
class _LayerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;
  final Color? activeColor;
  final String? tooltip;

  const _LayerIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
    this.activeColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.destructive
        : isActive
            ? (activeColor ?? AppColors.accent)
            : AppColors.inkMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.br6,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            size: 15,
            color: color,
          ),
        ),
      ),
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
