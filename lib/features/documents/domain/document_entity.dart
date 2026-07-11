class DocumentEntity {
  final String id;
  final String companyId;
  final String? relatedEntityId;
  final String?
      relatedEntityType; // vehicle, driver, customer, contract, company, etc.
  final String category; // company, vehicle, driver, customer, finance
  final String fileName;
  final String originalFileName;
  final int fileSize; // in bytes
  final String mimeType;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadDate;
  final DateTime? expiryDate;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String status; // pending_verification, verified, rejected, expired
  final String? notes;

  const DocumentEntity({
    required this.id,
    required this.companyId,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.category,
    required this.fileName,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadDate,
    this.expiryDate,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'category': category,
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadDate': uploadDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      relatedEntityId: map['relatedEntityId'] as String?,
      relatedEntityType: map['relatedEntityType'] as String?,
      category: map['category'] as String? ?? 'company',
      fileName: map['fileName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      fileSize: map['fileSize'] as int? ?? 0,
      mimeType: map['mimeType'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      uploadDate: map['uploadDate'] != null
          ? DateTime.parse(map['uploadDate'] as String)
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      status: map['status'] as String? ?? 'pending_verification',
      notes: map['notes'] as String?,
    );
  }

  DocumentEntity copyWith({
    String? id,
    String? companyId,
    String? relatedEntityId,
    String? relatedEntityType,
    String? category,
    String? fileName,
    String? originalFileName,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    String? downloadUrl,
    DateTime? uploadDate,
    DateTime? expiryDate,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? status,
    String? notes,
    bool clearExpiry = false,
    bool clearDeleted = false,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadDate: uploadDate ?? this.uploadDate,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
