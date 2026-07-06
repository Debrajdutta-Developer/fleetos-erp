/// Represents a registered Company/Tenant in the multi-tenant FleetOS ERP database.
class CompanyEntity {
  final String id;
  final String name;      // Company Name
  final String ownerName; // Owner Name
  final String? gstNumber; // GST Number (optional)
  final String logoUrl;
  final String adminUid;
  final DateTime createdAt;
  final bool isSetupComplete;

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.ownerName,
    this.gstNumber,
    this.logoUrl = '',
    required this.adminUid,
    required this.createdAt,
    this.isSetupComplete = false,
  });

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
      'adminUid': adminUid,
      'createdAt': createdAt.toIso8601String(),
      'isSetupComplete': isSetupComplete,
    };
  }

  /// Create company entity from Firestore document map
  factory CompanyEntity.fromMap(Map<String, dynamic> map) {
    return CompanyEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerName: map['ownerName'] as String? ?? '',
      gstNumber: map['gstNumber'] as String?,
      logoUrl: map['logoUrl'] as String? ?? '',
      adminUid: map['adminUid'] as String,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.now(),
      isSetupComplete: map['isSetupComplete'] as bool? ?? false,
    );
  }

  /// Implements copyWith for updates
  CompanyEntity copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? gstNumber,
    String? logoUrl,
    String? adminUid,
    DateTime? createdAt,
    bool? isSetupComplete,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      adminUid: adminUid ?? this.adminUid,
      createdAt: createdAt ?? this.createdAt,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
    );
  }
}
