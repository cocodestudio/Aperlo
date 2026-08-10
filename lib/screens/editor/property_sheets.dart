import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// Common helpers
Color hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  try {
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  } catch (_) {
    return const Color(0xFF1A6B4A);
  }
}

String colorToHex(Color c) {
  return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

Widget buildSection(String title, List<Widget> children) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title.toUpperCase(), style: AppText.labelSmall(color: AppColors.inkMuted).copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Divider(color: AppColors.borderSubtle, thickness: 1, height: 1),
    ),
    ...children,
    const SizedBox(height: 20),
  ]);
}

class PropertySheetLayout extends StatelessWidget {
  final List<Widget> children;

  const PropertySheetLayout({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyColorPicker extends StatefulWidget {
  final String label;
  final String hexColor;
  final ValueChanged<String> onChanged;
  const PropertyColorPicker({super.key, required this.label, required this.hexColor, required this.onChanged});

  @override
  State<PropertyColorPicker> createState() => _PropertyColorPickerState();
}

class _PropertyColorPickerState extends State<PropertyColorPicker> {
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  
  static const _presetColors = [
    Color(0xFF141A14), Color(0xFFFFFFFF), Color(0xFF1A6B4A), Color(0xFF0082FF),
    Color(0xFFFF3B30), Color(0xFF007AFF), Color(0xFFFF9500), Color(0xFF34C759),
    Color(0xFF5856D6), Color(0xFFAF52DE), Color(0xFFFF2D55), Color(0xFF636366),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _formatHex(widget.hexColor));
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  String _formatHex(String input) {
    var val = input.replaceAll('#', '').toUpperCase();
    return '#$val';
  }
  
  @override
  void didUpdateWidget(PropertyColorPicker old) {
    super.didUpdateWidget(old);
    if (old.hexColor != widget.hexColor) {
      final formatted = _formatHex(widget.hexColor);
      if (_ctrl.text != formatted) {
        _ctrl.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitColor(String val) {
    var clean = val.trim().replaceAll('#', '');
    if (clean.length == 6 || clean.length == 8 || clean.length == 3) {
      final formatted = '#${clean.toUpperCase()}';
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color currentColor = hexToColor(widget.hexColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.label, style: AppText.labelLarge()),
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDefault, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                decoration: BoxDecoration(
                  color: _isFocused ? AppColors.surface : AppColors.surfaceMuted.withValues(alpha: 0.6),
                  borderRadius: AppRadius.br10,
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hash,
                      size: 15,
                      color: _isFocused ? AppColors.accent : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        style: AppText.mono(color: AppColors.inkPrimary).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                        onSubmitted: _submitColor,
                        onChanged: (val) {
                          if (!val.startsWith('#')) {
                            _ctrl.text = '#$val';
                            _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
                          }
                          _submitColor(_ctrl.text);
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '#1A6B4A',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((c) {
            final hex = colorToHex(c);
            final isSelected = widget.hexColor.toUpperCase() == hex.toUpperCase();
            return GestureDetector(
              onTap: () {
                _ctrl.text = hex;
                widget.onChanged(hex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.borderDefault,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class PropertySlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  const PropertySlider({super.key, required this.label, required this.value, required this.min, required this.max, required this.onChanged, this.valueFormatter});

  @override
  State<PropertySlider> createState() => _PropertySliderState();
}

class _PropertySliderState extends State<PropertySlider> {
  bool _dragging = false;

  void _updateValue(double localDx, double maxWidth) {
    if (maxWidth <= 0) return;
    final fraction = (localDx / maxWidth).clamp(0.0, 1.0);
    widget.onChanged(widget.min + fraction * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final fraction = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final displayValue = widget.valueFormatter != null
        ? widget.valueFormatter!(widget.value)
        : widget.value.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: AppText.labelLarge()),
              // Value badge pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _dragging ? AppColors.accent : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  displayValue,
                  style: AppText.mono(color: _dragging ? AppColors.accentOn : AppColors.inkSecondary).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const thumbR = 11.0;
              const trackH = 6.0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => setState(() => _dragging = true),
                onPanEnd: (_) => setState(() => _dragging = false),
                onPanCancel: () => setState(() => _dragging = false),
                onPanUpdate: (d) => _updateValue(d.localPosition.dx, trackWidth),
                onTapDown: (d) {
                  setState(() => _dragging = true);
                  _updateValue(d.localPosition.dx, trackWidth);
                },
                onTapUp: (_) => setState(() => _dragging = false),
                child: SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Track background
                      Positioned.fill(
                        top: (36 - trackH) / 2,
                        bottom: (36 - trackH) / 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(trackH / 2),
                          ),
                        ),
                      ),
                      // Active fill
                      Positioned(
                        left: 0,
                        top: (36 - trackH) / 2,
                        bottom: (36 - trackH) / 2,
                        width: fraction * trackWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentTint, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(trackH / 2),
                          ),
                        ),
                      ),
                      // Thumb
                      Positioned(
                        left: (fraction * trackWidth - thumbR).clamp(0, trackWidth - thumbR * 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: thumbR * 2,
                          height: thumbR * 2,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent,
                              width: _dragging ? 2.5 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: _dragging ? 0.35 : 0.18),
                                blurRadius: _dragging ? 10 : 5,
                                offset: const Offset(0, 2),
                              ),
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
        ],
      ),
    );
  }
}

class TogglePillGroup extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const TogglePillGroup({super.key, required this.options, required this.selectedValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.br10,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: AppRadius.br6,
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: AppText.labelDefault(color: isSelected ? AppColors.inkPrimary : AppColors.inkMuted).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TextAlignmentControl extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const TextAlignmentControl({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Text Alignment', style: AppText.labelLarge()),
        ),
        TogglePillGroup(
          options: const ['Left', 'Center', 'Right'],
          selectedValue: value == 'center' ? 'Center' : (value == 'right' ? 'Right' : 'Left'),
          onChanged: (val) => onChanged(val.toLowerCase()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class PropertyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  
  const PropertyDropdown({super.key, required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label, style: AppText.labelLarge()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted.withValues(alpha: 0.3),
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: AppRadius.br10,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.inkMuted),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppText.bodyDefault()))).toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class StyledInputNumeric extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const StyledInputNumeric({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label, style: AppText.labelLarge()),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(value - 1),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.br10,
                ),
                child: const Icon(LucideIcons.minus, size: 16),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderDefault),
                  borderRadius: AppRadius.br10,
                ),
                alignment: Alignment.center,
                child: Text(value.toStringAsFixed(1), style: AppText.bodyLarge()),
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.br10,
                ),
                child: const Icon(LucideIcons.plus, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class StyledActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const StyledActionTile({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.3),
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: AppRadius.br10,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Text(label, style: AppText.labelLarge()),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class StyledPositionNudge extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const StyledPositionNudge({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Position Nudge', style: AppText.labelLarge()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNudgeButton(LucideIcons.arrowUp, onUp),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNudgeButton(LucideIcons.arrowLeft, onLeft),
            const SizedBox(width: 40),
            _buildNudgeButton(LucideIcons.arrowRight, onRight),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNudgeButton(LucideIcons.arrowDown, onDown),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNudgeButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Position Presets — snap element to preset positions
// ─────────────────────────────────────────────────────────────────────────────

class PositionPresets extends StatelessWidget {
  final VoidCallback onSnapLeft;
  final VoidCallback onSnapRight;
  final VoidCallback onSnapTop;
  final VoidCallback onSnapBottom;
  final VoidCallback onSnapCenterH;
  final VoidCallback onSnapCenterV;

  const PositionPresets({
    super.key,
    required this.onSnapLeft,
    required this.onSnapRight,
    required this.onSnapTop,
    required this.onSnapBottom,
    required this.onSnapCenterH,
    required this.onSnapCenterV,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Snap Position', style: AppText.labelLarge()),
        ),
        // Row 1 — horizontal axis
        Row(
          children: [
            _preset('Left',     LucideIcons.alignLeft,           onSnapLeft),
            const SizedBox(width: 8),
            _preset('Center H', LucideIcons.alignCenter,         onSnapCenterH),
            const SizedBox(width: 8),
            _preset('Right',    LucideIcons.alignRight,          onSnapRight),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2 — vertical axis
        Row(
          children: [
            _preset('Top',      LucideIcons.alignStartVertical,  onSnapTop),
            const SizedBox(width: 8),
            _preset('Center V', LucideIcons.alignCenterVertical, onSnapCenterV),
            const SizedBox(width: 8),
            _preset('Bottom',   LucideIcons.alignEndVertical,    onSnapBottom),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _preset(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.br10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.inkSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.labelSmall(color: AppColors.inkSecondary)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LayerBackgroundEditSheet extends StatefulWidget {
  final Map<String, dynamic> layer;
  final void Function(Map<String, dynamic>) onSave;
  
  const LayerBackgroundEditSheet({super.key, required this.layer, required this.onSave});

  @override
  State<LayerBackgroundEditSheet> createState() => _LayerBackgroundEditSheetState();
}

class _LayerBackgroundEditSheetState extends State<LayerBackgroundEditSheet> {
  late Map<String, dynamic> _data;
  late String _bgType;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.layer);
    
    if (_data['gradient'] != null && (_data['gradient'] as List).length >= 2) {
      _bgType = 'Linear Gradient';
    } else if (_data['split_at'] != null) {
      _bgType = 'Split Colors';
    } else {
      _bgType = 'Solid Color';
    }
  }

  void _updateData() {
    setState(() {});
    widget.onSave(_data);
  }

  @override
  Widget build(BuildContext context) {
    return PropertySheetLayout(
      children: [
        buildSection('Type', [
          TogglePillGroup(
            options: const ['Solid Color', 'Linear Gradient', 'Split Colors'],
            selectedValue: _bgType,
            onChanged: (v) {
              setState(() {
                _bgType = v;
                _data.remove('color');
                _data.remove('gradient');
                _data.remove('begin');
                _data.remove('end');
                _data.remove('split_at');
                _data.remove('top_color');
                _data.remove('bottom_color');
                
                if (_bgType == 'Solid Color') {
                  _data['color'] = '#FAF9F6';
                } else if (_bgType == 'Linear Gradient') {
                  _data['gradient'] = ['#0082FF', '#0040A3'];
                  _data['begin'] = 'topCenter';
                  _data['end'] = 'bottomCenter';
                } else if (_bgType == 'Split Colors') {
                  _data['split_at'] = 0.5;
                  _data['top_color'] = '#FAF9F6';
                  _data['bottom_color'] = '#F5F7F5';
                }
                _updateData();
              });
            },
          ),
        ]),
        
        if (_bgType == 'Solid Color')
          buildSection('Solid Color', [
            PropertyColorPicker(
              label: 'Color',
              hexColor: _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() => _data['color'] = c);
                _updateData();
              },
            ),
          ]),
          
        if (_bgType == 'Linear Gradient')
          buildSection('Linear Gradient', [
            PropertyColorPicker(
              label: 'Start Color',
              hexColor: (_data['gradient'] as List?)?[0] as String? ?? '#0082FF',
              onChanged: (c) {
                setState(() {
                  if (_data['gradient'] == null) _data['gradient'] = ['#0082FF', '#0040A3'];
                  _data['gradient'][0] = c;
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'End Color',
              hexColor: (_data['gradient'] as List?)?[1] as String? ?? '#0040A3',
              onChanged: (c) {
                setState(() {
                  if (_data['gradient'] == null) _data['gradient'] = ['#0082FF', '#0040A3'];
                  _data['gradient'][1] = c;
                });
                _updateData();
              },
            ),
            PropertyDropdown(
              label: 'Direction (Start)',
              value: _data['begin'] as String? ?? 'topCenter',
              items: const ['topCenter', 'topLeft', 'centerLeft', 'bottomLeft'],
              onChanged: (v) {
                setState(() => _data['begin'] = v);
                _updateData();
              },
            ),
            PropertyDropdown(
              label: 'Direction (End)',
              value: _data['end'] as String? ?? 'bottomCenter',
              items: const ['bottomCenter', 'bottomRight', 'centerRight', 'topRight'],
              onChanged: (v) {
                setState(() => _data['end'] = v);
                _updateData();
              },
            ),
          ]),
        
        if (_bgType == 'Split Colors')
          buildSection('Split Colors', [
            PropertyColorPicker(
              label: 'Top Color',
              hexColor: _data['top_color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() => _data['top_color'] = c);
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Bottom Color',
              hexColor: _data['bottom_color'] as String? ?? '#F5F7F5',
              onChanged: (c) {
                setState(() => _data['bottom_color'] = c);
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Split Ratio',
              value: (_data['split_at'] as num?)?.toDouble() ?? 0.5,
              min: 0.1, max: 0.9,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() => _data['split_at'] = v);
                _updateData();
              },
            ),
          ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mockup Style Selector
// ─────────────────────────────────────────────────────────────────────────────

class MockupStyleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const MockupStyleSelector({super.key, required this.value, required this.onChanged});

  static const Map<String, String> _styles = {
    'dynamic_island': 'Dynamic Island',
    'circle_notch': 'Circle Notch',
    'bar_notch': 'Bar Notch',
    'punch_hole': 'Punch Hole',
    'flat': 'Flat (Android)',
    'none': 'No Notch',
  };

  Widget _phoneSkeleton(String style, bool isSelected) {
    final color = isSelected ? AppColors.accent : AppColors.inkDisabled;
    final frameColor = isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surfaceMuted;
    
    Widget notch;
    switch (style) {
      case 'dynamic_island':
        notch = Container(
          margin: const EdgeInsets.only(top: 3),
          width: 11,
          height: 3.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'circle_notch':
        notch = Container(
          margin: const EdgeInsets.only(top: 2.5),
          width: 9,
          height: 4.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
          child: Center(
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case 'bar_notch':
        notch = Container(
          width: 14,
          height: 4.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
        );
      case 'punch_hole':
        notch = Container(
          margin: const EdgeInsets.only(top: 3),
          width: 3.5,
          height: 3.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case 'flat':
        notch = Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 3, left: 4),
            width: 3.5,
            height: 3.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      case 'none':
      default:
        notch = const SizedBox();
    }

    return Container(
      width: 28,
      height: 48,
      decoration: BoxDecoration(
        color: frameColor,
        border: Border.all(
          color: color,
          width: isSelected ? 2.0 : 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.topCenter,
      child: notch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Mockup Style', style: AppText.labelLarge()),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _styles.entries.map((e) {
            final isSelected = e.key == value;
            return GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentTint : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _phoneSkeleton(e.key, isSelected),
                    const SizedBox(height: 6),
                    Text(
                      e.value,
                      style: AppText.labelSmall(
                        color: isSelected ? AppColors.accent : AppColors.inkMuted,
                      ).copyWith(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
