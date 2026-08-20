import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aperlo/widgets/adaptive_image.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';


// ─────────────────────────────────────────────────────────────────────────────
// TemplateData  – editable fields the user controls in the editor
// ─────────────────────────────────────────────────────────────────────────────

class TemplateData {
  const TemplateData({
    this.headline = 'Your headline here',
    this.subheadline = 'A short description that tells users what they get',
    this.screenshotImage,
    this.headlineColor,
    this.subheadlineColor,
  });

  final String headline;
  final String subheadline;
  final ImageProvider? screenshotImage;
  final Color? headlineColor;
  final Color? subheadlineColor;

  TemplateData copyWith({
    String? headline,
    String? subheadline,
    ImageProvider? screenshotImage,
    Color? headlineColor,
    Color? subheadlineColor,
  }) =>
      TemplateData(
        headline: headline ?? this.headline,
        subheadline: subheadline ?? this.subheadline,
        screenshotImage: screenshotImage ?? this.screenshotImage,
        headlineColor: headlineColor ?? this.headlineColor,
        subheadlineColor: subheadlineColor ?? this.subheadlineColor,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DynamicTemplate  – the main widget
//
// Layer types (render bottom-to-top):
//   background     – solid color, linear gradient, radial gradient, split
//   text           – positioned text; supports {headline} & {subheadline}
//   phone          – phone mockup  (style: dynamic_island | circle_notch |
//                    bar_notch | punch_hole | flat | none)
//   shape          – circle, rect, rounded_rect, polygon, arc, ring, blob,
//                    diagonal_split, star
//   accent_bar     – thin colored bar / divider
//   badge          – pill-shaped label with optional icon char
//   feature_row    – icon char + text row (for feature lists)
//   image          – network or asset image with fit / opacity
//   frosted_panel  – blurred glass panel with optional border
//   divider        – horizontal rule
//
// All x/y/width/height values are 0.0–1.0 fractions of canvas size.
// ─────────────────────────────────────────────────────────────────────────────

class DynamicTemplate extends StatelessWidget {
  const DynamicTemplate({super.key, 
    required this.layers,
    required this.headline,
    required this.subheadline,
    this.headlineColor,
    this.subheadlineColor,
    this.headlineFont = 'Syne',
    this.subheadlineFont = 'DM Sans',
    this.screenshotImage,
    this.canvasWidth = 390,
    this.canvasHeight = 844,
    this.onTapLayer,
    this.onPanUpdateLayer,
    this.onPanEndLayer,
    this.onLongPressLayer,
    this.onTapPhone,
    this.deviceFrameColor,
    this.selectedLayerIndex,
  });

  final List<Map<String, dynamic>> layers;
  final String headline;
  final String subheadline;
  final Color? headlineColor;
  final Color? subheadlineColor;
  final String headlineFont;
  final String subheadlineFont;
  final ImageProvider? screenshotImage;
  final double canvasWidth;
  final double canvasHeight;
  /// Called whenever ANY layer is tapped in the editor. Index is the layer's
  /// position in [layers].
  final void Function(int index)? onTapLayer;
  final void Function(int index, Offset delta)? onPanUpdateLayer;
  final void Function(int index)? onPanEndLayer;
  final void Function(int index)? onLongPressLayer;
  final void Function(int index)? onTapPhone;
  final Color? deviceFrameColor;
  /// The index of the currently selected layer — shown with a highlight ring.
  final int? selectedLayerIndex;

  @override
  Widget build(BuildContext context) {
    final safeLayers = <Widget>[];
    final bleedLayers = <Widget>[];

    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final type = layer['type'] as String? ?? '';
      final pinning = layer['pinning'] as String? ?? (type == 'background' ? 'bleed' : 'safe');
      
      if (pinning == 'bleed') {
        bleedLayers.add(_buildLayerWithTap(i, layer, canvasWidth, canvasHeight));
      } else {
        safeLayers.add(_buildLayerWithTap(i, layer, canvasWidth, canvasHeight, isSafe: true));
      }
    }

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ...bleedLayers,
            if (safeLayers.isNotEmpty)
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1320 / 2868,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < layers.length; i++)
                              if ((layers[i]['pinning'] as String? ?? (layers[i]['type'] == 'background' ? 'bleed' : 'safe')) != 'bleed')
                                _buildLayerWithTap(i, layers[i], constraints.maxWidth, constraints.maxHeight)
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerWithTap(int index, Map<String, dynamic> layer, double w, double h, {bool isSafe = false}) {
    return _buildLayer(index, layer, w, h);
  }

  Widget _buildLayer(int index, Map<String, dynamic> layer, double w, double h) {
    final type = layer['type'] as String? ?? '';
    final isVisible = layer['visible'] as bool? ?? true;
    if (!isVisible && type != 'background') {
      return const SizedBox.shrink();
    }
    final isLocked = layer['locked'] as bool? ?? false;
    final isSelected = selectedLayerIndex == index;
    final onTap = (!isLocked && onTapLayer != null) ? () => onTapLayer!(index) : null;
    final onPanUpdate = (!isLocked && isSelected && onPanUpdateLayer != null) ? (Offset d) => onPanUpdateLayer!(index, d) : null;
    switch (type) {
      case 'background':
        return _Background(layer: layer, w: w, h: h);
      case 'text':
        return _TextLayer(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          headline: headline,
          subheadline: subheadline,
          headlineColor: headlineColor,
          subheadlineColor: subheadlineColor,
          headlineFont: headlineFont,
          subheadlineFont: subheadlineFont,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'phone':
        ImageProvider? localScreenshot = screenshotImage;
        final path = layer['screenshotPath'] as String?;
        if (path != null) {
          if (path.startsWith('http')) {
            localScreenshot = NetworkImage(path);
          } else if (File(path).existsSync()) {
            localScreenshot = FileImage(File(path));
          }
        }
        
        void onTapPhoneCallback() {
          if (onTapPhone != null) {
            onTapPhone!(index);
          } else {
            onTap?.call();
          }
        }

        return _PhoneLayer(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: onLongPressLayer != null ? () => onLongPressLayer!(index) : null,
          screenshot: localScreenshot,
          onTap: onTapPhoneCallback,
          deviceFrameColor: deviceFrameColor,
          isSelected: isSelected,
        );
      case 'pattern':
      case 'pattern_overlay':
        return _PatternOverlayLayer(
          layer: layer,
          w: w,
          h: h,
          isSelected: isSelected,
          index: index,
          onTap: onTap,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
        );
      case 'shape':
        return _ShapeLayer(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'accent_bar':
        return _AccentBar(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'badge':
        return _BadgeLayer(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          headline: headline,
          subheadline: subheadline,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'feature_row':
        return _FeatureRow(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'image':
        return _ImageLayer(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'frosted_panel':
        return _FrostedPanel(
          layer: layer,
          w: w,
          h: h,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          headline: headline,
          subheadline: subheadline,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      case 'divider':
        return _DividerLayer(
          layer: layer,
          w: canvasWidth,
          h: canvasHeight,
          onPanUpdate: onPanUpdate,
          onPanEnd: (isSelected && onPanEndLayer != null) ? () => onPanEndLayer!(index) : null,
          onLongPress: null,
          isSelected: isSelected,
          onTap: onTap,
          index: index,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _color(dynamic val, [Color fallback = const Color(0xFF141A14)]) {
  if (val == null) return fallback;
  if (val is int) return Color(val);
  if (val is String) {
    if (val.isEmpty) return fallback;
    try {
      final hex = val.replaceFirst('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}

double _f(dynamic val, [double fallback = 0]) =>
    val == null ? fallback : (val as num).toDouble();

String _resolveText(String template, String headline, String subheadline) =>
    template
        .replaceAll('{headline}', headline)
        .replaceAll('{subheadline}', subheadline);

Alignment _alignment(String? v) => switch (v) {
      'topLeft' => Alignment.topLeft,
      'topRight' => Alignment.topRight,
      'topCenter' => Alignment.topCenter,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomRight' => Alignment.bottomRight,
      'centerLeft' => Alignment.centerLeft,
      'centerRight' => Alignment.centerRight,
      'center' => Alignment.center,
      _ => Alignment.topCenter,
    };

Widget _withSelection(Widget child, bool isSelected) {
  if (!isSelected) return child;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF1A6B4A),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6B4A).withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

TextStyle _googleFont(String name, TextStyle base) {
  try {
    return GoogleFonts.getFont(name, textStyle: base);
  } catch (e) {
    // If the font name is invalid or not available in Google Fonts, fallback to DM Sans.
    return GoogleFonts.dmSans(textStyle: base);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background({
    required this.layer,
    required this.w,
    required this.h,
  });

  final Map<String, dynamic> layer;
  final double w, h;

  @override
  Widget build(BuildContext context) {
    final bgType = layer['bg_type'] as String? ?? _inferBgType(layer);

    // ── Pattern background (Grid, Dots, Stripes, Rays) ────────────────────
    if (bgType == 'grid' || bgType == 'dots' || bgType == 'stripes' || bgType == 'rays') {
      return SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          size: Size(w, h),
          painter: _BackgroundPatternPainter(
            layer: layer,
            bgType: bgType,
          ),
        ),
      );
    }

    // ── Split background ──────────────────────────────────────────────────
    final splitAt = _f(layer['split_at']);
    final warp = _f(layer['bg_warp'], 0.0);
    if (bgType == 'split' || splitAt > 0) {
      if (warp > 0) {
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            size: Size(w, h),
            painter: _WarpSplitPainter(
              topColor: _color(layer['top_color'] ?? layer['color'], const Color(0xFFFAF9F6)),
              bottomColor: _color(layer['bottom_color'], const Color(0xFFF5F7F5)),
              splitAt: splitAt > 0 ? splitAt : 0.5,
              warp: warp,
            ),
          ),
        );
      }
      return SizedBox(
        width: w,
        height: h,
        child: Column(
          children: [
            Container(
                height: h * (splitAt > 0 ? splitAt : 0.5),
                color: _color(layer['top_color'] ?? layer['color'], const Color(0xFFFAF9F6))),
            Expanded(
                child: Container(
                    color: _color(layer['bottom_color'],
                        const Color(0xFFF5F7F5)))),
          ],
        ),
      );
    }

    // ── Radial gradient ───────────────────────────────────────────────────
    final radialColors = layer['radial_gradient'] as List?;
    if (bgType == 'radial' || (radialColors != null && radialColors.length >= 2)) {
      final rColors = radialColors != null && radialColors.length >= 2
          ? radialColors.map((c) => _color(c)).toList()
          : [_color(layer['color'], const Color(0xFF0082FF)), _color(layer['end_color'], const Color(0xFF0040A3))];
      if (warp > 0) {
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            size: Size(w, h),
            painter: _WarpGradientPainter(
              colors: rColors,
              begin: _alignment(layer['radial_center'] as String?),
              end: Alignment.bottomRight,
              warp: warp,
            ),
          ),
        );
      }
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: _alignment(layer['radial_center'] as String?),
            radius: _f(layer['radial_radius'], 0.8),
            colors: rColors,
            stops: (layer['radial_stops'] as List?)
                    ?.map((s) => _f(s))
                    .toList() ??
                [0.0, 1.0],
          ),
        ),
      );
    }

    // ── Linear gradient ───────────────────────────────────────────────────
    final gradColors = layer['gradient'] as List?;
    if (bgType == 'linear' || (gradColors != null && gradColors.length >= 2)) {
      final gColors = gradColors != null && gradColors.length >= 2
          ? gradColors.map((c) => _color(c)).toList()
          : [_color(layer['color'], const Color(0xFF0082FF)), _color(layer['end_color'], const Color(0xFF0040A3))];
      if (warp > 0) {
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            size: Size(w, h),
            painter: _WarpGradientPainter(
              colors: gColors,
              begin: _alignment(layer['begin'] as String?),
              end: _alignment(layer['end'] as String? ?? 'bottomCenter'),
              warp: warp,
            ),
          ),
        );
      }
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _alignment(layer['begin'] as String?),
            end: _alignment(layer['end'] as String? ?? 'bottomCenter'),
            colors: gColors,
            stops: (layer['stops'] as List?)
                    ?.map((s) => _f(s))
                    .toList(),
          ),
        ),
      );
    }

    // ── Solid color ───────────────────────────────────────────────────────
    return Container(
      width: w,
      height: h,
      color: _color(layer['color'] ?? layer['bg_color'], const Color(0xFFF5F7F5)),
    );
  }

  static String _inferBgType(Map<String, dynamic> l) {
    final explicit = (l['bg_type'] as String?)?.toLowerCase();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (l['grid'] == true || l['grid_spacing'] != null || l['grid_line_width'] != null) return 'grid';
    if (l['dots'] == true || l['dot_spacing'] != null || l['dot_size'] != null) return 'dots';
    if (l['stripes'] == true || l['stripe_spacing'] != null || l['stripe_width'] != null) return 'stripes';
    if (l['rays'] == true || l['ray_count'] != null) return 'rays';
    if (l['split_at'] != null) return 'split';
    if (l['radial_gradient'] != null) return 'radial';
    if (l['gradient'] != null) return 'linear';
    return 'solid';
  }
}

class _WarpSplitPainter extends CustomPainter {
  const _WarpSplitPainter({
    required this.topColor,
    required this.bottomColor,
    required this.splitAt,
    required this.warp,
  });

  final Color topColor;
  final Color bottomColor;
  final double splitAt;
  final double warp;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 375.0).clamp(0.2, 20.0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bottomColor);
    final splitY = size.height * splitAt;
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, splitY);
    final stepX = (10.0 * scale).clamp(2.0, 30.0);
    for (double x = 0; x <= size.width + stepX; x += stepX) {
      final wave = (math.sin((x / size.width) * 2 * math.pi) * (50.0 * warp) +
          math.cos((x / size.width) * 4 * math.pi) * (20.0 * warp)) * scale;
      topPath.lineTo(x, splitY + wave);
    }
    topPath
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);
  }

  @override
  bool shouldRepaint(covariant _WarpSplitPainter old) =>
      old.topColor != topColor ||
      old.bottomColor != bottomColor ||
      old.splitAt != splitAt ||
      old.warp != warp;
}

