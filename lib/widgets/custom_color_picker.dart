import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color hexToColor(String hex) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 3) {
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  }
  try {
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    } else if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return const Color(0xFF1A6B4A);
  } catch (_) {
    return const Color(0xFF1A6B4A);
  }
}

String colorToHex(Color c, {bool includeAlpha = false}) {
  final a = ((c.a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0').toUpperCase();
  final r = ((c.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0').toUpperCase();
  final g = ((c.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0').toUpperCase();
  final b = ((c.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0').toUpperCase();
  return includeAlpha ? '#$a$r$g$b' : '#$r$g$b';
}

String rawHexValue(String input) {
  return input.trim().replaceAll('#', '').toUpperCase();
}

// ─────────────────────────────────────────────────────────────────────────────
// Color History Manager
// ─────────────────────────────────────────────────────────────────────────────

class ColorHistoryManager extends ChangeNotifier {
  ColorHistoryManager._() {
    _loadHistory();
  }

  static final ColorHistoryManager instance = ColorHistoryManager._();

  static const List<String> defaultPresets = [
    '#1A6B4A', // Forest green (App Accent)
    '#141A14', // Ink Primary (Dark)
    '#FFFFFF', // Pure White
    '#FAF9F6', // Off White Canvas
    '#0082FF', // Electric Blue
    '#0040A3', // Deep Blue
    '#34C759', // Emerald Green
    '#FF9500', // Amber
    '#FF3B30', // Crimson Red
    '#FF2D55', // Neon Pink
    '#AF52DE', // Purple Orchid
    '#5856D6', // Royal Indigo
    '#00C7BE', // Teal Cyan
    '#636366', // Slate Grey
  ];

  final List<String> _history = [];

  List<String> get history => List.unmodifiable(_history.isNotEmpty ? _history : defaultPresets);

  void _loadHistory() {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final saved = box.get('color_history') as List?;
        if (saved != null && saved.isNotEmpty) {
          _history.clear();
          for (final item in saved) {
            if (item is String && item.isNotEmpty) {
              _history.add(item.toUpperCase());
            }
          }
        }
      }
    } catch (_) {}
    if (_history.isEmpty) {
      _history.addAll(defaultPresets);
    }
  }

  void addColor(String hex) {
    var clean = hex.trim().replaceAll('#', '').toUpperCase();
    if (clean.length == 3) {
      clean = '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    }
    if (clean.length != 6 && clean.length != 8) return;

    final formatted = '#$clean';
    _history.remove(formatted);
    _history.insert(0, formatted);

    if (_history.length > 20) {
      _history.removeRange(20, _history.length);
    }

    try {
      if (Hive.isBoxOpen('settings')) {
        Hive.box('settings').put('color_history', _history);
      }
    } catch (_) {}

    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Color Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────

class CustomColorPickerDialog extends StatefulWidget {
  final String initialHex;
  final ValueChanged<String> onColorSelected;

  const CustomColorPickerDialog({
    super.key,
    required this.initialHex,
    required this.onColorSelected,
  });

  static Future<String?> show(BuildContext context, {required String initialHex, required ValueChanged<String> onColorSelected}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomColorPickerDialog(
        initialHex: initialHex,
        onColorSelected: onColorSelected,
      ),
    );
  }

  @override
  State<CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late HSVColor _hsv;
  late Color _initialColor;

  @override
  void initState() {
    super.initState();
    _initialColor = hexToColor(widget.initialHex);
    _hsv = HSVColor.fromColor(_initialColor);
  }

  Color get _currentColor => _hsv.toColor();
  String get _currentHex => colorToHex(_currentColor);

  void _updateFromHSV(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
    });
    widget.onColorSelected(_currentHex);
  }

  void _applyAndClose() {
    ColorHistoryManager.instance.addColor(_currentHex);
    widget.onColorSelected(_currentHex);
    Navigator.of(context).pop(_currentHex);
  }

  @override
  Widget build(BuildContext context) {
    final curColor = _currentColor;
    final r = (curColor.r * 255.0).round();
    final g = (curColor.g * 255.0).round();
    final b = (curColor.b * 255.0).round();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
          boxShadow: AppShadows.float,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Title & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentTint,
                      borderRadius: BorderRadius.circular(AppRadius.r6),
                    ),
                    child: Text(
                      'COLOR PICKER',
                      style: AppText.labelSmall(color: AppColors.accent).copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, size: 16, color: AppColors.inkPrimary),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.borderSubtle, height: 1),

            // Scrollable picker content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 2D Saturation & Brightness Palette
                  _SaturationBrightnessCanvas(
                    hsv: _hsv,
                    onChanged: (s, v) {
                      _updateFromHSV(_hsv.withSaturation(s).withValue(v));
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. 1D Rainbow Hue Slider
                  _HueSlider(
                    hue: _hsv.hue,
                    onChanged: (newHue) {
                      _updateFromHSV(_hsv.withHue(newHue));
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Live Preview & Values Card (No elevation)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                      borderRadius: AppRadius.br12,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        // Before / After Color Pill (Flat, no elevation)
                        Container(
                          width: 64,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.br10,
                            border: Border.all(color: AppColors.borderSubtle, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  color: _initialColor,
                                  alignment: Alignment.center,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  color: curColor,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // RGB Numeric Badges
                        Expanded(
                          child: Row(
                            children: [
                              _ValueBadge(label: 'R', value: '$r'),
                              const SizedBox(width: 5),
                              _ValueBadge(label: 'G', value: '$g'),
                              const SizedBox(width: 5),
                              _ValueBadge(label: 'B', value: '$b'),
                              const SizedBox(width: 5),
                              _ValueBadge(label: 'H', value: '${_hsv.hue.round()}°'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Color History & Preset Swatches
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT & PRESETS',
                        style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${ColorHistoryManager.instance.history.length} colors',
                        style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  AnimatedBuilder(
                    animation: ColorHistoryManager.instance,
                    builder: (context, _) {
                      final history = ColorHistoryManager.instance.history;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: history.map((hex) {
                          final c = hexToColor(hex);
                          final isSelected = hex.toUpperCase() == _currentHex.toUpperCase();
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _updateFromHSV(HSVColor.fromColor(c));
                            },
                            child: AnimatedContainer(
                              duration: AppMotion.fast,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.borderSubtle,
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Icon(
                                        LucideIcons.check,
                                        size: 14,
                                        color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 5. Action Apply Button (Pill shape)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkPrimary,
                            side: const BorderSide(color: AppColors.borderDefault),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel', style: AppText.labelLarge()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyAndClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.accentOn,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, size: 16),
                              const SizedBox(width: 6),
                              Text('Apply Color', style: AppText.labelLarge(color: AppColors.accentOn)),
                            ],
                          ),
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
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// 2D Saturation / Brightness Canvas
// ─────────────────────────────────────────────────────────────────────────────

class _SaturationBrightnessCanvas extends StatelessWidget {
  final HSVColor hsv;
  final void Function(double saturation, double value) onChanged;

  const _SaturationBrightnessCanvas({
    required this.hsv,
    required this.onChanged,
  });

  void _handleGesture(Offset localPosition, Size size) {
    final s = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final cursorX = (hsv.saturation * size.width).clamp(0.0, size.width);
          final cursorY = ((1.0 - hsv.value) * size.height).clamp(0.0, size.height);

          return GestureDetector(
            onPanStart: (d) => _handleGesture(d.localPosition, size),
            onPanUpdate: (d) => _handleGesture(d.localPosition, size),
            onTapDown: (d) => _handleGesture(d.localPosition, size),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.br12,
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SaturationValuePainter(hue: hsv.hue),
                    ),
                  ),
                  // Draggable cursor
                  Positioned(
                    left: cursorX - 10,
                    top: cursorY - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hsv.toColor(),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  final double hue;

  _SaturationValuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final pureHueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final rect = Offset.zero & size;

    // 1. Horizontal saturation gradient (White to Pure Hue Color)
    final satGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, pureHueColor],
    );
    final satPaint = Paint()..shader = satGradient.createShader(rect);
    canvas.drawRect(rect, satPaint);

    // 2. Vertical brightness gradient (Transparent to Black)
    final valGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    final valPaint = Paint()..shader = valGradient.createShader(rect);
    canvas.drawRect(rect, valPaint);
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) => oldDelegate.hue != hue;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1D Rainbow Hue Slider
// ─────────────────────────────────────────────────────────────────────────────

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  void _handleGesture(Offset localPosition, Size size) {
    final fraction = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final newHue = (fraction * 360.0).clamp(0.0, 360.0);
    onChanged(newHue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 24);
        final thumbX = (hue / 360.0 * size.width).clamp(0.0, size.width);

        return GestureDetector(
          onPanStart: (d) => _handleGesture(d.localPosition, size),
          onPanUpdate: (d) => _handleGesture(d.localPosition, size),
          onTapDown: (d) => _handleGesture(d.localPosition, size),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brFull,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.brFull,
                    child: CustomPaint(
                      painter: _HueTrackPainter(),
                    ),
                  ),
                ),
                // Draggable thumb
                Positioned(
                  left: thumbX - 10,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HueTrackPainter extends CustomPainter {
  static const List<Color> _hueColors = [
    Color(0xFFFF0000), // 0
    Color(0xFFFFFF00), // 60
    Color(0xFF00FF00), // 120
    Color(0xFF00FFFF), // 180
    Color(0xFF0000FF), // 240
    Color(0xFFFF00FF), // 300
    Color(0xFFFF0000), // 360
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      colors: _hueColors,
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Value Badge Helper
// ─────────────────────────────────────────────────────────────────────────────

class _ValueBadge extends StatelessWidget {
  final String label;
  final String value;

  const _ValueBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: value,
                style: AppText.mono(color: AppColors.inkPrimary).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

