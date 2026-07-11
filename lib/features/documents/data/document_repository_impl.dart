import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/document_entity.dart';
import '../domain/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  DocumentRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<DocumentEntity>> watchDocuments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('documents')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DocumentEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<DocumentEntity>> getDocuments(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('documents')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DocumentEntity?> getDocumentById(String companyId, String documentId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('documents')
          .doc(documentId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return DocumentEntity.fromMap(data);
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DocumentEntity> createDocument(String companyId, DocumentEntity document) async {
    try {
      final id = document.id.isEmpty ? _uuid.v4() : document.id;
      final newDoc = document.copyWith(
        id: id,
        companyId: companyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('documents')
          .doc(id)
          .set(newDoc.toMap());

      return newDoc;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDocument(String companyId, DocumentEntity document) async {
    try {
      final updatedDoc = document.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('documents')
          .doc(document.id)
          .set(updatedDoc.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteDocument(String companyId, String documentId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('documents')
          .doc(documentId)
          .update({'deletedAt': DateTime.now().toIso8601String()});
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
