import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_color_picker.dart';

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

class PropertySheetSection {
  final String title;
  final Widget content;

  const PropertySheetSection({
    required this.title,
    required this.content,
  });
}

class PropertySheetLayout extends StatefulWidget {
  final List<Widget>? children;
  final List<PropertySheetSection>? sections;

  const PropertySheetLayout({
    super.key,
    this.children,
    this.sections,
  });

  @override
  State<PropertySheetLayout> createState() => _PropertySheetLayoutState();
}

class _PropertySheetLayoutState extends State<PropertySheetLayout> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final hasTabs = sections != null && sections.length > 1;

    Widget activeContent;
    if (sections != null && sections.isNotEmpty) {
      final safeIdx = _activeTabIndex.clamp(0, sections.length - 1);
      final activeSection = sections[safeIdx];
      activeContent = KeyedSubtree(
        key: ValueKey(activeSection.title),
        child: activeSection.content,
      );
    } else {
      activeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: widget.children ?? const [],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
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

          // Section Tab Switcher
          if (hasTabs)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 0, AppSpacing.s20, AppSpacing.s4),
              child: TogglePillGroup(
                options: sections.map((s) => s.title).toList(),
                selectedValue: sections[_activeTabIndex.clamp(0, sections.length - 1)].title,
                onChanged: (title) {
                  final idx = sections.indexWhere((s) => s.title == title);
                  if (idx != -1) {
                    setState(() => _activeTabIndex = idx);
                  }
                },
              ),
            ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: activeContent,
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

  const PropertyColorPicker({
    super.key,
    required this.label,
    required this.hexColor,
    required this.onChanged,
  });

  @override
  State<PropertyColorPicker> createState() => _PropertyColorPickerState();
}

