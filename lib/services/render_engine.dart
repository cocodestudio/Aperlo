import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RenderEngine {
  /// Renders a [widget] off-screen at the exact [pixelWidth] and [pixelHeight].
  /// Does not mutate the on-screen UI tree.
  static Future<ui.Image> renderTemplateAtResolution({
    required Widget templateWidget,
    required int pixelWidth,
    required int pixelHeight,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();

    // Create a constrained Box for the target size
    final logicalSize = Size(pixelWidth.toDouble(), pixelHeight.toDouble());
    
    // We use the primary view to back the render view
    final view = ui.PlatformDispatcher.instance.implicitView ?? ui.PlatformDispatcher.instance.views.first;

    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: 1.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: logicalSize),
          child: templateWidget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Give asynchronous images a moment to decode
    await Future.delayed(const Duration(milliseconds: 500));

    // Flush a second time to capture late-resolving textures
    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    return repaintBoundary.toImage(pixelRatio: 1.0);
  }
}
