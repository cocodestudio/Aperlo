import 'package:flutter/material.dart';

enum CanvasElementType { text, image, shape, deviceFrame, sticker }

class CanvasElement {
  const CanvasElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
    required this.zIndex,
    this.properties = const {},
  });

  final String id;
  final CanvasElementType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation; // degrees
  final double opacity; // 0.0 - 1.0
  final int zIndex;
  final Map<String, dynamic> properties; // type-specific

  CanvasElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    int? zIndex,
    Map<String, dynamic>? properties,
  }) {
    return CanvasElement(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'opacity': opacity,
        'zIndex': zIndex,
        'properties': properties,
      };

  factory CanvasElement.fromMap(Map<String, dynamic> map) => CanvasElement(
        id: map['id'] as String,
        type: CanvasElementType.values.byName(map['type'] as String),
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        width: (map['width'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        rotation: (map['rotation'] as num).toDouble(),
        opacity: (map['opacity'] as num).toDouble(),
        zIndex: map['zIndex'] as int,
        properties: Map<String, dynamic>.from(map['properties'] as Map),
      );
}

/// Canvas background — color, gradient, or image
class CanvasBackground {
  const CanvasBackground.color(this.color)
      : gradient = null,
        imageUrl = null;

  const CanvasBackground.gradient(this.gradient)
      : color = null,
        imageUrl = null;

  const CanvasBackground.image(this.imageUrl)
      : color = null,
        gradient = null;

  final Color? color;
  final Gradient? gradient;
  final String? imageUrl;

  static CanvasBackground get defaultBg => const CanvasBackground.color(Color(0xFFFFFFFF));

  Map<String, dynamic> toMap() {
    if (color != null) return {'type': 'color', 'value': color!.toARGB32()};
    if (imageUrl != null) return {'type': 'image', 'value': imageUrl};
    return {'type': 'color', 'value': 0xFFFFFFFF};
  }
}

/// Full editor state — snapshot for undo/redo stack
class EditorState {
  const EditorState({
    required this.elements,
    required this.background,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final List<CanvasElement> elements;
  final CanvasBackground background;
  final double canvasWidth;
  final double canvasHeight;

  EditorState copyWith({
    List<CanvasElement>? elements,
    CanvasBackground? background,
  }) {
    return EditorState(
      elements: elements ?? this.elements,
      background: background ?? this.background,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );
  }
}
