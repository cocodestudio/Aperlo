import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/collection.dart';
import '../models/screenshot.dart';

class LocalDataService {
  Box get _collectionsBox => Hive.box('collections');
  Box get _screenshotsBox => Hive.box('screenshots');
  Box get _settingsBox => Hive.box('settings');
  Box get _templateDiscoveryBox => Hive.box('template_discovery');

  // ── General Settings ──────────────────────────────────

  int get appFirstLaunchTime {
    return _settingsBox.get('app_first_launch_time', defaultValue: 0) as int;
  }

  // ── Template Discovery ────────────────────────────────

  int? getTemplateDiscoveryTime(String templateId) {
    return _templateDiscoveryBox.get(templateId) as int?;
  }

  Future<void> setTemplateDiscoveryTime(String templateId, int timestamp) async {
    await _templateDiscoveryBox.put(templateId, timestamp);
  }

  // ── Collections ───────────────────────────────────────

  Stream<List<Collection>> collectionsStream() async* {
    yield getCollections();
    await for (final _ in _collectionsBox.watch()) {
      yield getCollections();
    }
  }

  List<Collection> getCollections() {
    final List<Collection> collections = [];
    for (var key in _collectionsBox.keys) {
      final data = _collectionsBox.get(key);
      if (data != null) {
        collections.add(Collection.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    collections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return collections;
  }

  Collection? getCollection(String collectionId) {
    final data = _collectionsBox.get(collectionId);
    return data != null ? Collection.fromMap(Map<String, dynamic>.from(data)) : null;
  }

  Future<void> saveCollection(Collection c) async {
    await _collectionsBox.put(c.id, c.toMap());
  }

  Future<void> deleteCollection(String collectionId) async {
    // Also delete associated screenshots and their files
    final screenshots = getScreenshots(collectionId);
    for (var s in screenshots) {
      await deleteScreenshot(s.id);
    }
    await _collectionsBox.delete(collectionId);
  }

  // ── Screenshots ───────────────────────────────────────

  Stream<List<Screenshot>> recentScreenshotsStream() async* {
    yield getRecentScreenshots();
    await for (final _ in _screenshotsBox.watch()) {
      yield getRecentScreenshots();
    }
  }

  List<Screenshot> getRecentScreenshots() {
    final List<Screenshot> screenshots = [];
    for (var key in _screenshotsBox.keys) {
      final data = _screenshotsBox.get(key);
      if (data != null) {
        screenshots.add(Screenshot.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    screenshots.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return screenshots.take(3).toList();
  }

  Stream<List<Screenshot>> screenshotsStream(String collectionId) async* {
    yield getScreenshots(collectionId);
    await for (final _ in _screenshotsBox.watch()) {
      yield getScreenshots(collectionId);
    }
  }

  List<Screenshot> getScreenshots(String collectionId) {
    final List<Screenshot> screenshots = [];
    for (var key in _screenshotsBox.keys) {
      final data = _screenshotsBox.get(key);
      if (data != null) {
        final s = Screenshot.fromMap(Map<String, dynamic>.from(data));
        if (s.collectionId == collectionId) {
          screenshots.add(s);
        }
      }
    }
    screenshots.sort((a, b) => a.order.compareTo(b.order));
    return screenshots;
  }

  Future<void> saveScreenshot(Screenshot s) async {
    await _screenshotsBox.put(s.id, s.toMap());
  }

  Future<void> deleteScreenshot(String screenshotId) async {
    // Delete associated files
    final data = _screenshotsBox.get(screenshotId);
    if (data != null) {
      final s = Screenshot.fromMap(Map<String, dynamic>.from(data));
      if (s.thumbnailUrl.isNotEmpty) {
        final thumbFile = File(s.thumbnailUrl);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
      if (s.canvasState.containsKey('screenshotImagePath')) {
        final imagePath = s.canvasState['screenshotImagePath'] as String?;
        if (imagePath != null && !imagePath.startsWith('http')) {
          final imgFile = File(imagePath);
          if (await imgFile.exists()) {
            await imgFile.delete();
          }
        }
      }
    }
    await _screenshotsBox.delete(screenshotId);
  }

  Future<Map<String, dynamic>?> getScreenshotDoc(String screenshotId) async {
    final data = _screenshotsBox.get(screenshotId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> saveCanvasState(String screenshotId, Map<String, dynamic> canvasState) async {
    final data = _screenshotsBox.get(screenshotId);
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      map['canvasState'] = canvasState;
      map['updatedAt'] = DateTime.now().toIso8601String();
      await _screenshotsBox.put(screenshotId, map);
    }
  }

  Future<void> saveScreenshotThumbnail(String screenshotId, String url) async {
    final data = _screenshotsBox.get(screenshotId);
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      map['thumbnailUrl'] = url;
      map['updatedAt'] = DateTime.now().toIso8601String();
      await _screenshotsBox.put(screenshotId, map);
    }
  }

  Future<void> renameScreenshot(String screenshotId, String newName) async {
    final data = _screenshotsBox.get(screenshotId);
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      map['name'] = newName;
      await _screenshotsBox.put(screenshotId, map);
    }
  }
}
