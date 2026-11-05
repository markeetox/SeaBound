import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'postcard_model.dart';
import 'postcards_flags.dart';
import 'postcards_repository.dart';

final postcardsRepositoryProvider = Provider<PostcardsRepository>((ref) {
  return PostcardsRepository();
});

final activePostcardsStreamProvider = StreamProvider<List<Postcard>>((ref) {
  if (!kPostcardsEnabled) {
    return Stream.value(const []);
  }
  final repo = ref.watch(postcardsRepositoryProvider);
  return repo.streamActivePostcards();
});

final userEarnedPostcardsStreamProvider =
    StreamProvider<List<EarnedPostcard>>((ref) {
  if (!kPostcardsEnabled) {
    return Stream.value(const []);
  }
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(postcardsRepositoryProvider);
  return repo.streamUserEarnedPostcards(authUser.uid);
});