class _WarpGradientPainter extends CustomPainter {
  const _WarpGradientPainter({
    required this.colors,
    required this.begin,
    required this.end,
    required this.warp,
  });

  final List<Color> colors;
  final Alignment begin;
  final Alignment end;
  final double warp;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 375.0).clamp(0.2, 20.0);
    final basePaint = Paint()
      ..shader = LinearGradient(begin: begin, end: end, colors: colors)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final c1 = colors.first.withValues(alpha: (0.45 * warp).clamp(0.0, 1.0));
    final c2 = colors.last.withValues(alpha: (0.55 * warp).clamp(0.0, 1.0));

    final stepX = (10.0 * scale).clamp(2.0, 30.0);
    final wavePath1 = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width + stepX; x += stepX) {
      final y = size.height * 0.5 + math.sin((x / size.width) * 2 * math.pi) * (70.0 * warp * scale);
      wavePath1.lineTo(x, y);
    }
    wavePath1
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(wavePath1, Paint()..color = c2);

    final wavePath2 = Path()..moveTo(0, 0);
    for (double x = 0; x <= size.width + stepX; x += stepX) {
      final y = size.height * 0.35 + math.cos((x / size.width) * 2.5 * math.pi) * (60.0 * warp * scale);
      wavePath2.lineTo(x, y);
    }
    wavePath2
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(wavePath2, Paint()..color = c1);
  }

  @override
  bool shouldRepaint(covariant _WarpGradientPainter old) =>
      old.colors != colors || old.begin != begin || old.end != end || old.warp != warp;
}

class _BackgroundPatternPainter extends CustomPainter {
  const _BackgroundPatternPainter({
    required this.layer,
    required this.bgType,
  });

