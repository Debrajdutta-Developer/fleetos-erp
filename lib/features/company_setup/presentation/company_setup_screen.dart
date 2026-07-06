import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'company_providers.dart';

/// Onboarding screen allowing registered corporate admins to setup their tenants/companies.
class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();       // Company Name
  final _ownerNameController = TextEditingController();  // Owner Name
  final _gstNumberController = TextEditingController();  // GST Number (optional)

  File? _logoFile;
  bool _mockLogoSelected = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickMockLogo() async {
    setState(() {
      _mockLogoSelected = true;
      _logoFile = null; 
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock company logo profile selected successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final setupController = ref.read(companySetupControllerProvider.notifier);

    final success = await setupController.registerCompany(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      gstNumber: _gstNumberController.text.trim().isEmpty 
          ? null 
          : _gstNumberController.text.trim().toUpperCase(),
      logoFile: _logoFile,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(companySetupControllerProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Tenant Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
              ),
              elevation: isDesktop ? 2 : 0,
              color: isDesktop ? theme.cardTheme.color : Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 36.0 : 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Initialize Company Space',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a dedicated partition for your company, designate owners, configure tax mappings, and onboard logistics operators.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error message container
                      if (state.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.error.withOpacity(0.2)),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(color: colorScheme.error, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Logo picker section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickMockLogo,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: colorScheme.primary.withOpacity(0.08),
                                backgroundImage: _mockLogoSelected
                                    ? const NetworkImage('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200')
                                    : null,
                                child: !_mockLogoSelected
                                    ? Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Company Brand Logo',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Supports PNG, JPG (Max 5MB)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onBackground.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form input fields
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Company Legal Name',
                        hintText: 'Globex Logistics Corp',
                        prefixIcon: Icons.business_outlined,
                        validator: (val) => val == null || val.isEmpty ? 'Company name is required' : null,
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _ownerNameController,
                        labelText: 'Owner / Legal Representative Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) => val == null || val.isEmpty ? 'Owner name is required' : null,
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _gstNumberController,
                        labelText: 'GSTIN Number (Optional)',
                        hintText: '29GGGGG1314R9Z6',
                        prefixIcon: Icons.receipt_long_outlined,
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            if (val.length != 15) {
                              return 'GST number must be exactly 15 characters';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      CustomButton(
                        text: 'CREATE TENANT PARTITION',
                        isLoading: state.isLoading,
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
