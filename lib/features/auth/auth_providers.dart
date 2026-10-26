import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value(null);
  }
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserProfileStream(user.uid);
});