  final Map<String, dynamic> layer;
  final String bgType;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw base background
    final baseColor = _color(layer['bg_color'] ?? layer['color'], const Color(0xFFFAF9F6));
    final gradColors = layer['gradient'] as List?;
    if (gradColors != null && gradColors.length >= 2) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: _alignment(layer['begin'] as String?),
          end: _alignment(layer['end'] as String? ?? 'bottomCenter'),
          colors: gradColors.map((c) => _color(c)).toList(),
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = baseColor,
      );
    }

    final scale = (size.width / 375.0).clamp(0.2, 20.0);
    final warp = _f(layer['bg_warp'], 0.0);

    // 2. Draw Pattern Overlay
    switch (bgType) {
      case 'grid':
        final gridColor = _color(layer['grid_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: _f(layer['grid_opacity'] ?? layer['pattern_opacity'], 0.15).clamp(0.0, 1.0));
        final rawLineWidth = _f(layer['grid_line_width'], 1.5);
        final rawSpacing = _f(layer['grid_spacing'], 32.0);
        final gridAngle = _f(layer['grid_angle'], 0.0);

        final lineWidth = (rawLineWidth * scale).clamp(0.5, 40.0);
        final spacing = (rawSpacing * scale).clamp(6.0, 500.0);

        final gridPaint = Paint()
          ..color = gridColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;

        if (gridAngle != 0) {
          canvas.save();
          canvas.translate(size.width / 2, size.height / 2);
          canvas.rotate(gridAngle * math.pi / 180);
          final diag = math.sqrt(size.width * size.width + size.height * size.height);
          final stepY = (15.0 * scale).clamp(4.0, 40.0);
          
          if (warp > 0) {
            for (double x = -diag; x <= diag; x += spacing) {
              final path = Path();
              path.moveTo(x + math.sin((-diag / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale), -diag);
              for (double y = -diag + stepY; y <= diag; y += stepY) {
                final dx = math.sin((y / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x + dx, y);
              }
              canvas.drawPath(path, gridPaint);
            }
            for (double y = -diag; y <= diag; y += spacing) {
              final path = Path();
              path.moveTo(-diag, y + math.cos((-diag / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale));
              for (double x = -diag + stepY; x <= diag; x += stepY) {
                final dy = math.cos((x / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x, y + dy);
              }
              canvas.drawPath(path, gridPaint);
            }
          } else {
            for (double x = -diag; x <= diag; x += spacing) {
              canvas.drawLine(Offset(x, -diag), Offset(x, diag), gridPaint);
            }
            for (double y = -diag; y <= diag; y += spacing) {
              canvas.drawLine(Offset(-diag, y), Offset(diag, y), gridPaint);
            }
          }
          canvas.restore();
        } else {
          final stepY = (15.0 * scale).clamp(4.0, 40.0);
          if (warp > 0) {
            for (double x = 0; x <= size.width + spacing; x += spacing) {
              final path = Path();
              path.moveTo(x + math.sin(x / (60.0 * scale)) * (30.0 * warp * scale), 0);
              for (double y = stepY; y <= size.height + stepY; y += stepY) {
                final dx = math.sin((y / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x + dx, y);
              }
              canvas.drawPath(path, gridPaint);
            }
            for (double y = 0; y <= size.height + spacing; y += spacing) {
              final path = Path();
              path.moveTo(0, y + math.cos(y / (60.0 * scale)) * (30.0 * warp * scale));
              for (double x = stepY; x <= size.width + stepY; x += stepY) {
                final dy = math.cos((x / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x, y + dy);
              }
              canvas.drawPath(path, gridPaint);
            }
          } else {
            for (double x = 0; x <= size.width + 1; x += spacing) {
              canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
            }
            for (double y = 0; y <= size.height + 1; y += spacing) {
              canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
            }
          }
        }
        break;

      case 'dots':
        final dotColor = _color(layer['dot_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: _f(layer['dot_opacity'] ?? layer['pattern_opacity'], 0.20).clamp(0.0, 1.0));
        final rawDotSize = _f(layer['dot_size'], 3.0);
        final rawSpacing = _f(layer['dot_spacing'], 24.0);

        final dotRadius = (rawDotSize * scale / 2.0).clamp(0.5, 40.0);
        final spacing = (rawSpacing * scale).clamp(6.0, 400.0);

        final dotPaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;

        for (double x = spacing / 2; x < size.width + spacing; x += spacing) {
          for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
            final dx = warp > 0 ? math.sin((y / (40.0 * scale)) + (x / (50.0 * scale))) * (25.0 * warp * scale) : 0.0;
            final dy = warp > 0 ? math.cos((x / (40.0 * scale)) + (y / (50.0 * scale))) * (25.0 * warp * scale) : 0.0;
            canvas.drawCircle(Offset(x + dx, y + dy), dotRadius, dotPaint);
          }
        }
        break;

      case 'stripes':
        final stripeColor = _color(layer['stripe_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: _f(layer['stripe_opacity'] ?? layer['pattern_opacity'], 0.15).clamp(0.0, 1.0));
        final rawWidth = _f(layer['stripe_width'], 8.0);
        final rawSpacing = _f(layer['stripe_spacing'], 28.0);
        final stripeAngle = _f(layer['stripe_angle'], 45.0);

        final stripeWidth = (rawWidth * scale).clamp(1.0, 100.0);
        final spacing = (rawSpacing * scale).clamp(4.0, 500.0);

        final stripePaint = Paint()
          ..color = stripeColor
          ..strokeWidth = stripeWidth
          ..style = PaintingStyle.stroke;

        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(stripeAngle * math.pi / 180);
        final diag = math.sqrt(size.width * size.width + size.height * size.height);
        final step = spacing + stripeWidth;
        final stepY = (15.0 * scale).clamp(4.0, 40.0);

        if (warp > 0) {
          for (double x = -diag; x <= diag; x += step) {
            final path = Path();
            path.moveTo(x + math.sin(-diag / (40.0 * scale)) * (25.0 * warp * scale), -diag);
            for (double y = -diag + stepY; y <= diag; y += stepY) {
              final dx = math.sin(y / (40.0 * scale)) * (25.0 * warp * scale);
              path.lineTo(x + dx, y);
            }
            canvas.drawPath(path, stripePaint);
          }
        } else {
          for (double x = -diag; x <= diag; x += step) {
            canvas.drawLine(Offset(x, -diag), Offset(x, diag), stripePaint);
          }
        }
        canvas.restore();
        break;

      case 'rays':
        final rayColor = _color(layer['ray_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: _f(layer['ray_opacity'] ?? layer['pattern_opacity'], 0.15).clamp(0.0, 1.0));
        final rayCount = _f(layer['ray_count'], 16).toInt().clamp(4, 72);
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.sqrt(size.width * size.width + size.height * size.height);

        final rayPaint = Paint()
          ..color = rayColor
          ..style = PaintingStyle.fill;

        final stepAngle = (2 * math.pi) / rayCount;
        final stepR = (15.0 * scale).clamp(4.0, 40.0);

        for (int i = 0; i < rayCount; i += 2) {
          final startAngle = i * stepAngle;
          final endAngle = startAngle + stepAngle;
          if (warp > 0) {
            final path = Path()..moveTo(center.dx, center.dy);
            for (double r = stepR; r <= radius; r += stepR) {
              final curA = startAngle + (r / radius) * (warp * 1.5);
              path.lineTo(center.dx + r * math.cos(curA), center.dy + r * math.sin(curA));
            }
            for (double r = radius; r >= 0; r -= stepR) {
              final curA = endAngle + (r / radius) * (warp * 1.5);
              path.lineTo(center.dx + r * math.cos(curA), center.dy + r * math.sin(curA));
            }
            path.close();
            canvas.drawPath(path, rayPaint);
          } else {
            final path = Path()
              ..moveTo(center.dx, center.dy)
              ..lineTo(
                center.dx + radius * math.cos(startAngle),
                center.dy + radius * math.sin(startAngle),
              )
              ..lineTo(
                center.dx + radius * math.cos(endAngle),
                center.dy + radius * math.sin(endAngle),
              )
              ..close();
            canvas.drawPath(path, rayPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return oldDelegate.layer != layer || oldDelegate.bgType != bgType;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern Overlay Layer – independent overlay layer (Grid, Dots, Stripes, Rays)
// ─────────────────────────────────────────────────────────────────────────────

class _PatternOverlayLayer extends StatelessWidget {
  const _PatternOverlayLayer({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });

  final Map<String, dynamic> layer;
  final double w, h;
  final bool isSelected;
  final VoidCallback? onTap;
  final int? index;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final patternType = (layer['pattern_type'] as String?)?.toLowerCase() ??
        (layer['bg_type'] as String?)?.toLowerCase() ??
        'grid';
    final opacity = _f(layer['opacity'] ?? layer['pattern_opacity'], 1.0).clamp(0.0, 1.0);
    final width = _f(layer['width'], 1.0) * w;
    final height = _f(layer['height'], 1.0) * h;

    final child = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _PatternPainter(
          layer: layer,
          patternType: patternType,
        ),
      ),
    );

    return _Positioner(
      layer: layer,
      w: w,
      h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Opacity(
            opacity: opacity,
            child: child,
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({
    required this.layer,
    required this.patternType,
  });

  final Map<String, dynamic> layer;
  final String patternType;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 375.0).clamp(0.2, 20.0);
    final warp = _f(layer['bg_warp'] ?? layer['warp'], 0.0);
    final opacity = _f(layer['pattern_opacity'] ?? layer['opacity'], 1.0).clamp(0.0, 1.0);

    switch (patternType) {
      case 'grid':
        final gridColor = _color(layer['color'] ?? layer['grid_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: (_f(layer['grid_opacity'], 0.25) * opacity).clamp(0.0, 1.0));
        final rawLineWidth = _f(layer['grid_line_width'], 1.5);
        final rawSpacing = _f(layer['grid_spacing'], 32.0);
        final gridAngle = _f(layer['grid_angle'], 0.0);

        final lineWidth = (rawLineWidth * scale).clamp(0.5, 40.0);
        final spacing = (rawSpacing * scale).clamp(6.0, 500.0);

        final gridPaint = Paint()
          ..color = gridColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;

        if (gridAngle != 0) {
          canvas.save();
          canvas.translate(size.width / 2, size.height / 2);
          canvas.rotate(gridAngle * math.pi / 180);
          final diag = math.sqrt(size.width * size.width + size.height * size.height);
          final stepY = (15.0 * scale).clamp(4.0, 40.0);
          
          if (warp > 0) {
            for (double x = -diag; x <= diag; x += spacing) {
              final path = Path();
              path.moveTo(x + math.sin((-diag / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale), -diag);
              for (double y = -diag + stepY; y <= diag; y += stepY) {
                final dx = math.sin((y / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x + dx, y);
              }
              canvas.drawPath(path, gridPaint);
            }
            for (double y = -diag; y <= diag; y += spacing) {
              final path = Path();
              path.moveTo(-diag, y + math.cos((-diag / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale));
              for (double x = -diag + stepY; x <= diag; x += stepY) {
                final dy = math.cos((x / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x, y + dy);
              }
              canvas.drawPath(path, gridPaint);
            }
          } else {
            for (double x = -diag; x <= diag; x += spacing) {
              canvas.drawLine(Offset(x, -diag), Offset(x, diag), gridPaint);
            }
            for (double y = -diag; y <= diag; y += spacing) {
              canvas.drawLine(Offset(-diag, y), Offset(diag, y), gridPaint);
            }
          }
          canvas.restore();
        } else {
          final stepY = (15.0 * scale).clamp(4.0, 40.0);
          if (warp > 0) {
            for (double x = 0; x <= size.width + spacing; x += spacing) {
              final path = Path();
              path.moveTo(x + math.sin(x / (60.0 * scale)) * (30.0 * warp * scale), 0);
              for (double y = stepY; y <= size.height + stepY; y += stepY) {
                final dx = math.sin((y / (45.0 * scale)) + (x / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x + dx, y);
              }
              canvas.drawPath(path, gridPaint);
            }
            for (double y = 0; y <= size.height + spacing; y += spacing) {
              final path = Path();
              path.moveTo(0, y + math.cos(y / (60.0 * scale)) * (30.0 * warp * scale));
              for (double x = stepY; x <= size.width + stepY; x += stepY) {
                final dy = math.cos((x / (45.0 * scale)) + (y / (60.0 * scale))) * (30.0 * warp * scale);
                path.lineTo(x, y + dy);
              }
              canvas.drawPath(path, gridPaint);
            }
          } else {
            for (double x = 0; x <= size.width + 1; x += spacing) {
              canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
            }
            for (double y = 0; y <= size.height + 1; y += spacing) {
              canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
            }
          }
        }
        break;

      case 'dots':
        final dotColor = _color(layer['color'] ?? layer['dot_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: (_f(layer['dot_opacity'], 0.25) * opacity).clamp(0.0, 1.0));
        final rawDotSize = _f(layer['dot_size'], 4.0);
        final rawSpacing = _f(layer['dot_spacing'], 24.0);

        final dotRadius = (rawDotSize * scale / 2.0).clamp(0.5, 50.0);
        final spacing = (rawSpacing * scale).clamp(6.0, 400.0);

        final dotPaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;

        for (double x = spacing / 2; x < size.width + spacing; x += spacing) {
          for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
            final dx = warp > 0 ? math.sin((y / (40.0 * scale)) + (x / (50.0 * scale))) * (25.0 * warp * scale) : 0.0;
            final dy = warp > 0 ? math.cos((x / (40.0 * scale)) + (y / (50.0 * scale))) * (25.0 * warp * scale) : 0.0;
            canvas.drawCircle(Offset(x + dx, y + dy), dotRadius, dotPaint);
          }
        }
        break;

      case 'stripes':
        final stripeColor = _color(layer['color'] ?? layer['stripe_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: (_f(layer['stripe_opacity'], 0.20) * opacity).clamp(0.0, 1.0));
        final rawWidth = _f(layer['stripe_width'], 8.0);
        final rawSpacing = _f(layer['stripe_spacing'], 28.0);
        final stripeAngle = _f(layer['stripe_angle'], 45.0);

        final stripeWidth = (rawWidth * scale).clamp(1.0, 100.0);
        final spacing = (rawSpacing * scale).clamp(4.0, 500.0);

        final stripePaint = Paint()
          ..color = stripeColor
          ..strokeWidth = stripeWidth
          ..style = PaintingStyle.stroke;

        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(stripeAngle * math.pi / 180);
        final diag = math.sqrt(size.width * size.width + size.height * size.height);
        final step = spacing + stripeWidth;
        final stepY = (15.0 * scale).clamp(4.0, 40.0);

        if (warp > 0) {
          for (double x = -diag; x <= diag; x += step) {
            final path = Path();
            path.moveTo(x + math.sin(-diag / (40.0 * scale)) * (25.0 * warp * scale), -diag);
            for (double y = -diag + stepY; y <= diag; y += stepY) {
              final dx = math.sin(y / (40.0 * scale)) * (25.0 * warp * scale);
              path.lineTo(x + dx, y);
            }
            canvas.drawPath(path, stripePaint);
          }
        } else {
          for (double x = -diag; x <= diag; x += step) {
            canvas.drawLine(Offset(x, -diag), Offset(x, diag), stripePaint);
          }
        }
        canvas.restore();
        break;

      case 'rays':
        final rayColor = _color(layer['color'] ?? layer['ray_color'] ?? layer['pattern_color'] ?? '#1A6B4A')
            .withValues(alpha: (_f(layer['ray_opacity'], 0.20) * opacity).clamp(0.0, 1.0));
        final rayCount = _f(layer['ray_count'], 16).toInt().clamp(4, 72);
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.sqrt(size.width * size.width + size.height * size.height);

        final rayPaint = Paint()
          ..color = rayColor
          ..style = PaintingStyle.fill;

        final stepAngle = (2 * math.pi) / rayCount;
        final stepR = (15.0 * scale).clamp(4.0, 40.0);

        for (int i = 0; i < rayCount; i += 2) {
          final startAngle = i * stepAngle;
          final endAngle = startAngle + stepAngle;
          if (warp > 0) {
            final path = Path()..moveTo(center.dx, center.dy);
            for (double r = stepR; r <= radius; r += stepR) {
              final curA = startAngle + (r / radius) * (warp * 1.5);
              path.lineTo(center.dx + r * math.cos(curA), center.dy + r * math.sin(curA));
            }
            for (double r = radius; r >= 0; r -= stepR) {
              final curA = endAngle + (r / radius) * (warp * 1.5);
              path.lineTo(center.dx + r * math.cos(curA), center.dy + r * math.sin(curA));
            }
            path.close();
            canvas.drawPath(path, rayPaint);
          } else {
            final path = Path()
              ..moveTo(center.dx, center.dy)
              ..lineTo(
                center.dx + radius * math.cos(startAngle),
                center.dy + radius * math.sin(startAngle),
              )
              ..lineTo(
                center.dx + radius * math.cos(endAngle),
                center.dy + radius * math.sin(endAngle),
              )
              ..close();
            canvas.drawPath(path, rayPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) =>
      !mapEquals(old.layer, layer) || old.patternType != patternType;
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Layer
// ─────────────────────────────────────────────────────────────────────────────

class _TextLayer extends StatelessWidget {
  const _TextLayer({
    required this.layer,
    required this.w,
    required this.h,
    required this.headline,
    required this.subheadline,
    this.headlineColor,
    this.subheadlineColor,
    required this.headlineFont,
    required this.subheadlineFont,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;

  final Map<String, dynamic> layer;
  final double w, h;
  final String headline, subheadline;
  final Color? headlineColor, subheadlineColor;
  final String headlineFont, subheadlineFont;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final width = _f(layer['width'], 0.85) * w;
    final rawContent = layer['content'] as String? ?? '';
    final content = _resolveText(rawContent, headline, subheadline);
    final fontSize = _f(layer['font_size'], 0.08) * w;

    final token = rawContent.contains('{headline}')
        ? 'headline'
        : rawContent.contains('{subheadline}')
            ? 'subheadline'
            : null;

    if (token == 'headline' && headline.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (token == 'subheadline' && subheadline.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final weight = _fontWeight(layer['weight'] as String? ??
        (layer['bold'] == true ? 'w800' : 'w400'));
    final align = _textAlign(layer['text_align'] as String? ?? layer['align'] as String? ?? 'left');
    final int? maxLines = null;
    final TextOverflow? overflow = null;
    final lineHeight = _f(layer['line_height'], 1.2);
    final letterSpacing = _f(layer['letter_spacing']);

    final defaultColor = _color(layer['color'], const Color(0xFF141A14));
    final finalColor = token == 'headline' && headlineColor != null
        ? headlineColor!
        : token == 'subheadline' && subheadlineColor != null
            ? subheadlineColor!
            : defaultColor;

    final fontName = layer['font'] as String? ?? (token == 'headline'
        ? headlineFont
        : token == 'subheadline'
            ? subheadlineFont
            : 'DM Sans');

    final opacity = _f(layer['opacity'], 1.0);

    // ── Gradient text support ─────────────────────────────────────────────
    final gradList = layer['gradient_colors'] as List?;
    Widget textWidget;
    if (gradList != null && gradList.length >= 2) {
      final gradColors = gradList.map((c) => _color(c)).toList();
      textWidget = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: _alignment(layer['gradient_begin'] as String? ?? 'topLeft'),
          end: _alignment(
              layer['gradient_end'] as String? ?? 'bottomRight'),
          colors: gradColors,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          content,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: _googleFont(
            fontName,
            TextStyle(
              fontSize: fontSize,
              fontWeight: weight,
              color: Colors.white,
              height: lineHeight,
              letterSpacing: letterSpacing,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    } else {
      textWidget = Text(
        content,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
        style: _googleFont(
          fontName,
          TextStyle(
            fontSize: fontSize,
            fontWeight: weight,
            color: finalColor,
            height: lineHeight,
            letterSpacing: letterSpacing,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    final inner = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: textWidget,
    );

    return _Positioner(
      layer: layer,
      w: w,
      h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          SizedBox(width: width, child: inner),
          isSelected,
        ),
        layer,
      ),
    );
  }

  FontWeight _fontWeight(String w) => switch (w) {
        'w100' => FontWeight.w100,
        'w200' => FontWeight.w200,
        'w300' => FontWeight.w300,
        'w400' => FontWeight.w400,
        'w500' => FontWeight.w500,
        'w600' => FontWeight.w600,
        'w700' => FontWeight.w700,
        'w800' => FontWeight.w800,
        'w900' => FontWeight.w900,
        _ => FontWeight.w400,
      };

  TextAlign _textAlign(String a) => switch (a) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone Mockup Layer
//
// style values:
//   dynamic_island  – iPhone 14 Pro+ pill notch (default)
//   circle_notch    – older iPhone circular notch
//   bar_notch       – older iPhone wide bar notch
//   punch_hole      – Android punch-hole camera
//   flat            – no notch (Android flat)
//   none            – clean edge-to-edge, no notch element
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneLayer extends StatelessWidget {
  const _PhoneLayer({
    required this.layer,
    required this.w,
    required this.h,
    this.screenshot,
    this.onTap,
    this.deviceFrameColor,
    this.isSelected = false,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });

  final Map<String, dynamic> layer;
  final double w, h;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final ImageProvider? screenshot;
  final VoidCallback? onTap;
  final Color? deviceFrameColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // ── Position: support both (x,y) top-left and (cx,cy) center ─────────
    final scale = _f(layer['scale'], 1.0);
    final phoneW = _f(layer['width'], 0.6) * w * scale;
    final aspectRatio = _f(layer['aspect_ratio'], 19.5 / 9);
    final phoneH = phoneW * aspectRatio;

    final frameColor =
        deviceFrameColor ?? _color(layer['frame_color'], const Color(0xFF1C1C1E));
    final bezelThick = _f(layer['bezel'], 8.0) * (w / 390.0) * scale;
    final radius = _f(layer['radius'], 38.0) * (w / 390.0) * scale;
    final depth = _f(layer['depth'], 0.0) * (w / 390.0) * scale;
    final depthColor = _color(layer['depth_color'], const Color(0xFF0F0F10));
    final style = layer['style'] as String? ?? 'dynamic_island';
    final shadowStyle = layer['shadow_style'] as String?;
    final shadow = layer['shadow'] != false && shadowStyle != 'none';
    final opacity = _f(layer['opacity'], 1.0);

    // 3D Oval Floor Cast Shadow properties
    final hasFloorShadow = layer['floor_shadow'] != false && layer['shadow'] != false;
    final shadowDistance = _f(layer['shadow_distance'], 35.0) * (w / 390.0) * scale;
    final shadowBlur = _f(layer['shadow_blur'], 22.0) * (w / 390.0) * scale;
    final rawWidthRatio = layer['shadow_width_ratio'] ?? (layer['shadow_width'] != null ? _f(layer['shadow_width']) / 100 : null);
    final shadowWidthRatio = _f(rawWidthRatio, 0.85);
    final rawHeightRatio = layer['shadow_height_ratio'] ?? (layer['shadow_height'] != null ? _f(layer['shadow_height']) / 100 : null);
    final shadowHeightRatio = _f(rawHeightRatio, 0.14);
    final rawOpacity = layer['shadow_opacity'] != null && _f(layer['shadow_opacity']) > 1.0
        ? _f(layer['shadow_opacity']) / 100.0
        : layer['shadow_opacity'];
    final shadowOpacity = _f(rawOpacity, 0.35);
    final shadowColor = _color(layer['shadow_color'], Colors.black);

    Widget phone = _buildPhoneWidget(
      phoneW: phoneW,
      phoneH: phoneH,
      frameColor: frameColor,
      bezelThick: bezelThick,
      radius: radius,
      depth: depth,
      depthColor: depthColor,
      style: style,
      shadow: shadow,
      shadowStyle: shadowStyle,
      hasFloorShadow: hasFloorShadow,
      shadowDistance: shadowDistance,
      shadowBlur: shadowBlur,
      shadowWidthRatio: shadowWidthRatio,
      shadowHeightRatio: shadowHeightRatio,
      shadowOpacity: shadowOpacity,
      shadowColor: shadowColor,
      scale: scale,
    );

    return _Positioner(
      layer: layer, w: w, h: h,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        child: _apply3DTransform(
          _withSelection(
            Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: phone,
            ),
            isSelected,
          ),
          layer,
        ),
      ),
    );
  }

  Widget _buildPhoneWidget({
    required double phoneW,
    required double phoneH,
    required Color frameColor,
    required double bezelThick,
    required double radius,
    required double depth,
    required Color depthColor,
    required String style,
    required bool shadow,
    String? shadowStyle,
    bool hasFloorShadow = false,
    double shadowDistance = 35.0,
    double shadowBlur = 22.0,
    double shadowWidthRatio = 0.85,
    double shadowHeightRatio = 0.14,
    double shadowOpacity = 0.35,
    Color shadowColor = Colors.black,
    required double scale,
  }) {
    final innerW = phoneW - bezelThick * 2;
    final innerH = phoneH - bezelThick * 2;
    final innerRadius = (radius - bezelThick).clamp(0, radius - 2).toDouble();

    List<BoxShadow> shadows = [];
    if (depth > 0) {
      for (int i = 1; i <= depth.round(); i++) {
        shadows.add(BoxShadow(
          color: depthColor,
          offset: Offset(i.toDouble(), i.toDouble()),
          blurRadius: 0,
        ));
      }
    }
    if (shadow) {
      final sf = (w / 390.0) * scale;
      final d = depth > 0 ? depth : 0.0;
      if (shadowStyle == 'subtle') {
        shadows.add(BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 16 * sf,
          offset: Offset(d + 0, d + 8 * sf),
        ));
      } else {
        shadows.add(BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 32 * sf,
          spreadRadius: -4 * sf,
          offset: Offset(d + 0, d + 16 * sf),
        ));
        shadows.add(BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 8 * sf,
          offset: Offset(d + 0, d + 4 * sf),
        ));
      }
    }

    Widget phoneFrame = Container(
      width: phoneW,
      height: phoneH,
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows.isNotEmpty ? shadows : null,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Stack(
            children: [
              SizedBox(
                width: innerW,
                height: innerH,
                child: screenshot != null
                    ? Image(image: screenshot!, fit: BoxFit.cover)
                    : _Placeholder(w: innerW),
              ),
              // ── Notch / camera cutout ─────────────────────────────────
              if (style != 'none')
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildNotch(style, innerW),
                ),
            ],
          ),
        ),
      ),
    );

    if (!hasFloorShadow) {
      return phoneFrame;
    }

    final sWidth = phoneW * shadowWidthRatio;
    final sHeight = phoneW * shadowHeightRatio;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -(shadowDistance + sHeight / 2),
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: math.max(0.1, shadowBlur),
                sigmaY: math.max(0.1, shadowBlur),
              ),
              child: Container(
                width: sWidth,
                height: sHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(sWidth / 2, sHeight / 2)),
                  gradient: RadialGradient(
                    colors: [
                      shadowColor.withValues(alpha: shadowOpacity.clamp(0.0, 1.0)),
                      shadowColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ),
        ),
        phoneFrame,
      ],
    );
  }

  Widget _buildNotch(String style, double w) {
    switch (style) {
      // Dynamic Island pill
      case 'dynamic_island':
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: w * 0.035),
            child: Container(
              width: w * 0.32,
              height: w * 0.085,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(w * 0.042),
              ),
            ),
          ),
        );

      // iPhone X / 11 / 12 wide notch
      case 'bar_notch':
        return CustomPaint(
          size: Size(w, w * 0.14),
          painter: _BarNotchPainter(),
        );

      // Android punch hole
      case 'punch_hole':
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: w * 0.03),
            child: Container(
              width: w * 0.07,
              height: w * 0.07,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

      // Android flat – just a small camera dot
      case 'flat':
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(top: w * 0.025, left: w * 0.08),
            child: Container(
              width: w * 0.065,
              height: w * 0.065,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

}

// Bar notch painter for iPhone X style
class _BarNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final path = Path();
    final r = size.width * 0.08;
    final notchW = size.width * 0.52;
    final notchH = size.height;

    path.moveTo(0, 0);
    path.lineTo((size.width - notchW) / 2 - r, 0);
    path.quadraticBezierTo(
        (size.width - notchW) / 2, 0, (size.width - notchW) / 2, r);
    path.lineTo((size.width - notchW) / 2, notchH - r);
    path.quadraticBezierTo((size.width - notchW) / 2, notchH,
        (size.width - notchW) / 2 + r, notchH);
    path.lineTo((size.width + notchW) / 2 - r, notchH);
    path.quadraticBezierTo((size.width + notchW) / 2, notchH,
        (size.width + notchW) / 2, notchH - r);
    path.lineTo((size.width + notchW) / 2, r);
    path.quadraticBezierTo(
        (size.width + notchW) / 2, 0, (size.width + notchW) / 2 + r, 0);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Text(
            'App Name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.08,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF141A14),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFE7EBE7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.07),
            decoration: const BoxDecoration(
                color: Color(0xFFD0D8D0), shape: BoxShape.circle),
            child: Icon(Icons.add_photo_alternate_outlined,
                size: w * 0.2, color: const Color(0xFF7D877D)),
          ),
          SizedBox(height: w * 0.05),
          Text(
            'Add a photo',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: w * 0.065,
                color: const Color(0xFF7D877D),
                height: 1.4,
                decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shape Layer
//
// shape_type: circle | rect | rounded_rect | polygon | arc | ring |
//             diagonal_split | star | blob
// ─────────────────────────────────────────────────────────────────────────────

class _ShapeLayer extends StatelessWidget {
  const _ShapeLayer({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;

  final Map<String, dynamic> layer;
  final double w, h;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final scale = _f(layer['scale'], 1.0);
    final widthBase = _f(layer['width'], _f(layer['size'], 0.3)) * w;
    final width = widthBase * scale;
    final heightBase = layer['height'] != null ? _f(layer['height']) * (w * 844 / 390) : widthBase;
    final height = heightBase * scale;
    final color = _color(layer['color']);
    final opacity = _f(layer['opacity'], 1.0);
    final shapeType =
        layer['shape_type'] as String? ?? layer['shape'] as String? ?? 'circle';

    // Gradient fill for shapes (supports colors list, fill_type, angle, and begin/end)
    final gradList = layer['gradient_colors'] as List?;
    final fillType = layer['fill_type'] as String?;
    final isGrad = fillType == 'gradient' || (fillType != 'solid' && gradList != null && gradList.length >= 2);

    LinearGradient? gradient;
    if (isGrad) {
      final colors = gradList != null && gradList.length >= 2
          ? gradList.map((c) => _color(c)).toList()
          : [
              _color(layer['color'], const Color(0xFF1A6B4A)),
              _color(layer['color_2'] ?? layer['color2'], const Color(0xFF2E9F6E)),
            ];

      if (layer['gradient_angle'] != null) {
        final deg = _f(layer['gradient_angle'], 135.0);
        final rad = (deg - 90.0) * (math.pi / 180.0);
        final gx = math.cos(rad);
        final gy = math.sin(rad);
        gradient = LinearGradient(
          begin: Alignment(-gx, -gy),
          end: Alignment(gx, gy),
          colors: colors,
        );
      } else {
        gradient = LinearGradient(
          begin: _alignment(layer['gradient_begin'] as String?),
          end: _alignment(
              layer['gradient_end'] as String? ?? 'bottomRight'),
          colors: colors,
        );
      }
    }

    Widget shape;
    switch (shapeType) {
      case 'circle':
        shape = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            shape: BoxShape.circle,
          ),
        );
        break;

      case 'rect':
        shape = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
          ),
        );
        break;

      case 'rounded_rect':
        final cr = _f(layer['corner_radius'], 16.0) * (w / 390.0);
        shape = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(cr),
          ),
        );
        break;

      case 'ring':
        final strokeW = _f(layer['stroke_width'], 8.0);
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _RingPainter(color: color, gradient: gradient, strokeWidth: strokeW),
          ),
        );
        break;

      case 'arc':
        final startAngle = _f(layer['start_angle'], -math.pi / 2);
        final sweepAngle = _f(layer['sweep_angle'], math.pi * 1.5);
        final strokeW = _f(layer['stroke_width'], 8.0);
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _ArcPainter(
              color: color,
              gradient: gradient,
              strokeWidth: strokeW,
              startAngle: startAngle,
              sweepAngle: sweepAngle,
            ),
          ),
        );
        break;

      case 'polygon':
        final sides = layer['sides'] as int? ?? 6;
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _PolygonPainter(
              color: gradient == null ? color : null,
              gradient: gradient,
              sides: sides,
            ),
          ),
        );
        break;

      case 'star':
        final points = layer['points'] as int? ?? 5;
        final innerRatio = _f(layer['inner_ratio'], 0.45);
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _StarPainter(
              color: color,
              gradient: gradient,
              points: points,
              innerRatio: innerRatio,
            ),
          ),
        );
        break;

      case 'diagonal_split':
        final color2 = _color(layer['color2'], color);
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _DiagonalSplitPainter(color1: color, color2: color2),
          ),
        );
        break;

      case 'diamond':
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _DiamondPainter(color: color, gradient: gradient),
          ),
        );
        break;

      case 'heart':
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _HeartPainter(color: color, gradient: gradient),
          ),
        );
        break;

      case 'cross':
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _CrossPainter(color: color, gradient: gradient),
          ),
        );
        break;

      case 'svg':
        final svgContent = layer['svg_content'] as String?;
        if (svgContent != null && svgContent.isNotEmpty) {
          if (gradient != null) {
            shape = SizedBox(
              width: width,
              height: height,
              child: ShaderMask(
                shaderCallback: (bounds) => gradient!.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: SvgPicture.string(
                  svgContent,
                  width: width,
                  height: height,
                ),
              ),
            );
          } else {
            shape = SizedBox(
              width: width,
              height: height,
              child: SvgPicture.string(
                svgContent,
                width: width,
                height: height,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            );
          }
        } else {
          shape = SizedBox(width: width, height: height);
        }
        break;

      case 'blob':
      default:
        shape = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _BlobPainter(color: color, gradient: gradient),
          ),
        );
        break;
    }

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: shape,
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ── Custom painters ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, this.gradient, required this.strokeWidth});
  final Color color;
  final Gradient? gradient;
  final double strokeWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
        strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth,
        size.height - strokeWidth);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.color,
    this.gradient,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });
  final double strokeWidth, startAngle, sweepAngle;
  final Color color;
  final Gradient? gradient;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
        size.width - strokeWidth, size.height - strokeWidth);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PolygonPainter extends CustomPainter {
  _PolygonPainter({this.color, this.gradient, required this.sides});
  final Color? color;
  final Gradient? gradient;
  final int sides;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    final paint = Paint();
    if (gradient != null) {
      paint.shader =
          gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color!;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  _StarPainter(
      {required this.color, this.gradient, required this.points, required this.innerRatio});
  final Color color;
  final Gradient? gradient;
  final int points;
  final double innerRatio;
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy);
    final innerR = outerR * innerRatio;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi * i / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalSplitPainter extends CustomPainter {
  _DiagonalSplitPainter({required this.color1, required this.color2});
  final Color color1, color2;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color1);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.color, this.gradient});
  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Web Panel uses transform="translate(50 50) scale(0.9)" in 100x100 viewport
    final sx = (size.width / 100.0) * 0.9;
    final sy = (size.height / 100.0) * 0.9;

    final path = Path();
    path.moveTo(cx + 25.0 * sx, cy - 32.8 * sy);
    path.cubicTo(
      cx + 33.3 * sx, cy - 29.4 * sy,
      cx + 41.6 * sx, cy - 22.9 * sy,
      cx + 46.0 * sx, cy - 14.2 * sy,
    );
    path.cubicTo(
      cx + 50.5 * sx, cy - 5.5 * sy,
      cx + 51.0 * sx, cy + 5.5 * sy,
      cx + 47.0 * sx, cy + 15.1 * sy,
    );
    path.cubicTo(
      cx + 43.0 * sx, cy + 24.7 * sy,
      cx + 34.4 * sx, cy + 32.8 * sy,
      cx + 25.0 * sx, cy + 37.3 * sy,
    );
    path.cubicTo(
      cx + 15.6 * sx, cy + 41.8 * sy,
      cx + 5.3 * sx, cy + 42.7 * sy,
      cx - 4.8 * sx, cy + 40.4 * sy,
    );
    path.cubicTo(
      cx - 14.8 * sx, cy + 38.1 * sy,
      cx - 24.6 * sx, cy + 32.7 * sy,
      cx - 32.1 * sx, cy + 25.0 * sy,
    );
    path.cubicTo(
      cx - 39.7 * sx, cy + 17.4 * sy,
      cx - 44.9 * sx, cy + 7.6 * sy,
      cx - 46.1 * sx, cy - 3.1 * sy,
    );
    path.cubicTo(
      cx - 47.3 * sx, cy - 13.7 * sy,
      cx - 44.4 * sx, cy - 25.1 * sy,
      cx - 37.2 * sx, cy - 31.0 * sy,
    );
    path.cubicTo(
      cx - 30.0 * sx, cy - 37.0 * sy,
      cx - 18.6 * sx, cy - 37.4 * sy,
      cx - 8.6 * sx, cy - 38.7 * sy,
    );
    path.cubicTo(
      cx + 1.5 * sx, cy - 40.1 * sy,
      cx + 16.8 * sx, cy - 36.2 * sy,
      cx + 25.0 * sx, cy - 32.8 * sy,
    );
    path.close();

    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gradient != gradient;
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent Bar
// ─────────────────────────────────────────────────────────────────────────────

