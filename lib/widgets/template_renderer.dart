import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Data model for a template's editable fields
class TemplateData {
  const TemplateData({
    this.headline = 'Your headline here',
    this.subheadline = 'A short description that tells users what they get',
    this.screenshotImage, // user's app screenshot
    this.backgroundColor = const Color(0xFFF5F7F5),
    this.accentColor = const Color(0xFF1A6B4A),
    this.headlineColor = const Color(0xFF141A14),
    this.subheadlineColor = const Color(0xFF475247),
  });

  final String headline;
  final String subheadline;
  final ImageProvider? screenshotImage;
  final Color backgroundColor;
  final Color accentColor;
  final Color headlineColor;
  final Color subheadlineColor;

  TemplateData copyWith({
    String? headline,
    String? subheadline,
    ImageProvider? screenshotImage,
    Color? backgroundColor,
    Color? accentColor,
    Color? headlineColor,
    Color? subheadlineColor,
  }) =>
      TemplateData(
        headline: headline ?? this.headline,
        subheadline: subheadline ?? this.subheadline,
        screenshotImage: screenshotImage ?? this.screenshotImage,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        accentColor: accentColor ?? this.accentColor,
        headlineColor: headlineColor ?? this.headlineColor,
        subheadlineColor: subheadlineColor ?? this.subheadlineColor,
      );
}

/// Routes to correct template layout by ID
Widget buildTemplate(String templateId, TemplateData data, {double width = 390, double height = 844}) {
  switch (templateId) {
    case 'tpl_minimal_001': return _TemplateCenteredPhone(data: data, width: width, height: height);
    case 'tpl_minimal_002': return _TemplateSageStudio(data: data, width: width, height: height);
    case 'tpl_bold_001':   return _TemplateBoldSplit(data: data, width: width, height: height);
    case 'tpl_bold_002':   return _TemplateForestDark(data: data, width: width, height: height);
    case 'tpl_dark_001':   return _TemplateInkNight(data: data, width: width, height: height);
    case 'tpl_dark_002':   return _TemplateSlateOverlay(data: data, width: width, height: height);
    case 'tpl_gradient_001': return _TemplateGradientSide(data: data, width: width, height: height);
    case 'tpl_illustration_001': return _TemplateGeometric(data: data, width: width, height: height);
    case 'tpl_typography_001': return _TemplateTypeFirst(data: data, width: width, height: height);
    default: return _TemplateCenteredPhone(data: data, width: width, height: height);
  }
}

