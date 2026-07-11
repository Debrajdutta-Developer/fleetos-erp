import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'document_providers.dart';
import '../domain/document_entity.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      ref.read(documentSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getFriendlyTypeName(String type) {
    switch (type) {
      case 'gst_certificate': return 'GST Certificate';
      case 'pan': return 'PAN Card';
      case 'trade_license': return 'Trade License';
      case 'company_logo': return 'Company Logo';
      case 'rc': return 'Registration Certificate (RC)';
      case 'insurance': return 'Insurance Policy';
      case 'fitness': return 'Fitness Certificate';
      case 'puc': return 'Pollution Certificate (PUC)';
      case 'permit': return 'National/State Permit';
      case 'road_tax': return 'Road Tax receipt';
      case 'driving_license': return 'Driving License (DL)';
      case 'national_id': return 'Aadhaar / National ID';
      default: return 'Other Document';
    }
  }

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'pending_verification': return Colors.orange;
      case 'rejected': return scheme.error;
      case 'expired': return Colors.red.shade800;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allDocs = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    final filteredDocs = ref.watch(filteredDocumentsProvider);
    final selectedCategory = ref.watch(selectedDocumentCategoryProvider);
    final selectedType = ref.watch(selectedDocumentTypeProvider);

    // Compute expiry alerts (expired, or expiring within 30 days)
    final now = DateTime.now();
    final expiryAlerts = allDocs.where((doc) {
      if (doc.expiryDate == null) return false;
      return doc.status == 'expired' || doc.expiryDate!.difference(now).inDays <= 30;
    }).toList();

    // Compute pending verification
    final pendingDocs = allDocs.where((doc) => doc.status == 'pending_verification').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Document Vault'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined),
              text: 'All Documents (${allDocs.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning_amber_rounded),
              text: 'Vault Expirations (${expiryAlerts.length})',
            ),
            Tab(
              icon: const Icon(Icons.verified_user_outlined),
              text: 'Approval Inbox (${pendingDocs.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. All Documents Tab
          _buildAllDocumentsTab(context, filteredDocs, selectedCategory, selectedType, colorScheme, theme),
          // 2. Expirations Tab
          _buildExpirationsTab(context, expiryAlerts, colorScheme, theme),
          // 3. Approval Inbox Tab
          _buildApprovalInboxTab(context, pendingDocs, colorScheme, theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload Document'),
        onPressed: () => context.push('/documents/new'),
      ),
    );
  }

  // --- ALL DOCUMENTS TAB ---
  Widget _buildAllDocumentsTab(
    BuildContext context,
    List<DocumentEntity> list,
    String category,
    String type,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Filter toolbar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by document name, number, or license plate...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  DropdownMenuItem(value: 'company', child: Text('Company Docs')),
                  DropdownMenuItem(value: 'vehicle', child: Text('Vehicle Docs')),
                  DropdownMenuItem(value: 'driver', child: Text('Driver Docs')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedDocumentCategoryProvider.notifier).state = val;
                    ref.read(selectedDocumentTypeProvider.notifier).state = 'all'; // reset type filter
                  }
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: type,
                items: _getTypeDropdownItems(category),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedDocumentTypeProvider.notifier).state = val;
                  }
                },
              ),
            ],
          ),
        ),

        // Grid list
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No vault documents found matching selection.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 220,
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, idx) {
                    final doc = list[idx];
                    return _buildDocumentCard(context, doc, colorScheme, theme);
                  },
                ),
        ),
      ],
    );
  }

  // --- EXSPIRATIONS TAB ---
  Widget _buildExpirationsTab(
    BuildContext context,
    List<DocumentEntity> list,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Vault verified. Zero document expiration alerts!'),
          ],
        ),
      );
    }

    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, idx) {
        final doc = list[idx];
        final days = doc.expiryDate != null ? doc.expiryDate!.difference(now).inDays : 0;
        final isExpired = days < 0;

        return ListTile(
          leading: Icon(
            isExpired ? Icons.cancel : Icons.warning_amber_rounded,
            color: isExpired ? Colors.red.shade800 : Colors.orange,
            size: 32,
          ),
          title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_getFriendlyTypeName(doc.type)} | Attached to: ${doc.entityName ?? "Company"}'),
              Text(
                isExpired ? 'EXPIRED' : 'Expiring in $days days (${DateFormat('yMMMd').format(doc.expiryDate!)})',
                style: TextStyle(
                  color: isExpired ? Colors.red.shade800 : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: OutlinedButton(
            onPressed: () => context.push('/documents/${doc.id}'),
            child: const Text('Resolve'),
          ),
        );
      },
    );
  }

  // --- APPROVAL INBOX TAB ---
  Widget _buildApprovalInboxTab(
    BuildContext context,
    List<DocumentEntity> list,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Inbox empty. No documents pending compliance verification.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, idx) {
        final doc = list[idx];

        return ListTile(
          leading: const Icon(Icons.rate_review_outlined, color: Colors.orange, size: 32),
          title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Type: ${_getFriendlyTypeName(doc.type)} | Attached to: ${doc.entityName ?? "Company"} | No: ${doc.documentNumber}',
          ),
          trailing: ElevatedButton(
            onPressed: () => context.push('/documents/${doc.id}'),
            child: const Text('Review'),
          ),
        );
      },
    );
  }

  // --- INDIVIDUAL CARD BUILDING ---
  Widget _buildDocumentCard(
    BuildContext context,
    DocumentEntity doc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(doc.status, colorScheme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/documents/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Top: Icon and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getCategoryIcon(doc.category),
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      doc.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Card Title & Subtitle
              Text(
                doc.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${_getFriendlyTypeName(doc.type)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
              Text(
                'Reference: ${doc.documentNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
              const Spacer(),

              const Divider(),
              // Card Bottom: Entity Mapping and Expiry Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc.entityName ?? 'Company Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    doc.expiryDate == null
                        ? 'No Expiration'
                        : 'Expires: ${DateFormat('MM/dd/yy').format(doc.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now())
                          ? Colors.red.shade800
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now())
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'company': return Icons.business_rounded;
      case 'vehicle': return Icons.local_shipping_rounded;
      case 'driver': return Icons.badge_rounded;
      default: return Icons.article_rounded;
    }
  }

  List<DropdownMenuItem<String>> _getTypeDropdownItems(String category) {
    final list = [
      const DropdownMenuItem(value: 'all', child: Text('All Types')),
    ];

    if (category == 'all' || category == 'company') {
      list.addAll([
        const DropdownMenuItem(value: 'gst_certificate', child: Text('GST Certificate')),
        const DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
        const DropdownMenuItem(value: 'trade_license', child: Text('Trade License')),
        const DropdownMenuItem(value: 'company_logo', child: Text('Company Logo')),
      ]);
    }
    if (category == 'all' || category == 'vehicle') {
      list.addAll([
        const DropdownMenuItem(value: 'rc', child: Text('Registration (RC)')),
        const DropdownMenuItem(value: 'insurance', child: Text('Insurance Policy')),
        const DropdownMenuItem(value: 'fitness', child: Text('Fitness Certificate')),
        const DropdownMenuItem(value: 'puc', child: Text('Pollution Certificate')),
        const DropdownMenuItem(value: 'permit', child: Text('State Permit')),
        const DropdownMenuItem(value: 'road_tax', child: Text('Road Tax Receipt')),
      ]);
    }
    if (category == 'all' || category == 'driver') {
      list.addAll([
        const DropdownMenuItem(value: 'driving_license', child: Text('Driving License (DL)')),
        const DropdownMenuItem(value: 'national_id', child: Text('Aadhaar / National ID')),
      ]);
    }

    return list;
  }
}
