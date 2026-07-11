import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/document_entity.dart';
import 'document_providers.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
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

  Future<void> _handleVerification(String status) async {
    final note = _noteController.text.trim();
    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .verifyDocument(widget.documentId, status, note.isNotEmpty ? note : null);

    if (success && mounted) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document successfully marked as ${status.replaceAll('_', ' ')}.')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Document'),
        content: const Text('Are you sure you want to permanently delete this document from the vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(documentFormControllerProvider.notifier)
          .deleteDocument(widget.documentId);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final documents = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    
    // Find the current document
    final docList = documents.where((d) => d.id == widget.documentId).toList();
    if (docList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Vault Detail')),
        body: const Center(child: Text('Document record not found or has been deleted.')),
      );
    }

    final doc = docList.first;
    final statusColor = _getStatusColor(doc.status, colorScheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details & Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: File Visual preview inspector
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Inspector container
                  Container(
                    height: 520,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 80,
                            color: colorScheme.primary.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            doc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Size: 2.1 MB | Format: PDF Document',
                            style: TextStyle(color: colorScheme.onBackground.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, py: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Visual Attachment Inspector View',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Metadata, Audits, Verification controls
          Container(
            width: 380,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
              color: colorScheme.surfaceVariant.withOpacity(0.15),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Block
                  Text(
                    doc.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                  const Divider(height: 32),

                  // Metadata properties
                  _buildProperty(context, 'Category', doc.category.toUpperCase()),
                  _buildProperty(context, 'Document Type', _getFriendlyTypeName(doc.type)),
                  _buildProperty(context, 'Reference ID / Number', doc.documentNumber),
                  _buildProperty(context, 'Mapping Scope', doc.entityName ?? 'Company Level'),
                  _buildProperty(
                    context,
                    'Expiry Date',
                    doc.expiryDate != null ? DateFormat('yMMMMd').format(doc.expiryDate!) : 'No expiration',
                  ),
                  if (doc.notes != null && doc.notes!.isNotEmpty)
                    _buildProperty(context, 'Notes', doc.notes!),

                  const Divider(height: 32),

                  // Verification Controls (if pending or in other states)
                  Text(
                    'COMPLIANCE MANAGEMENT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Verification note / reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject'),
                          onPressed: () => _handleVerification('rejected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                          onPressed: () => _handleVerification('verified'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Audit Trail Timeline
                  Text(
                    'AUDIT TIMELINE LOGS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineItem(
                    title: 'Verification Status Updated',
                    subtitle: doc.status == 'pending_verification'
                        ? 'Pending manager review.'
                        : 'Marked ${doc.status.toUpperCase()} by ${doc.verifiedBy ?? "system"}.',
                    time: doc.verifiedAt != null ? DateFormat('MM/dd/yy HH:mm').format(doc.verifiedAt!) : 'N/A',
                    color: statusColor,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: 'Document Uploaded & Saved',
                    subtitle: 'Metadata registered in Firestore vault.',
                    time: DateFormat('MM/dd/yy HH:mm').format(doc.createdAt),
                    color: colorScheme.primary,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProperty(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
