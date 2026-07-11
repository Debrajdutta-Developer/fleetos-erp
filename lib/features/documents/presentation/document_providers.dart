import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../domain/document_entity.dart';
import '../domain/document_repository.dart';
import '../data/document_repository_impl.dart';

// --- Repository Provider ---
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl();
});

// --- Stream Provider for Documents ---
final documentsStreamProvider = StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(documentRepositoryProvider).watchDocuments(user!.companyId!);
});

// --- State Providers for Filtering ---
final selectedDocumentCategoryProvider = StateProvider<String>((ref) => 'all');
final selectedDocumentTypeProvider = StateProvider<String>((ref) => 'all');
final documentSearchQueryProvider = StateProvider<String>((ref) => '');

// --- Filtered Stream Provider ---
final filteredDocumentsProvider = Provider.autoDispose<List<DocumentEntity>>((ref) {
  final docsAsync = ref.watch(documentsStreamProvider);
  final category = ref.watch(selectedDocumentCategoryProvider);
  final type = ref.watch(selectedDocumentTypeProvider);
  final query = ref.watch(documentSearchQueryProvider).toLowerCase();

  final list = docsAsync.valueOrNull ?? [];

  return list.where((doc) {
    // 1. Category filter
    if (category != 'all' && doc.category != category) return false;
    
    // 2. Type filter
    if (type != 'all' && doc.type != type) return false;

    // 3. Search query
    if (query.isNotEmpty) {
      final name = doc.name.toLowerCase();
      final num = doc.documentNumber.toLowerCase();
      final entity = (doc.entityName ?? '').toLowerCase();
      return name.contains(query) || num.contains(query) || entity.contains(query);
    }

    return true;
  }).toList();
});

// --- UI State for Form and Verification ---
class DocumentFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const DocumentFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });
}

class DocumentFormController extends StateNotifier<DocumentFormState> {
  final DocumentRepository _repo;
  final Ref _ref;

  DocumentFormController({
    required DocumentRepository repo,
    required Ref ref,
  })  : _repo = repo,
        _ref = ref,
        super(const DocumentFormState());

  Future<bool> saveDocument(DocumentEntity doc) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company session context.');

      final isEdit = doc.id.isNotEmpty;
      final savedDoc = await _repo.createDocument(user!.companyId!, doc);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: user.companyId!,
        entityType: 'document',
        entityId: savedDoc.id,
        action: isEdit ? 'document_updated' : 'document_uploaded',
        description: 'Document "${savedDoc.name}" (${savedDoc.type}) ${isEdit ? "updated" : "uploaded"} by ${user.displayName ?? user.email}',
        userId: user.uid,
        userName: user.displayName ?? user.email,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyDocument(String docId, String status, String? note) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      final updatedDoc = doc.copyWith(
        status: status,
        notes: note,
        verifiedBy: user.displayName ?? user.email,
        verifiedAt: DateTime.now(),
      );

      await _repo.updateDocument(user.companyId!, updatedDoc);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: user.companyId!,
        entityType: 'document',
        entityId: docId,
        action: 'document_verified',
        description: 'Document "${doc.name}" marked as $status by ${user.displayName ?? user.email}',
        userId: user.uid,
        userName: user.displayName ?? user.email,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      await _repo.deleteDocument(user.companyId!, docId);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: user.companyId!,
        entityType: 'document',
        entityId: docId,
        action: 'document_deleted',
        description: 'Document "${doc.name}" deleted by ${user.displayName ?? user.email}',
        userId: user.uid,
        userName: user.displayName ?? user.email,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }
}

final documentFormControllerProvider =
    StateNotifierProvider.autoDispose<DocumentFormController, DocumentFormState>((ref) {
  return DocumentFormController(
    repo: ref.watch(documentRepositoryProvider),
    ref: ref,
  );
});