class _PropertyColorPickerState extends State<PropertyColorPicker> {
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: rawHexValue(widget.hexColor));
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(PropertyColorPicker old) {
    super.didUpdateWidget(old);
    final rawOld = rawHexValue(old.hexColor);
    final rawNew = rawHexValue(widget.hexColor);
    if (rawOld != rawNew) {
      if (_ctrl.text.toUpperCase() != rawNew) {
        _ctrl.text = rawNew;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitColor(String rawVal) {
    var clean = rawVal.trim().replaceAll('#', '').toUpperCase();
    if (clean.length == 3) {
      clean = '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    }
    if (clean.length == 6 || clean.length == 8) {
      final formatted = '#$clean';
      ColorHistoryManager.instance.addColor(formatted);
      widget.onChanged(formatted);
    }
  }

  void _openColorPickerDialog() {
    HapticFeedback.selectionClick();
    CustomColorPickerDialog.show(
      context,
      initialHex: widget.hexColor,
      onColorSelected: (selectedHex) {
        final clean = rawHexValue(selectedHex);
        _ctrl.text = clean;
        widget.onChanged(selectedHex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = hexToColor(widget.hexColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.label, style: AppText.labelLarge()),
        ),

        // Row: Left-side flat live color preview box + Flat Hex Input Field with # prefix icon
        Row(
          children: [
            // Flat Live Color Preview Box (NO ELEVATION, flat clean border)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: AppRadius.br10,
                border: Border.all(color: AppColors.borderDefault, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),

            // Flat Hex Input Field (same font as font size: DMSans 700)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _isFocused ? AppColors.surface : AppColors.surfaceMuted.withValues(alpha: 0.6),
                  borderRadius: AppRadius.br10,
                  border: Border.all(
                    color: _isFocused ? AppColors.accent : AppColors.borderDefault,
                    width: _isFocused ? 1.8 : 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hash,
                      size: 16,
                      color: _isFocused ? AppColors.accent : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        style: AppText.bodyLarge(color: AppColors.inkPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                        onSubmitted: _submitColor,
                        onChanged: (val) {
                          var clean = val.replaceAll('#', '').toUpperCase();
                          if (clean.length > 8) clean = clean.substring(0, 8);
                          if (clean != val) {
                            _ctrl.value = TextEditingValue(
                              text: clean,
                              selection: TextSelection.collapsed(offset: clean.length),
                            );
                          }
                          _submitColor(clean);
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '1A6B4A',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Swatches list: includes "+" button to trigger color picker dialog + real-time history/preset swatches
        AnimatedBuilder(
          animation: ColorHistoryManager.instance,
          builder: (context, _) {
            final history = ColorHistoryManager.instance.history;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // "+" button to trigger custom color picker dialog
                  GestureDetector(
                    onTap: _openColorPickerDialog,
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: const Icon(LucideIcons.plus, size: 16, color: AppColors.accent),
                    ),
                  ),

                  // Swatches
                  ...history.take(14).map((hex) {
                    final c = hexToColor(hex);
                    final isSelected = widget.hexColor.toUpperCase() == hex.toUpperCase();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _ctrl.text = rawHexValue(hex);
                        ColorHistoryManager.instance.addColor(hex);
                        widget.onChanged(hex);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.borderDefault,
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
                  }),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 14),
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

  const PropertySlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  State<PropertySlider> createState() => _PropertySliderState();
}

class _PropertySliderState extends State<PropertySlider> {
  bool _dragging = false;

  void _updateValue(double localDx, double trackWidth) {
    if (trackWidth <= 0) return;
    const thumbDiameter = 28.0;
    final availableWidth = trackWidth - thumbDiameter;
    if (availableWidth <= 0) return;
    final clampedX = (localDx - (thumbDiameter / 2)).clamp(0.0, availableWidth);
    final fraction = (clampedX / availableWidth).clamp(0.0, 1.0);
    final newValue = widget.min + fraction * (widget.max - widget.min);
    widget.onChanged(newValue);
  }

  void _step(double delta) {
    HapticFeedback.selectionClick();
    final newValue = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.max - widget.min;
    final fraction = range > 0 ? ((widget.value - widget.min) / range).clamp(0.0, 1.0) : 0.0;
    final displayValue = widget.valueFormatter != null
        ? widget.valueFormatter!(widget.value)
        : widget.value.toStringAsFixed(2);

    final step = range > 20 ? 1.0 : (range > 2 ? 0.1 : 0.05);

    const trackHeight = 16.0;
    const thumbDiameter = 28.0;
    const totalTouchHeight = 44.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Label & Value Stepper Pill ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: AppText.labelLarge().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Micro Stepper Decrement
                  _StepperButton(
                    icon: LucideIcons.minus,
                    onTap: () => _step(-step),
                  ),
                  const SizedBox(width: 4),

                  // Value Badge Pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _dragging ? AppColors.accent : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: _dragging ? AppColors.accent : AppColors.borderSubtle,
                        width: 1,
                      ),
                      boxShadow: [
                        if (_dragging)
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    child: Text(
                      displayValue,
                      style: AppText.bodyDefault(
                        color: _dragging ? AppColors.accentOn : AppColors.inkPrimary,
                      ).copyWith(fontSize: 12.0, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Micro Stepper Increment
                  _StepperButton(
                    icon: LucideIcons.plus,
                    onTap: () => _step(step),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Interactive Track & Floating Thumb ──────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final maxThumbOffset = (trackWidth - thumbDiameter).clamp(0.0, trackWidth);
              final thumbLeft = (fraction * maxThumbOffset).clamp(0.0, maxThumbOffset);
              final fillWidth = thumbLeft + (thumbDiameter / 2);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  HapticFeedback.selectionClick();
                  setState(() => _dragging = true);
                  _updateValue(d.localPosition.dx, trackWidth);
                },
                onPanEnd: (_) => setState(() => _dragging = false),
                onPanCancel: () => setState(() => _dragging = false),
                onPanUpdate: (d) => _updateValue(d.localPosition.dx, trackWidth),
                onTapDown: (d) {
                  HapticFeedback.selectionClick();
                  setState(() => _dragging = true);
                  _updateValue(d.localPosition.dx, trackWidth);
                },
                onTapUp: (_) => setState(() => _dragging = false),
                child: SizedBox(
                  height: totalTouchHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // ── Track Base Capsule ──────────────────────────────
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (totalTouchHeight - trackHeight) / 2,
                        height: trackHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(trackHeight / 2),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Subtle notch guide marks
                              Positioned.fill(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(3, (index) {
                                    return Container(
                                      width: 1.5,
                                      height: 5.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.borderStrong.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              // Active Fill Pill
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: fillWidth.clamp(0.0, trackWidth),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF135338),
                                        Color(0xFF1A6B4A),
                                        Color(0xFF268A60),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(trackHeight / 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Floating Precision Thumb ────────────────────────
                      Positioned(
                        left: thumbLeft,
                        top: (totalTouchHeight - thumbDiameter) / 2,
                        child: AnimatedScale(
                          scale: _dragging ? 1.14 : 1.0,
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: thumbDiameter,
                            height: thumbDiameter,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _dragging ? AppColors.accent : AppColors.borderStrong,
                                width: _dragging ? 2.4 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: _dragging ? 0.22 : 0.12),
                                  blurRadius: _dragging ? 8 : 4,
                                  spreadRadius: _dragging ? 1 : 0,
                                  offset: Offset(0, _dragging ? 3 : 1.5),
                                ),
                                if (_dragging)
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                width: _dragging ? 10.0 : 7.0,
                                height: _dragging ? 10.0 : 7.0,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (_dragging)
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                              ),
                            ),
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.r6),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r6),
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r6),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Icon(icon, size: 11, color: AppColors.inkSecondary),
        ),
      ),
    );
  }
}

class TogglePillGroup extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const TogglePillGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  static const double _padding = 4.0;
  static const double _height = 42.0;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexOf(selectedValue).clamp(0, options.isEmpty ? 0 : options.length - 1);

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: AppRadius.brFull,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brFull,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - (_padding * 2);
            final itemWidth = options.isNotEmpty ? availableWidth / options.length : availableWidth;
            final pillHeight = constraints.maxHeight - (_padding * 2);

            return Stack(
              children: [
                // Inner sliding active pill indicator
                if (options.isNotEmpty && selectedIndex >= 0)
                  AnimatedPositioned(
                    duration: AppMotion.base,
                    curve: AppMotion.easeOut,
                    left: _padding + (selectedIndex * itemWidth),
                    top: _padding,
                    width: itemWidth,
                    height: pillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.brFull,
                        boxShadow: AppShadows.subtle,
                      ),
                    ),
                  ),
                // Row of interactive tab options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _padding),
                  child: Row(
                    children: options.map((opt) {
                      final isSelected = opt == selectedValue;
                      return SizedBox(
                        width: itemWidth,
                        height: constraints.maxHeight,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: AppRadius.brFull,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            borderRadius: AppRadius.brFull,
                            splashColor: isSelected
                                ? Colors.transparent
                                : AppColors.accent.withValues(alpha: 0.14),
                            highlightColor: isSelected
                                ? Colors.transparent
                                : AppColors.accent.withValues(alpha: 0.06),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onChanged(opt);
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: AppMotion.fast,
                                style: AppText.labelDefault(
                                  color: isSelected ? AppColors.accentOn : AppColors.inkMuted,
                                ).copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                child: Text(
                                  opt,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
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
            Material(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.br10,
              child: InkWell(
                borderRadius: AppRadius.br10,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: Icon(LucideIcons.minus, size: 16)),
                ),
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
                child: Text(
                  value.toStringAsFixed(1),
                  style: AppText.bodyLarge(color: AppColors.inkPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Material(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.br10,
              child: InkWell(
                borderRadius: AppRadius.br10,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: Icon(LucideIcons.plus, size: 16)),
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: AppRadius.br12,
        child: InkWell(
          borderRadius: AppRadius.br12,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              borderRadius: AppRadius.br12,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppText.labelLarge().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.inkMuted),
              ],
            ),
          ),
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
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(icon, size: 20)),
          ),
        ),
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
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.br10,
        child: InkWell(
          borderRadius: AppRadius.br10,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.layer);
  }

  void _updateData() {
    setState(() {});
    widget.onSave(_data);
  }

  @override
  Widget build(BuildContext context) {
    return PropertySheetLayout(
      sections: [
        PropertySheetSection(
          title: 'Solid Color',
          content: buildSection('Solid Color', [
            PropertyColorPicker(
              label: 'Color',
              hexColor: _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['color'] = c;
                  _data.remove('gradient');
                  _data.remove('split_at');
                });
                _updateData();
              },
            ),
          ]),
        ),
        PropertySheetSection(
          title: 'Linear Gradient',
          content: buildSection('Linear Gradient', [
            PropertyColorPicker(
              label: 'Start Color',
              hexColor: (_data['gradient'] as List?)?[0] as String? ?? '#0082FF',
              onChanged: (c) {
                setState(() {
                  if (_data['gradient'] == null) _data['gradient'] = ['#0082FF', '#0040A3'];
                  _data['gradient'][0] = c;
                  _data.remove('color');
                  _data.remove('split_at');
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
                  _data.remove('color');
                  _data.remove('split_at');
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
        ),
        PropertySheetSection(
          title: 'Grid Lines',
          content: buildSection('Grid Lines Pattern', [
            PropertyColorPicker(
              label: 'Base Background',
              hexColor: _data['bg_color'] as String? ?? _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['bg_color'] = c;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Grid Line Color',
              hexColor: _data['grid_color'] as String? ?? _data['pattern_color'] as String? ?? '#1A6B4A',
              onChanged: (c) {
                setState(() {
                  _data['grid_color'] = c;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Line Width',
              value: (_data['grid_line_width'] as num?)?.toDouble() ?? 1.5,
              min: 0.5, max: 8.0,
              valueFormatter: (v) => '${v.toStringAsFixed(1)} px',
              onChanged: (v) {
                setState(() {
                  _data['grid_line_width'] = v;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Grid Spacing',
              value: (_data['grid_spacing'] as num?)?.toDouble() ?? 32.0,
              min: 10.0, max: 100.0,
              valueFormatter: (v) => '${v.toInt()} px',
              onChanged: (v) {
                setState(() {
                  _data['grid_spacing'] = v;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Line Opacity',
              value: (_data['grid_opacity'] as num?)?.toDouble() ?? 0.15,
              min: 0.05, max: 1.0,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() {
                  _data['grid_opacity'] = v;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Grid Angle',
              value: (_data['grid_angle'] as num?)?.toDouble() ?? 0.0,
              min: 0.0, max: 90.0,
              valueFormatter: (v) => '${v.toInt()}°',
              onChanged: (v) {
                setState(() {
                  _data['grid_angle'] = v;
                  _data['bg_type'] = 'grid';
                });
                _updateData();
              },
            ),
          ]),
        ),
        PropertySheetSection(
          title: 'Dot Matrix',
          content: buildSection('Dot Matrix Pattern', [
            PropertyColorPicker(
              label: 'Base Background',
              hexColor: _data['bg_color'] as String? ?? _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['bg_color'] = c;
                  _data['bg_type'] = 'dots';
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Dot Color',
              hexColor: _data['dot_color'] as String? ?? _data['pattern_color'] as String? ?? '#1A6B4A',
              onChanged: (c) {
                setState(() {
                  _data['dot_color'] = c;
                  _data['bg_type'] = 'dots';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Dot Size',
              value: (_data['dot_size'] as num?)?.toDouble() ?? 3.0,
              min: 1.0, max: 12.0,
              valueFormatter: (v) => '${v.toStringAsFixed(1)} px',
              onChanged: (v) {
                setState(() {
                  _data['dot_size'] = v;
                  _data['bg_type'] = 'dots';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Dot Spacing',
              value: (_data['dot_spacing'] as num?)?.toDouble() ?? 24.0,
              min: 10.0, max: 80.0,
              valueFormatter: (v) => '${v.toInt()} px',
              onChanged: (v) {
                setState(() {
                  _data['dot_spacing'] = v;
                  _data['bg_type'] = 'dots';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Dot Opacity',
              value: (_data['dot_opacity'] as num?)?.toDouble() ?? 0.20,
              min: 0.05, max: 1.0,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() {
                  _data['dot_opacity'] = v;
                  _data['bg_type'] = 'dots';
                });
                _updateData();
              },
            ),
          ]),
        ),
        PropertySheetSection(
          title: 'Stripes',
          content: buildSection('Diagonal Stripes', [
            PropertyColorPicker(
              label: 'Base Background',
              hexColor: _data['bg_color'] as String? ?? _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['bg_color'] = c;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Stripe Color',
              hexColor: _data['stripe_color'] as String? ?? _data['pattern_color'] as String? ?? '#1A6B4A',
              onChanged: (c) {
                setState(() {
                  _data['stripe_color'] = c;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Stripe Width',
              value: (_data['stripe_width'] as num?)?.toDouble() ?? 8.0,
              min: 2.0, max: 30.0,
              valueFormatter: (v) => '${v.toInt()} px',
              onChanged: (v) {
                setState(() {
                  _data['stripe_width'] = v;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Stripe Spacing',
              value: (_data['stripe_spacing'] as num?)?.toDouble() ?? 28.0,
              min: 10.0, max: 80.0,
              valueFormatter: (v) => '${v.toInt()} px',
              onChanged: (v) {
                setState(() {
                  _data['stripe_spacing'] = v;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Stripe Opacity',
              value: (_data['stripe_opacity'] as num?)?.toDouble() ?? 0.15,
              min: 0.05, max: 1.0,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() {
                  _data['stripe_opacity'] = v;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Stripe Angle',
              value: (_data['stripe_angle'] as num?)?.toDouble() ?? 45.0,
              min: 0.0, max: 180.0,
              valueFormatter: (v) => '${v.toInt()}°',
              onChanged: (v) {
                setState(() {
                  _data['stripe_angle'] = v;
                  _data['bg_type'] = 'stripes';
                });
                _updateData();
              },
            ),
          ]),
        ),
        PropertySheetSection(
          title: 'Sunburst Rays',
          content: buildSection('Sunburst Rays', [
            PropertyColorPicker(
              label: 'Base Background',
              hexColor: _data['bg_color'] as String? ?? _data['color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['bg_color'] = c;
                  _data['bg_type'] = 'rays';
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Ray Color',
              hexColor: _data['ray_color'] as String? ?? _data['pattern_color'] as String? ?? '#1A6B4A',
              onChanged: (c) {
                setState(() {
                  _data['ray_color'] = c;
                  _data['bg_type'] = 'rays';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Ray Count',
              value: (_data['ray_count'] as num?)?.toDouble() ?? 16.0,
              min: 6.0, max: 36.0,
              valueFormatter: (v) => '${v.toInt()} rays',
              onChanged: (v) {
                setState(() {
                  _data['ray_count'] = v.toInt();
                  _data['bg_type'] = 'rays';
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Ray Opacity',
              value: (_data['ray_opacity'] as num?)?.toDouble() ?? 0.15,
              min: 0.05, max: 1.0,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() {
                  _data['ray_opacity'] = v;
                  _data['bg_type'] = 'rays';
                });
                _updateData();
              },
            ),
          ]),
        ),
        PropertySheetSection(
          title: 'Split Colors',
          content: buildSection('Split Colors', [
            PropertyColorPicker(
              label: 'Top Color',
              hexColor: _data['top_color'] as String? ?? '#FAF9F6',
              onChanged: (c) {
                setState(() {
                  _data['top_color'] = c;
                  _data['bg_type'] = 'split';
                  if (_data['split_at'] == null) _data['split_at'] = 0.5;
                  _data.remove('color');
                  _data.remove('gradient');
                });
                _updateData();
              },
            ),
            PropertyColorPicker(
              label: 'Bottom Color',
              hexColor: _data['bottom_color'] as String? ?? '#F5F7F5',
              onChanged: (c) {
                setState(() {
                  _data['bottom_color'] = c;
                  _data['bg_type'] = 'split';
                  if (_data['split_at'] == null) _data['split_at'] = 0.5;
                  _data.remove('color');
                  _data.remove('gradient');
                });
                _updateData();
              },
            ),
            PropertySlider(
              label: 'Split Ratio',
              value: (_data['split_at'] as num?)?.toDouble() ?? 0.5,
              min: 0.1, max: 0.9,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) {
                setState(() {
                  _data['split_at'] = v;
                  _data['bg_type'] = 'split';
                });
                _updateData();
              },
            ),
          ]),
        ),
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

  static const List<MapEntry<String, String>> _styles = [
    MapEntry('dynamic_island', 'Dynamic Island'),
    MapEntry('bar_notch', 'Bar Notch'),
    MapEntry('punch_hole', 'Punch Hole'),
    MapEntry('flat', 'Flat'),
    MapEntry('none', 'No Notch'),
  ];

  Widget _phoneSkeleton(String style, bool isSelected) {
    final color = isSelected ? AppColors.accent : AppColors.inkDisabled;
    final frameColor = isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surfaceMuted;
    
    Widget notch;
    switch (style) {
      case 'dynamic_island':
        notch = Container(
          margin: const EdgeInsets.only(top: 3),
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      case 'bar_notch':
        notch = Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2.5),
              bottomRight: Radius.circular(2.5),
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
            margin: const EdgeInsets.only(top: 3, left: 3),
            width: 3,
            height: 3,
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
      width: 26,
      height: 44,
      decoration: BoxDecoration(
        color: frameColor,
        border: Border.all(
          color: color,
          width: isSelected ? 2.0 : 1.5,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.topCenter,
      child: notch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Mockup Style', style: AppText.labelLarge()),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.12,
          ),
          itemCount: _styles.length,
          itemBuilder: (context, index) {
            final e = _styles[index];
            final isSelected = e.key == value;
            return Material(
              color: isSelected ? AppColors.accentTint : AppColors.surfaceMuted.withValues(alpha: 0.45),
              borderRadius: AppRadius.br12,
              child: InkWell(
                borderRadius: AppRadius.br12,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(e.key);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.br12,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.borderSubtle,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _phoneSkeleton(e.key, isSelected),
                      const SizedBox(height: 5),
                      Text(
                        e.value,
                        style: AppText.labelSmall(
                          color: isSelected ? AppColors.accent : AppColors.inkSecondary,
                        ).copyWith(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
