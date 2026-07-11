class DocumentEntity {
  final String id;
  final String companyId;
  final String name;
  final String category; // company, vehicle, driver
  final String type; // gst_certificate, pan, trade_license, company_logo, rc, insurance, fitness, puc, permit, road_tax, driving_license, national_id, other
  final String fileUrl;
  final String? entityId; // references vehicleId, driverId, or null
  final String? entityName; // references licensePlate, driverName, or null
  final String documentNumber;
  final DateTime? expiryDate;
  final String status; // pending_verification, verified, rejected, expired
  final String? notes;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DocumentEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.category,
    required this.type,
    required this.fileUrl,
    this.entityId,
    this.entityName,
    required this.documentNumber,
    this.expiryDate,
    required this.status,
    this.notes,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'category': category,
      'type': type,
      'fileUrl': fileUrl,
      'entityId': entityId,
      'entityName': entityName,
      'documentNumber': documentNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      type: map['type'] as String? ?? 'other',
      fileUrl: map['fileUrl'] as String? ?? '',
      entityId: map['entityId'] as String?,
      entityName: map['entityName'] as String?,
      documentNumber: map['documentNumber'] as String? ?? '',
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate'] as String) : null,
      status: map['status'] as String? ?? 'pending_verification',
      notes: map['notes'] as String?,
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null ? DateTime.parse(map['verifiedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
    );
  }

  DocumentEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    String? category,
    String? type,
    String? fileUrl,
    String? entityId,
    String? entityName,
    String? documentNumber,
    DateTime? expiryDate,
    String? status,
    String? notes,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearExpiry = false,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
