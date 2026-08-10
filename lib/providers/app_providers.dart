import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/local_data_service.dart';
import '../models/collection.dart';
import '../models/screenshot.dart';
import '../models/template.dart';
import '../models/canvas_element.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// ── Services ────────────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(FirebaseFirestore.instance),
);

final localDataServiceProvider = Provider<LocalDataService>(
  (ref) => LocalDataService(),
);

// ── Collections ─────────────────────────────────────────

final collectionsProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(localDataServiceProvider).collectionsStream();
});

class CollectionsNotifier extends Notifier<void> {
  @override
  void build() {}

  LocalDataService get _db => ref.read(localDataServiceProvider);

  Future<Collection> create(String name, int colorValue) async {
    final now = DateTime.now();
    final c = Collection(
      id: const Uuid().v4(),
      name: name,
      userId: 'local_user', // Local mode, user ID doesn't matter much
      color: collectionColors[colorValue % collectionColors.length],
      screenshotIds: [],
      createdAt: now,
      updatedAt: now,
    );
    await _db.saveCollection(c);
    return c;
  }

  Future<void> rename(Collection c, String name) =>
      _db.saveCollection(c.copyWith(name: name, updatedAt: DateTime.now()));

  Future<void> delete(Collection c) => _db.deleteCollection(c.id);

  Future<void> addScreenshot(Collection c, String screenshotId) =>
      _db.saveCollection(c.copyWith(
        screenshotIds: [...c.screenshotIds, screenshotId],
        updatedAt: DateTime.now(),
      ));

  Future<void> removeScreenshot(Collection c, String screenshotId) =>
      _db.saveCollection(c.copyWith(
        screenshotIds: c.screenshotIds.where((id) => id != screenshotId).toList(),
        updatedAt: DateTime.now(),
      ));
}

final collectionsNotifierProvider = NotifierProvider<CollectionsNotifier, void>(
  CollectionsNotifier.new,
);

// ── Screenshots ─────────────────────────────────────────

final screenshotsProvider =
    StreamProvider.family<List<Screenshot>, String>((ref, collectionId) {
  return ref.watch(localDataServiceProvider).screenshotsStream(collectionId);
});

final recentScreenshotsProvider = StreamProvider<List<Screenshot>>((ref) {
  return ref.watch(localDataServiceProvider).recentScreenshotsStream();
});

class ScreenshotsNotifier extends Notifier<void> {
  @override
  void build() {}

  LocalDataService get _db => ref.read(localDataServiceProvider);

  Future<Screenshot> create({
    required String collectionId,
    required String templateId,
    required String name,
    required int order,
  }) async {
    final now = DateTime.now();
    final s = Screenshot(
      id: const Uuid().v4(),
      collectionId: collectionId,
      name: name,
      templateId: templateId,
      canvasState: {},
      thumbnailUrl: '',
      order: order,
      createdAt: now,
      updatedAt: now,
    );
    await _db.saveScreenshot(s);
    return s;
  }

  Future<void> save(Screenshot s) => _db.saveScreenshot(s);

  Future<void> delete(String id) => _db.deleteScreenshot(id);
}

final screenshotsNotifierProvider = NotifierProvider<ScreenshotsNotifier, void>(
  ScreenshotsNotifier.new,
);

// ── Templates ────────────────────────────────────────────

class TemplatesNotifier extends AutoDisposeFamilyAsyncNotifier<List<Template>, String?> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  FutureOr<List<Template>> build(String? arg) async {
    _lastDoc = null;
    _hasMore = true;
    return _fetch(isFirst: true);
  }

  Future<List<Template>> _fetch({bool isFirst = false}) async {
    if (!isFirst && !_hasMore) return state.value ?? [];
    
    final res = await ref.read(firestoreServiceProvider).getTemplatesPaginated(
      category: arg,
      startAfter: _lastDoc,
      limit: isFirst ? 10 : 5,
    );
    
    final newTemplates = res['templates'] as List<Template>;
    _lastDoc = res['lastDoc'] as DocumentSnapshot?;
    _hasMore = res['hasMore'] as bool;

    if (isFirst) return newTemplates;
    
    final current = state.value ?? [];
    return [...current, ...newTemplates];
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;
    final newTemplates = await _fetch();
    state = AsyncData(newTemplates);
  }
}

