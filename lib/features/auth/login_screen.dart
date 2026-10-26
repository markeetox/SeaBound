import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _cleanErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-credential':
          return 'Invalid credentials. Check your email and password.';
        default:
          return error.message ?? 'Authentication failed. (${error.code})';
      }
    }
    return error.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cleanErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Seabound'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.sailing,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Seabound',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A community app for fishermen and boaters',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address.';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log In'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            context.push('/signup');
                          },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
