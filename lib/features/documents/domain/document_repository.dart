import 'document_entity.dart';

abstract class DocumentRepository {
  Stream<List<DocumentEntity>> watchDocuments(String companyId);
  Future<List<DocumentEntity>> getDocuments(String companyId);
  Future<DocumentEntity?> getDocumentById(String companyId, String documentId);
  Future<DocumentEntity> createDocument(String companyId, DocumentEntity document);
  Future<void> updateDocument(String companyId, DocumentEntity document);
  Future<void> deleteDocument(String companyId, String documentId);
}
