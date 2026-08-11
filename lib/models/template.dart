import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as enc;

class Template {
  const Template({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailUrl,
    required this.isPro,
    required this.isDownloaded,
    required this.localPath,
    required this.fileSizeBytes,
    required this.deviceType,
    required this.description,
    required this.tags,
    required this.screenshotSlots,
    this.headlineFont = 'Syne',
    this.subheadlineFont = 'DM Sans',
    this.layout = const [],
    this.createdAt,
    this.totalUses = 0,
  });

  final String id;
  final String name;
  final String category;
  final String thumbnailUrl;
  final bool isPro;
  final bool isDownloaded;
  final String localPath; // empty if not downloaded
  final int fileSizeBytes;
  final DeviceType deviceType;
  final String description;
  final List<String> tags;
  final int screenshotSlots;
  final String headlineFont;
  final String subheadlineFont;
  final List<Map<String, dynamic>> layout;
  final int? createdAt;
  final int totalUses;

  String get fileSizeLabel {
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Template copyWith({bool? isDownloaded, String? localPath}) => Template(
        id: id, name: name, category: category, thumbnailUrl: thumbnailUrl,
        isPro: isPro, isDownloaded: isDownloaded ?? this.isDownloaded,
        localPath: localPath ?? this.localPath, fileSizeBytes: fileSizeBytes,
        deviceType: deviceType, description: description, tags: tags,
        screenshotSlots: screenshotSlots, 
        headlineFont: headlineFont, subheadlineFont: subheadlineFont,
        layout: layout,
        createdAt: createdAt,
        totalUses: totalUses,
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'name': name, 'category': category, 'thumbnailUrl': thumbnailUrl,
        'isPro': isPro, 'isDownloaded': isDownloaded, 'localPath': localPath,
        'fileSizeBytes': fileSizeBytes, 'deviceType': deviceType.name,
        'description': description, 'tags': tags, 'screenshotSlots': screenshotSlots,
        'headlineFont': headlineFont, 'subheadlineFont': subheadlineFont,
        'layout': layout,
        'createdAt': createdAt,
        'totalUses': totalUses,
      };

  static final _secretKey = enc.Key.fromUtf8('FrameKitSecureKey2026!@#\$1234567');

  static int? _parseCreatedAt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is Timestamp) return val.millisecondsSinceEpoch;
    if (val is String) {
      final parsedInt = int.tryParse(val);
      if (parsedInt != null) return parsedInt;
      final parsedDate = DateTime.tryParse(val);
      if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
    }
    return null;
  }

  factory Template.fromMap(Map<String, dynamic> originalMap) {
    // Create a mutable copy
    final map = Map<String, dynamic>.from(originalMap);

    // Decrypt if encryptedData is present
    if (map.containsKey('encryptedData')) {
      try {
        final parts = (map['encryptedData'] as String).split(':');
        if (parts.length == 2) {
          final iv = enc.IV.fromBase64(parts[0]);
          final ciphertext = parts[1];
          final encrypter = enc.Encrypter(enc.AES(_secretKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));
          
          final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
          final decryptedMap = jsonDecode(decrypted) as Map<String, dynamic>;
          
          // Merge decrypted sensitive data into the map
          map.addAll(decryptedMap);
        }
      } catch (e) {
        // Handle decryption failure
      }
    }

    return Template(
        id: map['id'] as String? ?? '', 
        name: map['name'] as String? ?? 'Encrypted Template',
        category: map['category'] as String? ?? 'Unknown', 
        thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        isPro: map['isPro'] as bool? ?? false, 
        isDownloaded: map['isDownloaded'] as bool? ?? false,
        localPath: map['localPath'] as String? ?? '',
        fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
        deviceType: DeviceType.values.byName(map['deviceType'] as String? ?? 'phone'),
        description: map['description'] as String? ?? '',
        tags: List<String>.from(map['tags'] as List? ?? []),
        screenshotSlots: map['screenshotSlots'] as int? ?? 1,
        headlineFont: map['headlineFont'] as String? ?? 'Syne',
        subheadlineFont: map['subheadlineFont'] as String? ?? 'DM Sans',
        layout: (map['layout'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        createdAt: _parseCreatedAt(map['createdAt']),
        totalUses: map['totalUses'] as int? ?? 0,
      );
  }
}

enum DeviceType { phone, tablet, desktop }
