import 'package:flutter/material.dart';

class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.userId,
    required this.color,
    required this.screenshotIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String userId;
  final Color color;
  final List<String> screenshotIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get screenshotCount => screenshotIds.length;

  Collection copyWith({
    String? name,
    Color? color,
    List<String>? screenshotIds,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id,
      name: name ?? this.name,
      userId: userId,
      color: color ?? this.color,
      screenshotIds: screenshotIds ?? this.screenshotIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'userId': userId,
        'color': color.toARGB32(),
        'screenshotIds': screenshotIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Collection.fromMap(Map<String, dynamic> map) => Collection(
        id: map['id'] as String,
        name: map['name'] as String,
        userId: map['userId'] as String,
        color: Color(map['color'] as int),
        screenshotIds: List<String>.from(map['screenshotIds'] as List),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

/// 25 preset colors for collections
const collectionColors = [
  Color(0xFF1A6B4A), // accent green
  Color(0xFF2563EB), // blue
  Color(0xFF7C3AED), // purple
  Color(0xFFDB2777), // pink
  Color(0xFFD97706), // amber
  Color(0xFF059669), // emerald
  Color(0xFFDC2626), // red
  Color(0xFF475247), // slate
  Color(0xFF0D9488), // teal
  Color(0xFF4F46E5), // indigo
  Color(0xFF9333EA), // purple
  Color(0xFFE11D48), // rose
  Color(0xFFEA580C), // orange
  Color(0xFF65A30D), // lime
  Color(0xFF0284C7), // light blue
  Color(0xFF0891B2), // cyan
  Color(0xFFC026D3), // fuchsia
  Color(0xFFBE185D), // pink-dark
  Color(0xFFB45309), // amber-dark
  Color(0xFF15803D), // green-dark
  Color(0xFF1E3A8A), // blue-dark
  Color(0xFF581C87), // purple-dark
  Color(0xFF831843), // pink-deep
  Color(0xFF14532D), // green-deep
  Color(0xFF7F1D1D), // red-dark
];
