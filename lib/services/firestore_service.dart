import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  // ── Templates ─────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection('templates');

  Future<Map<String, dynamic>> getTemplatesPaginated({
    String? category,
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> q = _templates;
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    
    // Fetch all templates for the category at once to allow local sorting
    // without requiring Firestore composite indexes or missing field fallbacks.
    final snap = await q.get();
    var templates = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      if (!data.containsKey('id') || (data['id'] as String? ?? '').isEmpty) {
        data['id'] = d.id;
      }
      return Template.fromMap(data);
    }).toList();
    
    // Sort templates: Newest first (based on createdAt), then fallback to ID (newest first)
    templates.sort((a, b) {
      final aTime = a.createdAt ?? 0;
      final bTime = b.createdAt ?? 0;
      if (aTime != bTime) {
        return bTime.compareTo(aTime); // Descending (newest first)
      }
      return b.id.compareTo(a.id); // Fallback: newest ID first
    });
    
    return {
      'templates': templates,
      'lastDoc': null,
      'hasMore': false, // No more pages, everything fetched
    };
  }

  Future<Template?> getTemplate(String id) async {
    final doc = await _templates.doc(id).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    if (!data.containsKey('id') || (data['id'] as String? ?? '').isEmpty) {
      data['id'] = doc.id;
    }
    return Template.fromMap(data);
  }

  /// Increments the total uses counter for a template when used in the app
  Future<void> incrementTemplateUses(String templateId) async {
    if (templateId.isEmpty) return;
    try {
      await _templates.doc(templateId).update({
        'totalUses': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently catch client network or permission error
    }
  }
}
