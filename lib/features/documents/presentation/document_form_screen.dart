import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../domain/document_entity.dart';
import 'document_providers.dart';

class DocumentFormScreen extends ConsumerStatefulWidget {
  final String? documentId;

  const DocumentFormScreen({super.key, this.documentId});

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _notesController;

  String _category = 'company';
  String _type = 'gst_certificate';
  String? _selectedEntityId;
  String? _selectedEntityName;
  
  bool _hasExpiry = true;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  
  bool _initialized = false;

  // Attachment mock state
  bool _fileAttached = false;
  String _fileName = '';
  String _fileSize = '';
  String _mockUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeValues(List<DocumentEntity> list) {
    if (_initialized) return;
    if (widget.documentId != null) {
      final doc = list.firstWhere((d) => d.id == widget.documentId);
      _nameController.text = doc.name;
      _numberController.text = doc.documentNumber;
      _notesController.text = doc.notes ?? '';
      _category = doc.category;
      _type = doc.type;
      _selectedEntityId = doc.entityId;
      _selectedEntityName = doc.entityName;
      _mockUrl = doc.fileUrl;
      _fileAttached = doc.fileUrl.isNotEmpty;
      if (_fileAttached) {
        _fileName = doc.name.toLowerCase().replaceAll(' ', '_') + '.pdf';
        _fileSize = '1.8 MB';
      }
      if (doc.expiryDate != null) {
        _hasExpiry = true;
        _expiryDate = doc.expiryDate!;
      } else {
        _hasExpiry = false;
      }
    }
    _initialized = true;
  }

  void _simulateFileSelection() {
    setState(() {
      _fileAttached = true;
      final typeLabel = _type.replaceAll('_', '');
      _fileName = 'uploaded_${typeLabel}_${math.Random().nextInt(999)}.pdf';
      _fileSize = '${(math.Random().nextDouble() * 3 + 0.5).toStringAsFixed(1)} MB';
      _mockUrl = 'https://firebasestorage.googleapis.com/v0/b/fleetos-erp/o/documents%2F${_fileName}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_fileAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or attach a document file.')),
      );
      return;
    }

    final doc = DocumentEntity(
      id: widget.documentId ?? '',
      companyId: '', // Filled in controller
      name: _nameController.text.trim(),
      category: _category,
      type: _type,
      fileUrl: _mockUrl,
      entityId: _category == 'company' ? null : _selectedEntityId,
      entityName: _category == 'company' ? null : _selectedEntityName,
      documentNumber: _numberController.text.trim(),
      expiryDate: _hasExpiry ? _expiryDate : null,
      status: widget.documentId != null ? 'pending_verification' : 'pending_verification',
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .saveDocument(doc);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formState = ref.watch(documentFormControllerProvider);
    final documents = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversStreamProvider).valueOrNull ?? [];

    if (widget.documentId != null && documents.isNotEmpty) {
      _initializeValues(documents);
    }

    final isEditMode = widget.documentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modify Document Details' : 'Upload Vault Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditMode ? 'Modify metadata parameters' : 'Attach enterprise compliance documents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Category Selector
                  Text('Document Category', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'company', child: Text('Company Level Document')),
                      DropdownMenuItem(value: 'vehicle', child: Text('Vehicle Compliance Document')),
                      DropdownMenuItem(value: 'driver', child: Text('Driver Licensing / National ID')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _category = val;
                          _selectedEntityId = null;
                          _selectedEntityName = null;
                          // Set default type
                          if (val == 'company') _type = 'gst_certificate';
                          if (val == 'vehicle') _type = 'rc';
                          if (val == 'driver') _type = 'driving_license';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Type Selector
                  Text('Document Type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _getTypeOptions(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _type = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Dynamic Entity Selection (if Vehicle or Driver)
                  if (_category == 'vehicle') ...[
                    Text('Associated Vehicle', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEntityId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select Vehicle'),
                      items: vehicles.map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.licensePlate} (${v.make} ${v.model})'),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final vObj = vehicles.firstWhere((veh) => veh.id == val);
                          setState(() {
                            _selectedEntityId = val;
                            _selectedEntityName = vObj.licensePlate;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Please select a vehicle' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_category == 'driver') ...[
                    Text('Associated Driver', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEntityId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select Driver'),
                      items: drivers.map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.fullName),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final dObj = drivers.firstWhere((drv) => drv.id == val);
                          setState(() {
                            _selectedEntityId = val;
                            _selectedEntityName = dObj.fullName;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Please select a driver' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. Basic Metadata Form
                  Text('Document Name', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. GST Certificate 2026, Volvo RC',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Document name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  Text('Document Reference Number', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. GSTIN, DL Number, Policy #',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Reference number is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // 5. Expiration tracking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tracks Expiration Date', style: theme.textTheme.titleSmall),
                      Switch(
                        value: _hasExpiry,
                        onChanged: (val) => setState(() => _hasExpiry = val),
                      ),
                    ],
                  ),
                  if (_hasExpiry) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Expiry Date: ${DateFormat('yMMMd').format(_expiryDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setState(() {
                            _expiryDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Notes
                  Text('Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add audit notes, compliance alerts or reference items...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Attachment Panel
                  Text('File Attachment', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (_fileAttached) ...[
                            Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: colorScheme.primary, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _fileName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_fileSize),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => setState(() {
                                    _fileAttached = false;
                                    _fileName = '';
                                    _fileSize = '';
                                    _mockUrl = '';
                                  }),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Icon(Icons.upload_file, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('No file attached. Max limit 10MB.'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Simulate File Upload (PDF/JPG)'),
                              onPressed: _simulateFileSelection,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 7. Submit Action
                  if (formState.errorMessage != null) ...[
                    Text(
                      formState.errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: formState.isLoading ? null : _submit,
                    child: formState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditMode ? 'Update Document' : 'Verify & Upload to Vault'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getTypeOptions() {
    if (_category == 'company') {
      return const [
        DropdownMenuItem(value: 'gst_certificate', child: Text('GST Certificate')),
        DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
        DropdownMenuItem(value: 'trade_license', child: Text('Trade License')),
        DropdownMenuItem(value: 'company_logo', child: Text('Company Logo')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else if (_category == 'vehicle') {
      return const [
        DropdownMenuItem(value: 'rc', child: Text('Registration Certificate (RC)')),
        DropdownMenuItem(value: 'insurance', child: Text('Insurance Policy')),
        DropdownMenuItem(value: 'fitness', child: Text('Fitness Certificate')),
        DropdownMenuItem(value: 'puc', child: Text('Pollution Certificate (PUC)')),
        DropdownMenuItem(value: 'permit', child: Text('Permit')),
        DropdownMenuItem(value: 'road_tax', child: Text('Road Tax Receipt')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else {
      return const [
        DropdownMenuItem(value: 'driving_license', child: Text('Driving License (DL)')),
        DropdownMenuItem(value: 'national_id', child: Text('Aadhaar / National ID')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    }
  }
}
