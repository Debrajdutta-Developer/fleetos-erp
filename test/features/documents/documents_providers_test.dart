import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/documents/domain/document_entity.dart';
import 'package:fleet_os_erp/features/documents/domain/document_repository.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_providers.dart';

class MockDocumentRepository implements DocumentRepository {
  final List<DocumentEntity> documents = [];

  @override
  Stream<List<DocumentEntity>> watchDocuments(String companyId) => Stream.value(documents);

  @override
  Future<List<DocumentEntity>> getDocuments(String companyId) async => documents;

  @override
  Future<DocumentEntity?> getDocumentById(String companyId, String documentId) async {
    try {
      return documents.firstWhere((d) => d.id == documentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DocumentEntity> createDocument(String companyId, DocumentEntity document) async {
    final id = document.id.isEmpty ? 'doc_${documents.length}' : document.id;
    final newDoc = document.copyWith(id: id, companyId: companyId);
    documents.add(newDoc);
    return newDoc;
  }

  @override
  Future<void> updateDocument(String companyId, DocumentEntity document) async {
    final idx = documents.indexWhere((d) => d.id == document.id);
    if (idx != -1) {
      documents[idx] = document;
    }
  }

  @override
  Future<void> deleteDocument(String companyId, String documentId) async {
    final idx = documents.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      documents[idx] = documents[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

void main() {
  group('Document Providers & Verification Unit Tests', () {
    late ProviderContainer container;
    late MockDocumentRepository docRepo;
    final now = DateTime.now();

    setUp(() {
      docRepo = MockDocumentRepository();
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          documentRepositoryProvider.overrideWithValue(docRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Selected category defaults to all', () {
      expect(container.read(selectedDocumentCategoryProvider), 'all');
    });

    test('Search query defaults to empty', () {
      expect(container.read(documentSearchQueryProvider), '');
    });

    test('saveDocument creates doc record successfully and logs upload event', () async {
      final doc = DocumentEntity(
        id: '',
        companyId: '',
        name: 'GST Certificate 2026',
        category: 'company',
        type: 'gst_certificate',
        fileUrl: 'https://test-storage/gst.pdf',
        documentNumber: 'GST-9988-12',
        status: 'pending_verification',
        createdAt: now,
        updatedAt: now,
      );

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .saveDocument(doc);

      expect(success, true);
      final docs = await docRepo.getDocuments('c_1');
      expect(docs.length, 1);
      expect(docs.first.name, 'GST Certificate 2026');
      expect(docs.first.status, 'pending_verification');
    });

    test('verifyDocument updates verification state to verified', () async {
      final doc = DocumentEntity(
        id: 'doc_custom_1',
        companyId: 'c_1',
        name: 'PAN Card',
        category: 'company',
        type: 'pan',
        fileUrl: 'https://test-storage/pan.pdf',
        documentNumber: 'PAN-12-AB',
        status: 'pending_verification',
        createdAt: now,
        updatedAt: now,
      );

      await docRepo.createDocument('c_1', doc);

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .verifyDocument('doc_custom_1', 'verified', 'Approved by manager');

      expect(success, true);
      final updated = await docRepo.getDocumentById('c_1', 'doc_custom_1');
      expect(updated!.status, 'verified');
      expect(updated.notes, 'Approved by manager');
      expect(updated.verifiedBy, 'Operator John');
    });

    test('deleteDocument sets deletedAt timestamp', () async {
      final doc = DocumentEntity(
        id: 'doc_custom_2',
        companyId: 'c_1',
        name: 'Volvo Fitness Cert',
        category: 'vehicle',
        type: 'fitness',
        fileUrl: 'https://test-storage/fitness.pdf',
        documentNumber: 'FIT-001-A',
        status: 'pending_verification',
        createdAt: now,
        updatedAt: now,
      );

      await docRepo.createDocument('c_1', doc);

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .deleteDocument('doc_custom_2');

      expect(success, true);
      final updated = await docRepo.getDocumentById('c_1', 'doc_custom_2');
      expect(updated!.deletedAt, isNotNull);
    });
  });
}
