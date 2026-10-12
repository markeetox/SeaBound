import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'badge_service.dart';
import 'catalog.dart';
import 'profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String _selectedAvatarId = 'avatar_01';
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _populateData(Map<String, dynamic>? userDoc, String? authDisplayName) {
    if (_isLoaded) return;
    final currentUsername = userDoc?['username'] as String? ?? authDisplayName ?? '';
    _usernameController.text = currentUsername;
    final currentAvatar = userDoc?['avatarId'] as String?;
    if (currentAvatar != null && currentAvatar.isNotEmpty) {
      _selectedAvatarId = currentAvatar;
    }
    _isLoaded = true;
  }

  Future<void> _saveProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(
        uid: uid,
        username: _usernameController.text.trim(),
        avatarId: _selectedAvatarId,
      );

      if (mounted) {
        final badgeService = ref.read(badgeServiceProvider);
        final result = await badgeService.onProfileUpdated();
        if (mounted) {
          showBadgeUnlocks(context, result);
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userDocState = ref.watch(userDocStreamProvider);

    final currentUser = authState.asData?.value;
    final userDoc = userDocState.asData?.value;

    if (currentUser == null) {
      return GradientBackground.red(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('User not authenticated.')),
        ),
      );
    }

    _populateData(userDoc, currentUser.displayName);

    final avatarIds = List.generate(
      16,
      (i) => 'avatar_${(i + 1).toString().padLeft(2, '0')}',
    );

    return GradientBackground.red(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 88, left: 24, right: 24, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Edit Profile',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            hintText: 'e.g. Captain_Jack',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) => Catalog.validateUsername(value),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Choose Avatar Preset',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: avatarIds.length,
                          itemBuilder: (context, index) {
                            final avatarId = avatarIds[index];
                            final isSelected = avatarId == _selectedAvatarId;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAvatarId = avatarId;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? OceanThemeExtension.defaultTokens.cyan
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/avatars/$avatarId.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        'A${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isSaving ? null : () => _saveProfile(currentUser.uid),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(isRedScreen: true),
            ),
          ],
        ),
      ),
    );
  }
}
