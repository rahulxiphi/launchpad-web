import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../router/app_router.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showInviteField = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authNotifierProvider.notifier).clearError();
      final routeExtra = GoRouterState.of(context).extra;
      final extraMap = routeExtra is Map ? routeExtra.cast<String, dynamic>() : null;

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          invitationCode: _inviteCodeController.text.trim().isEmpty
              ? null
              : _inviteCodeController.text.trim(),
        stageBucket: extraMap?['stageBucket'] as String?,
        );

    // GoRouter redirect handles navigation on success (auth state change → /)
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final routeExtra = GoRouterState.of(context).extra;
    final extraMap = routeExtra is Map ? routeExtra.cast<String, dynamic>() : null;
    final stageBucket = extraMap?['stageBucket'] as String?;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: 28,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Create your account',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start your financial advisory journey — free for startups.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    if (stageBucket != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Signing up for the ${stageBucket.replaceAll('_', '-')} stage.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Error banner
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Work email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required.';
                        }
                        if (!v.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required.';
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      textInputAction:
                          _showInviteField ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: _showInviteField ? null : (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Invitation code toggle
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showInviteField = !_showInviteField),
                      child: Row(
                        children: [
                          Icon(
                            _showInviteField
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Have an invitation code?',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showInviteField) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _inviteCodeController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Invitation code (optional)',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Create account button
                    FilledButton(
                      onPressed: authState.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 20),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login, extra: routeExtra),
                          child: Text(
                            'Sign in',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Terms note
                    Text(
                      'By creating an account you agree to our Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
