class Screenshot {
  const Screenshot({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.templateId,
    required this.canvasState,
    required this.thumbnailUrl,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String collectionId;
  final String name;
  final String templateId;
  final Map<String, dynamic> canvasState; // serialized canvas elements
  final String thumbnailUrl; // URL to cached thumbnail
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Screenshot copyWith({
    String? id,
    String? collectionId,
    String? name,
    Map<String, dynamic>? canvasState,
    String? thumbnailUrl,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Screenshot(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      name: name ?? this.name,
      templateId: templateId,
      canvasState: canvasState ?? this.canvasState,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'collectionId': collectionId,
        'name': name,
        'templateId': templateId,
        'canvasState': canvasState,
        'thumbnailUrl': thumbnailUrl,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Screenshot.fromMap(Map<String, dynamic> map) => Screenshot(
        id: map['id'] as String,
        collectionId: map['collectionId'] as String,
        name: map['name'] as String,
        templateId: map['templateId'] as String,
        canvasState: Map<String, dynamic>.from(map['canvasState'] as Map),
        thumbnailUrl: map['thumbnailUrl'] as String? ?? map['thumbnailPath'] as String? ?? '',
        order: map['order'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