class _AccentBar extends StatelessWidget {
  const _AccentBar({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final Map<String, dynamic> layer;
  final double w, h;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final barW = _f(layer['width'], 0.08) * w;
    final barH = _f(layer['height'], 0.004) * (w * 844 / 390);
    final color = _color(layer['color'], const Color(0xFF1A6B4A));

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Container(
            width: barW,
            height: barH,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(barH / 2),
            ),
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Layer – pill-shaped chip
//
// Fields:
//   x, y, width (optional), font_size, bold, color (bg), text_color
//   content – text; supports {headline} / {subheadline}
//   icon – optional emoji or character shown before text
//   border_color, corner_radius
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeLayer extends StatelessWidget {
  const _BadgeLayer({
    required this.layer,
    required this.w,
    required this.h,
    required this.headline,
    required this.subheadline,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;

  final Map<String, dynamic> layer;
  final double w, h;
  final String headline, subheadline;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final rawContent = layer['content'] as String? ?? '';
    final content = _resolveText(rawContent, headline, subheadline);
    final icon = layer['icon'] as String?;
    final bgColor = _color(layer['color'], const Color(0xFFE8F5E9));
    final textColor =
        _color(layer['text_color'], const Color(0xFF1A6B4A));
    final fontSize = _f(layer['font_size'], 0.035) * w;
    final cr = _f(layer['corner_radius'], 100.0) * (w / 390.0);
    final borderColor = layer['border_color'] != null
        ? _color(layer['border_color'])
        : null;
    final fontName = layer['font'] as String? ?? 'DM Sans';
    final weight =
        layer['bold'] == true ? FontWeight.w700 : FontWeight.w500;
    final hPad = fontSize * 0.8;
    final vPad = fontSize * 0.4;

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(cr),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Text(icon,
                      style: TextStyle(
                          fontSize: fontSize,
                          decoration: TextDecoration.none)),
                  SizedBox(width: fontSize * 0.4),
                ],
                Text(
                  content,
                  style: _googleFont(
                    fontName,
                    TextStyle(
                      fontSize: fontSize,
                      fontWeight: weight,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature Row – icon + text row (for feature lists)
//
// Fields:
//   x, y, width
//   icon – emoji or character
//   icon_bg – icon background color
//   icon_color – icon text color
//   content – text next to icon
//   text_color, font, font_size, bold
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final Map<String, dynamic> layer;
  final double w, h;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
//     final width = _f(layer['width'], 0.85) * w;
    final content = layer['content'] as String? ?? '';
    final icon = layer['icon'] as String? ?? '●';
    final iconBg =
        layer['icon_bg'] != null ? _color(layer['icon_bg']) : null;
    final iconColor =
        _color(layer['icon_color'], const Color(0xFF1A6B4A));
    final textColor = _color(layer['text_color'], const Color(0xFF141A14));
    final fontSize = _f(layer['font_size'], 0.04) * w;
    final fontName = layer['font'] as String? ?? 'DM Sans';
    final weight =
        layer['bold'] == true ? FontWeight.w600 : FontWeight.w400;

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: fontSize * 1.8,
                height: fontSize * 1.8,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: fontSize * 0.9,
                      color: iconColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  content,
                  style: _googleFont(
                    fontName,
                    TextStyle(
                      fontSize: fontSize,
                      fontWeight: weight,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Layer – network or asset image
//
// Fields:
//   x, y, width, height
//   url – network image URL
//   asset – asset path (e.g., 'assets/images/hero.png')
//   fit: cover | contain | fill | none | scaleDown
//   opacity, corner_radius, rotation
// ─────────────────────────────────────────────────────────────────────────────

class _ImageLayer extends StatelessWidget {
  const _ImageLayer({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final Map<String, dynamic> layer;
  final double w, h;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final imgW = _f(layer['width'], 0.5) * w;
    final imgH = layer['height'] != null ? _f(layer['height']) * (w * 844 / 390) : imgW;
    final cr = _f(layer['corner_radius'], 0.0) * (w / 390.0);
    final opacity = _f(layer['opacity'], 1.0);
    final url = layer['url'] as String?;
    final asset = layer['asset'] as String?;
    final fitStr = layer['fit'] as String? ?? 'cover';
    final fit = switch (fitStr) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      'none' => BoxFit.none,
      'scaleDown' => BoxFit.scaleDown,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      _ => BoxFit.cover,
    };

    Widget img;
    if (url != null) {
      img = AdaptiveImage(imageUrl: url, fit: fit, width: imgW, height: imgH);
    } else if (asset != null) {
      img = Image.asset(asset, fit: fit, width: imgW, height: imgH);
    } else {
      img = Container(
          width: imgW,
          height: imgH,
          color: Colors.grey.shade200);
    }

    Widget result = cr > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(cr), child: img)
        : img;

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: result,
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted Panel – blurred glass card with optional content inside
//
// Fields:
//   x, y, width, height
//   blur – sigma (default 12)
//   color – tint color with opacity (e.g. '#80FFFFFF')
//   corner_radius
//   border_color, border_width
//   content – optional text shown inside
//   text_color, font, font_size
// ─────────────────────────────────────────────────────────────────────────────

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({
    required this.layer,
    required this.w,
    required this.h,
    required this.headline,
    required this.subheadline,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final Map<String, dynamic> layer;
  final double w, h;
  final String headline, subheadline;
  final bool isSelected;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final pw = _f(layer['width'], 0.8) * w;
    final ph = _f(layer['height'], 0.15) * (w * 844 / 390);
    final blur = _f(layer['blur'], 12.0);
    final tint =
        _color(layer['color'], const Color(0x80FFFFFF));
    final cr = _f(layer['corner_radius'], 16.0) * (w / 390.0);
    final borderColor = layer['border_color'] != null
        ? _color(layer['border_color'])
        : Colors.white.withValues(alpha: 0.3);
    final borderWidth = _f(layer['border_width'], 1.0) * (w / 390.0);

    final rawContent = layer['content'] as String?;
    final content = rawContent != null
        ? _resolveText(rawContent, headline, subheadline)
        : null;
    final textColor =
        _color(layer['text_color'], const Color(0xFF141A14));
    final fontSize = _f(layer['font_size'], 0.04) * w;
    final fontName = layer['font'] as String? ?? 'DM Sans';

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          ClipRRect(
            borderRadius: BorderRadius.circular(cr), child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur),
              child: Container(
                width: pw,
                height: ph,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(cr),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16 * (w / 390.0), vertical: 12 * (w / 390.0)),
                child: content != null
                    ? Text(
                        content,
                        textAlign: TextAlign.center,
                        style: _googleFont(
                          fontName,
                          TextStyle(
                            fontSize: fontSize,
                            color: textColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider Layer
// ─────────────────────────────────────────────────────────────────────────────

class _DividerLayer extends StatelessWidget {
  const _DividerLayer({
    required this.layer,
    required this.w,
    required this.h,
    this.isSelected = false,
    this.onTap,
    this.index,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
  });
  final VoidCallback? onTap;
  final int? index;
  final Map<String, dynamic> layer;
  final double w, h;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
//     final x = _f(layer['x']) * w;
//     final y = _f(layer['y']) * h;
    final width = _f(layer['width'], 1.0) * w;
    final thickness = _f(layer['thickness'], 0.001) * (w * 844 / 390);
    final color = _color(layer['color'], const Color(0x1F000000));

    return _Positioner(
      layer: layer, w: w, h: h,
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onLongPress: onLongPress,
      child: _apply3DTransform(
        _withSelection(
          Container(width: width, height: thickness, color: color),
          isSelected,
        ),
        layer,
      ),
    );
  }
}

Widget _apply3DTransform(Widget child, Map<String, dynamic> layer) {
  final rotZ = _f(layer['rotation']);
  final rotX = _f(layer['rotation_x']);
  final rotY = _f(layer['rotation_y']);

  if (rotX != 0 || rotY != 0 || rotZ != 0) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(rotX * math.pi / 180)
      ..rotateY(rotY * math.pi / 180)
      ..rotateZ(rotZ * math.pi / 180);

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: child,
    );
  }
  return child;
}

class _Positioner extends StatelessWidget {
  final Map<String, dynamic> layer;
  final double w;
  final double h;
  final Widget child;
  final void Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const _Positioner({
    required this.layer,
    required this.w,
    required this.h,
    required this.child,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final alignX = layer['align_x'] as String? ?? (layer.containsKey('cx') ? 'center' : 'left');
    final alignY = layer['align_y'] as String? ?? (layer.containsKey('cy') ? 'center' : 'top');

    final hasCx = layer.containsKey('cx');
    final hasCy = layer.containsKey('cy');

    final x = _f(layer['x'], 0.0);
    final y = _f(layer['y'], 0.0);
    final cx = _f(layer['cx'], 0.5);
    final cy = _f(layer['cy'], 0.5);

    double? posLeft, posRight, posTop, posBottom;
    double dx = 0.0, dy = 0.0;

    if (hasCx && alignX == 'center') {
      posLeft = cx * w;
      dx = -0.5;
    } else if (alignX == 'right') {
      posRight = x * w;
    } else if (alignX == 'center') {
      posLeft = (hasCx ? cx : x) * w;
      dx = -0.5;
    } else {
      posLeft = x * w;
    }

    if (hasCy && alignY == 'center') {
      posTop = cy * h;
      dy = -0.5;
    } else if (alignY == 'bottom') {
      posBottom = y * h;
    } else if (alignY == 'center') {
      posTop = (hasCy ? cy : y) * h;
      dy = -0.5;
    } else {
      posTop = y * h;
    }

    return Positioned(
      left: posLeft,
      right: posRight,
      top: posTop,
      bottom: posBottom,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onPanUpdate: onPanUpdate != null ? (details) => onPanUpdate!(details.delta) : null,
        onPanEnd: onPanEnd != null ? (_) => onPanEnd!() : null,
        behavior: HitTestBehavior.opaque,
        child: FractionalTranslation(
          translation: Offset(dx, dy),
          child: child,
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;
  _DiamondPainter({required this.color, this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 100.0;
    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    final path = Path()
      ..moveTo(50 * sx, 4 * sy)
      ..lineTo(96 * sx, 50 * sy)
      ..lineTo(50 * sx, 96 * sy)
      ..lineTo(4 * sx, 50 * sy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) => oldDelegate.color != color || oldDelegate.gradient != gradient;
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;
  _HeartPainter({required this.color, this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 100.0;
    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    final path = Path()
      ..moveTo(50 * sx, 25 * sy)
      ..cubicTo(50 * sx, 10 * sy, 20 * sx, 10 * sy, 20 * sx, 35 * sy)
      ..cubicTo(20 * sx, 55 * sy, 35 * sx, 72 * sy, 50 * sx, 90 * sy)
      ..cubicTo(65 * sx, 72 * sy, 80 * sx, 55 * sy, 80 * sx, 35 * sy)
      ..cubicTo(80 * sx, 10 * sy, 50 * sx, 10 * sy, 50 * sx, 25 * sy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) => oldDelegate.color != color || oldDelegate.gradient != gradient;
}

class _CrossPainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;
  _CrossPainter({required this.color, this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 100.0;
    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }
    final path = Path()
      ..moveTo(40 * sx, 4 * sy)
      ..lineTo(60 * sx, 4 * sy)
      ..lineTo(60 * sx, 40 * sy)
      ..lineTo(96 * sx, 40 * sy)
      ..lineTo(96 * sx, 60 * sy)
      ..lineTo(60 * sx, 60 * sy)
      ..lineTo(60 * sx, 96 * sy)
      ..lineTo(40 * sx, 96 * sy)
      ..lineTo(40 * sx, 60 * sy)
      ..lineTo(4 * sx, 60 * sy)
      ..lineTo(4 * sx, 40 * sy)
      ..lineTo(40 * sx, 40 * sy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) => oldDelegate.color != color || oldDelegate.gradient != gradient;
}
