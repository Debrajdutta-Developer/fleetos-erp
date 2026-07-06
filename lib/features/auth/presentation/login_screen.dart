import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'auth_providers.dart';

/// Form login and registration screen utilizing Clean Architecture components.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Only for registration

  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await authController.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    } else {
      success = await authController.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (success && mounted) {
      final user = ref.read(currentUserProvider);
      if (user?.companyId == null || user!.companyId!.isEmpty) {
        context.go('/company-setup');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);

    // Responsive helper layout widths
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 768;

    return Scaffold(
      body: Row(
        children: [
          // Desktop branding sidebar banner
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                color: colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'FleetOS ERP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The unified command center for fleet logistics, multi-tenant inventory, routing metrics, and enterprise billing infrastructure.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Secured with AES 256-bit standards',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main Login Content Form
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small Mobile Logo Placeholder
                        if (!isDesktop) ...[
                          Row(
                            children: [
                              Icon(Icons.local_shipping_rounded, color: colorScheme.primary, size: 32),
                              const SizedBox(width: 8),
                              Text(
                                'FleetOS',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],

                        Text(
                          _isSignUp ? 'Create Corporate Account' : 'Welcome Operator',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp 
                              ? 'Get started with FleetOS ERP' 
                              : 'Log in to access your dashboard and fleet diagnostics.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Banner message box
                        if (authState.errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.error.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: TextStyle(color: colorScheme.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (_isSignUp) ...[
                          CustomTextField(
                            controller: _nameController,
                            labelText: 'Full Name',
                            hintText: 'John Doe',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'operator@fleetos.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Email is required';
                            final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailReg.hasMatch(val)) return 'Invalid email format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password is required';
                            if (val.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Submit Button
                        CustomButton(
                          text: _isSignUp ? 'REGISTER COMPANY ADMIN' : 'INITIALIZE HANDSHAKE',
                          isLoading: authState.isLoading,
                          onPressed: _submitForm,
                        ),
                        const SizedBox(height: 24),

                        // Auth Toggle Action link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isSignUp 
                                  ? 'Already registered? Authenticate here' 
                                  : 'New organization? Register admin account',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
