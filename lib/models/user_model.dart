class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isPro,
    required this.defaultExportFormat,
    required this.autoSave,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isPro;
  final String defaultExportFormat; // 'png' | 'jpg' | 'webp'
  final bool autoSave;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    bool? isPro,
    String? defaultExportFormat,
    bool? autoSave,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPro: isPro ?? this.isPro,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      autoSave: autoSave ?? this.autoSave,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'isPro': isPro,
        'defaultExportFormat': defaultExportFormat,
        'autoSave': autoSave,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        avatarUrl: map['avatarUrl'] as String? ?? '',
        isPro: map['isPro'] as bool? ?? false,
        defaultExportFormat: map['defaultExportFormat'] as String? ?? 'png',
        autoSave: map['autoSave'] as bool? ?? true,
      );
}
