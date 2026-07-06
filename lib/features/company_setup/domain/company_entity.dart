/// Represents a registered Company/Tenant in the multi-tenant FleetOS ERP database.
class CompanyEntity {
  final String id;
  final String name;
  final String logoUrl;
  final String industry;
  final String fleetSize;
  final String adminUid;
  final DateTime createdAt;
  final bool isSetupComplete;

  const CompanyEntity({
    required this.id,
    required this.name,
    this.logoUrl = '',
    required this.industry,
    required this.fleetSize,
    required this.adminUid,
    required this.createdAt,
    this.isSetupComplete = false,
  });

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'industry': industry,
      'fleetSize': fleetSize,
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
      logoUrl: map['logoUrl'] as String? ?? '',
      industry: map['industry'] as String,
      fleetSize: map['fleetSize'] as String,
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
    String? logoUrl,
    String? industry,
    String? fleetSize,
    String? adminUid,
    DateTime? createdAt,
    bool? isSetupComplete,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      industry: industry ?? this.industry,
      fleetSize: fleetSize ?? this.fleetSize,
      adminUid: adminUid ?? this.adminUid,
      createdAt: createdAt ?? this.createdAt,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
    );
  }
}
