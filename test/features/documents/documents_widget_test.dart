import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/documents/domain/document_entity.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_list_screen.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_providers.dart';
import 'documents_providers_test.dart' show MockDocumentRepository;

void main() {
  testWidgets('DocumentListScreen renders document vault filters and tabs',
      (WidgetTester tester) async {
    final now = DateTime.now();

    final testDoc = DocumentEntity(
      id: 'doc_1',
      companyId: 'c_1',
      name: 'GST Certificate 2026',
      category: 'company',
      type: 'gst_certificate',
      fileUrl: 'https://test-storage/gst.pdf',
      documentNumber: 'GST-9988-12',
      status: 'pending_verification',
      createdAt: now,
      updatedAt: now,
    );

    final mockRepo = MockDocumentRepository();
    await mockRepo.createDocument('c_1', testDoc);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          documentRepositoryProvider.overrideWithValue(mockRepo),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: DocumentListScreen(),
        ),
      ),
    );

    // Let UI render
    await tester.pumpAndSettle();

    // Verify main screen title
    expect(find.text('Enterprise Document Vault'), findsOneWidget);

    // Verify tabs are present
    expect(find.textContaining('All Documents'), findsOneWidget);
    expect(find.textContaining('Vault Expirations'), findsOneWidget);
    expect(find.textContaining('Approval Inbox'), findsOneWidget);

    // Verify document name is listed in card
    expect(find.text('GST Certificate 2026'), findsOneWidget);

    // Verify reference number and type are printed
    expect(find.text('Reference: GST-9988-12'), findsOneWidget);
    expect(find.text('Type: GST Certificate'), findsOneWidget);

    // Verify upload button exists
    expect(find.text('Upload Document'), findsOneWidget);
  });
}