// ── Phone mockup widget (reused by all templates) ──────────────────────────

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.screenshot,
    required this.width,
    this.frameColor = const Color(0xFF1C1C1E),
  });

  final ImageProvider? screenshot;
  final double width;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    final height = width * 2.1;
    final innerW = width - 12;
    final innerH = height - 12;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(36.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: SizedBox(
            width: innerW,
            height: innerH,
            child: screenshot != null
                ? Image(image: screenshot!, fit: BoxFit.cover)
                : _ScreenshotPlaceholder(width: innerW, height: innerH),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotPlaceholder extends StatelessWidget {
  const _ScreenshotPlaceholder({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: width * 0.2, color: AppColors.inkDisabled),
          const SizedBox(height: 8),
          Text(
            'Tap to add\nscreenshot',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.06,
              color: AppColors.inkDisabled,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 1: Centered phone — headline top, phone middle, subheadline bottom
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateCenteredPhone extends StatelessWidget {
  const _TemplateCenteredPhone({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.62;
    return Container(
      width: width, height: height,
      color: data.backgroundColor,
      child: Column(
        children: [
          SizedBox(height: height * 0.08),
          // Accent pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'NEW',
              style: TextStyle(fontSize: width * 0.032, fontWeight: FontWeight.w700, color: data.accentColor, letterSpacing: 1.2),
            ),
          ),
          SizedBox(height: height * 0.025),
          // Headline
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Text(
              data.headline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.082, fontWeight: FontWeight.w800, color: data.headlineColor, height: 1.15, letterSpacing: -0.5),
            ),
          ),
          SizedBox(height: height * 0.022),
          // Subheadline
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Text(
              data.subheadline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.042, color: data.subheadlineColor, height: 1.55),
            ),
          ),
          SizedBox(height: height * 0.04),
          // Phone
          Expanded(
            child: _PhoneMockup(screenshot: data.screenshotImage, width: phoneW),
          ),
          SizedBox(height: height * 0.02),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 2: Sage Studio — soft green top half, phone overlapping, text below
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateSageStudio extends StatelessWidget {
  const _TemplateSageStudio({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.58;
    final topH = height * 0.52;

    return Container(
      width: width, height: height,
      color: AppColors.surface,
      child: Stack(
        children: [
          // Top colored block
          Container(
            height: topH,
            color: const Color(0xFFEDF3EE),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: height * 0.06),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Text(
                      data.headline,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(fontSize: width * 0.076, fontWeight: FontWeight.w800, color: data.headlineColor, height: 1.2, letterSpacing: -0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Phone centered overlapping the two halves
          Positioned(
            top: topH - (phoneW * 2.1 * 0.45),
            left: (width - phoneW) / 2,
            child: _PhoneMockup(
              screenshot: data.screenshotImage,
              width: phoneW,
              frameColor: const Color(0xFF2A3D2E),
            ),
          ),
          // Bottom text
          Positioned(
            bottom: height * 0.05,
            left: width * 0.1,
            right: width * 0.1,
            child: Text(
              data.subheadline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.042, color: data.subheadlineColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 3: Bold Split — dark top half text, light bottom, phone spanning
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateBoldSplit extends StatelessWidget {
  const _TemplateBoldSplit({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.55;
    final topH = height * 0.48;

    return Container(
      width: width, height: height,
      color: AppColors.surface,
      child: Stack(
        children: [
          // Dark top
          Container(
            height: topH,
            color: const Color(0xFF141A14),
            child: Padding(
              padding: EdgeInsets.fromLTRB(width * 0.08, height * 0.1, width * 0.08, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: width * 0.08,
                    height: 3,
                    color: data.accentColor,
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    data.headline,
                    maxLines: 3,
                    style: TextStyle(fontSize: width * 0.085, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ),
          // Light bottom
          Positioned(
            top: topH,
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: const Color(0xFFF5F7F5),
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.fromLTRB(width * 0.08, 0, width * 0.08, height * 0.06),
              child: Text(
                data.subheadline,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: width * 0.04, color: data.subheadlineColor, height: 1.55),
              ),
            ),
          ),
          // Phone centered
          Positioned(
            top: topH - (phoneW * 2.1 * 0.5),
            left: (width - phoneW) / 2,
            child: _PhoneMockup(screenshot: data.screenshotImage, width: phoneW),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 4: Forest Dark — full dark bg, phone right-aligned, text left
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateForestDark extends StatelessWidget {
  const _TemplateForestDark({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.52;

    return Container(
      width: width, height: height,
      color: const Color(0xFF0D1F15),
      child: Stack(
        children: [
          // Subtle glow behind phone
          Positioned(
            right: -phoneW * 0.3,
            top: height * 0.15,
            child: Container(
              width: phoneW * 1.6,
              height: phoneW * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Text block left
          Positioned(
            left: width * 0.07,
            top: height * 0.12,
            width: width * 0.52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 3, color: data.accentColor),
                SizedBox(height: height * 0.02),
                Text(
                  data.headline,
                  maxLines: 4,
                  style: TextStyle(fontSize: width * 0.075, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                ),
                SizedBox(height: height * 0.025),
                Text(
                  data.subheadline,
                  maxLines: 3,
                  style: TextStyle(fontSize: width * 0.038, color: Colors.white.withValues(alpha: 0.6), height: 1.55),
                ),
              ],
            ),
          ),
          // Phone right side
          Positioned(
            right: -phoneW * 0.12,
            top: height * 0.1,
            child: _PhoneMockup(
              screenshot: data.screenshotImage,
              width: phoneW,
              frameColor: const Color(0xFF1A2E20),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 5: Ink Night — full dark, phone bottom, big text top
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateInkNight extends StatelessWidget {
  const _TemplateInkNight({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.6;

    return Container(
      width: width, height: height,
      color: const Color(0xFF111318),
      child: Column(
        children: [
          SizedBox(height: height * 0.1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.07),
            child: Text(
              data.headline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.09, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.6),
            ),
          ),
          SizedBox(height: height * 0.025),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Text(
              data.subheadline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.04, color: Colors.white.withValues(alpha: 0.55), height: 1.55),
            ),
          ),
          SizedBox(height: height * 0.04),
          // Separator line
          Container(
            width: width * 0.15,
            height: 2,
            color: data.accentColor,
          ),
          SizedBox(height: height * 0.04),
          Expanded(
            child: _PhoneMockup(
              screenshot: data.screenshotImage,
              width: phoneW,
              frameColor: const Color(0xFF1C2026),
            ),
          ),
          SizedBox(height: height * 0.02),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 6: Slate Overlay — phone full height left, text card right
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateSlateOverlay extends StatelessWidget {
  const _TemplateSlateOverlay({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.56;

    return Container(
      width: width, height: height,
      color: const Color(0xFF1C2026),
      child: Stack(
        children: [
          // Phone left-center
          Positioned(
            left: -phoneW * 0.1,
            top: (height - phoneW * 2.1) / 2,
            child: _PhoneMockup(
              screenshot: data.screenshotImage,
              width: phoneW,
              frameColor: const Color(0xFF252B33),
            ),
          ),
          // Text card right
          Positioned(
            right: width * 0.04,
            top: height * 0.28,
            width: width * 0.42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PRO', style: TextStyle(fontSize: width * 0.03, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                ),
                SizedBox(height: height * 0.02),
                Text(
                  data.headline,
                  maxLines: 4,
                  style: TextStyle(fontSize: width * 0.068, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: -0.3),
                ),
                SizedBox(height: height * 0.02),
                Text(
                  data.subheadline,
                  maxLines: 3,
                  style: TextStyle(fontSize: width * 0.035, color: Colors.white.withValues(alpha: 0.55), height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 7: Gradient Side — gradient bg, phone centered with blur glow
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateGradientSide extends StatelessWidget {
  const _TemplateGradientSide({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.6;

    return Container(
      width: width, height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A6B4A), Color(0xFF0D3B6E)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: height * 0.08),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.07),
            child: Text(
              data.headline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.082, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.5),
            ),
          ),
          SizedBox(height: height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Text(
              data.subheadline,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: width * 0.04, color: Colors.white.withValues(alpha: 0.75), height: 1.55),
            ),
          ),
          SizedBox(height: height * 0.04),
          Expanded(
            child: _PhoneMockup(screenshot: data.screenshotImage, width: phoneW, frameColor: const Color(0x33FFFFFF)),
          ),
          SizedBox(height: height * 0.02),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 8: Geometric — light bg, geometric shapes, phone center
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateGeometric extends StatelessWidget {
  const _TemplateGeometric({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.56;

    return Container(
      width: width, height: height,
      color: const Color(0xFFF0F4F0),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -width * 0.15, right: -width * 0.15,
            child: _Circle(size: width * 0.55, color: const Color(0xFF1A6B4A).withValues(alpha: 0.1))),
          Positioned(bottom: -width * 0.2, left: -width * 0.1,
            child: _Circle(size: width * 0.65, color: const Color(0xFF1A6B4A).withValues(alpha: 0.07))),
          Positioned(top: height * 0.35, left: width * 0.04,
            child: _Circle(size: width * 0.08, color: const Color(0xFF1A6B4A).withValues(alpha: 0.3))),
          // Content
          Column(
            children: [
              SizedBox(height: height * 0.07),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: Text(
                  data.headline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: width * 0.08, fontWeight: FontWeight.w800, color: data.headlineColor, height: 1.15, letterSpacing: -0.4),
                ),
              ),
              SizedBox(height: height * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                child: Text(
                  data.subheadline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: width * 0.04, color: data.subheadlineColor, height: 1.55),
                ),
              ),
              SizedBox(height: height * 0.04),
              Expanded(
                child: _PhoneMockup(screenshot: data.screenshotImage, width: phoneW),
              ),
              SizedBox(height: height * 0.02),
            ],
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Template 9: Type First — big bold text left, small phone right
// ═══════════════════════════════════════════════════════════════════════════
class _TemplateTypeFirst extends StatelessWidget {
  const _TemplateTypeFirst({required this.data, required this.width, required this.height});
  final TemplateData data;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final phoneW = width * 0.38;

    return Container(
      width: width, height: height,
      color: AppColors.surface,
      child: Stack(
        children: [
          // Vertical accent bar
          Positioned(
            left: width * 0.07,
            top: height * 0.12,
            bottom: height * 0.12,
            child: Container(width: 3, color: data.accentColor),
          ),
          // Big text
          Positioned(
            left: width * 0.13,
            top: height * 0.1,
            width: width * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.headline,
                  maxLines: 5,
                  style: TextStyle(fontSize: width * 0.09, fontWeight: FontWeight.w800, color: data.headlineColor, height: 1.1, letterSpacing: -0.5),
                ),
                SizedBox(height: height * 0.03),
                Text(
                  data.subheadline,
                  maxLines: 3,
                  style: TextStyle(fontSize: width * 0.038, color: data.subheadlineColor, height: 1.6),
                ),
              ],
            ),
          ),
          // Phone right
          Positioned(
            right: width * 0.02,
            top: (height - phoneW * 2.1) / 2,
            child: _PhoneMockup(screenshot: data.screenshotImage, width: phoneW),
          ),
        ],
      ),
    );
  }
}