final templatesProvider = AutoDisposeAsyncNotifierProviderFamily<TemplatesNotifier, List<Template>, String?>(
  TemplatesNotifier.new,
);

final templateNewBadgeProvider = Provider.family<bool, Template>((ref, template) {
  final createdAt = template.createdAt;
  if (createdAt == null) return false;

  final localData = ref.watch(localDataServiceProvider);
  final appFirstLaunchTime = localData.appFirstLaunchTime;
  
  if (appFirstLaunchTime == 0) return false;
  if (createdAt < appFirstLaunchTime) return false; // Uploaded before user installed

  var discoveredAt = localData.getTemplateDiscoveryTime(template.id);
  final now = DateTime.now().millisecondsSinceEpoch;

  if (discoveredAt == null) {
    // User is seeing it for the first time right now!
    discoveredAt = now;
    // We cannot await inside a standard Provider. We'll fire and forget.
    Future.microtask(() => localData.setTemplateDiscoveryTime(template.id, now));
  }

  final difference = now - discoveredAt;
  const threeDaysMs = 3 * 24 * 60 * 60 * 1000;
  
  return difference <= threeDaysMs;
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');



// ── Editor ───────────────────────────────────────────────

class EditorNotifier extends Notifier<EditorNotifierState> {
  static const _maxUndo = 50;

  @override
  EditorNotifierState build() => EditorNotifierState.empty();

  void init(EditorState initial) {
    state = EditorNotifierState(
      current: initial,
      undoStack: [],
      redoStack: [],
      selectedElementId: null,
      zoomLevel: 1.0,
    );
  }

  void _push(EditorState next) {
    final undoStack = [...state.undoStack, state.current];
    state = state.copyWith(
      current: next,
      undoStack: undoStack.length > _maxUndo ? undoStack.sublist(1) : undoStack,
      redoStack: [],
    );
  }

  void addElement(CanvasElement el) =>
      _push(state.current.copyWith(elements: [...state.current.elements, el]));

  void updateElement(CanvasElement el) => _push(state.current.copyWith(
        elements: state.current.elements.map((e) => e.id == el.id ? el : e).toList(),
      ));

  void deleteElement(String id) => _push(state.current.copyWith(
        elements: state.current.elements.where((e) => e.id != id).toList(),
      ));

  void setBackground(CanvasBackground bg) =>
      _push(state.current.copyWith(background: bg));

  void selectElement(String? id) =>
      state = state.copyWith(selectedElementId: id);

  void setZoom(double zoom) =>
      state = state.copyWith(zoomLevel: zoom.clamp(0.25, 4.0));

  void undo() {
    if (state.undoStack.isEmpty) return;
    final prev = state.undoStack.last;
    state = state.copyWith(
      current: prev,
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [state.current, ...state.redoStack],
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.first;
    state = state.copyWith(
      current: next,
      undoStack: [...state.undoStack, state.current],
      redoStack: state.redoStack.sublist(1),
    );
  }
}

class EditorNotifierState {
  const EditorNotifierState({
    required this.current,
    required this.undoStack,
    required this.redoStack,
    required this.selectedElementId,
    required this.zoomLevel,
  });

  final EditorState current;
  final List<EditorState> undoStack;
  final List<EditorState> redoStack;
  final String? selectedElementId;
  final double zoomLevel;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  CanvasElement? get selectedElement => selectedElementId == null
      ? null
      : current.elements.where((e) => e.id == selectedElementId).firstOrNull;

  factory EditorNotifierState.empty() => EditorNotifierState(
        current: EditorState(
          elements: [],
          background: CanvasBackground.defaultBg,
          canvasWidth: 390,
          canvasHeight: 844,
        ),
        undoStack: [],
        redoStack: [],
        selectedElementId: null,
        zoomLevel: 1.0,
      );

  EditorNotifierState copyWith({
    EditorState? current,
    List<EditorState>? undoStack,
    List<EditorState>? redoStack,
    String? selectedElementId,
    double? zoomLevel,
  }) {
    return EditorNotifierState(
      current: current ?? this.current,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      selectedElementId: selectedElementId ?? this.selectedElementId,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

final editorProvider =
    NotifierProvider<EditorNotifier, EditorNotifierState>(EditorNotifier.new);

// Used to share the canvas RepaintBoundary key with the Export Screen
final activeCanvasKeyProvider = Provider<GlobalKey>((ref) => GlobalKey(debugLabel: 'activeCanvas'));
