import 'dart:io';
import 'company_entity.dart';

/// Contract definition for Company/Tenant configuration in Clean Architecture.
abstract class CompanyRepository {
  /// Create new company registry record.
  /// Throws [ServerFailure] on failure.
  Future<CompanyEntity> createCompany({
    required String name,
    required String industry,
    required String fleetSize,
    required String adminUid,
    File? logoFile,
  });

  /// Retrieve company details.
  Future<CompanyEntity?> getCompany(String companyId);

  /// Optional: Upload logo image to storage bucket and fetch URL.
  Future<String> uploadLogo(String companyId, File logoFile);
}
