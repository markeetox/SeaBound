import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'postcard_model.dart';
import 'postcards_flags.dart';
import 'postcards_providers.dart';
import 'postcards_repository.dart';
import 'zone_matcher.dart';

class PostcardDetectionService {
  final PostcardsRepository _repository;
  final StreamController<Postcard> _newlyEarnedController =
      StreamController<Postcard>.broadcast();

  Stream<Postcard> get onNewlyEarned => _newlyEarnedController.stream;

  DateTime? _lastEvaluationTime;
  Position? _lastEvaluatedPosition;
  bool _isEvaluating = false;

  PostcardDetectionService({
    required PostcardsRepository repository,
  }) : _repository = repository;

  Future<void> evaluatePosition({
    required Position position,
    required String uid,
    required List<Postcard> activePostcards,
    required Set<String> earnedPostcardIds,
  }) async {
    if (!kPostcardsEnabled || uid.isEmpty || activePostcards.isEmpty) {
      return;
    }

    // 1. Accuracy check: ignore poor GPS accuracy (> 65 meters)
    if (position.accuracy > 65.0) {
      return;
    }

    // 2. Mock location check: ignore simulated mock fixes on platforms where available
    if (position.isMocked) {
      return;
    }

    // 3. Throttling: evaluate at most once every 3 seconds or on meaningful movement (> 15m)
    final now = DateTime.now();
    if (_lastEvaluationTime != null && _lastEvaluatedPosition != null) {
      final elapsed = now.difference(_lastEvaluationTime!);
      final distance = ZoneMatcher.haversineDistanceMeters(
        position.latitude,
        position.longitude,
        _lastEvaluatedPosition!.latitude,
        _lastEvaluatedPosition!.longitude,
      );

      if (elapsed < const Duration(seconds: 3) && distance < 15.0) {
        return;
      }
    }

    if (_isEvaluating) return;
    _isEvaluating = true;

    try {
      _lastEvaluationTime = now;
      _lastEvaluatedPosition = position;

      // 4. Candidate filtering: skip already earned postcards
      final unearnedCandidates = activePostcards
          .where((card) => !earnedPostcardIds.contains(card.id))
          .toList();

      if (unearnedCandidates.isEmpty) return;

      // 5. Zone matching
      final matches = ZoneMatcher.matchPostcards(
        userLat: position.latitude,
        userLng: position.longitude,
        activePostcards: unearnedCandidates,
      );

      // 6. Claim hit postcards (offline safe: Firestore offline queue queues sets)
      for (final postcard in matches) {
        final claimed = await _repository.claimPostcard(
          uid: uid,
          postcard: postcard,
        );

        if (claimed) {
          earnedPostcardIds.add(postcard.id);
          _newlyEarnedController.add(postcard);
          debugPrint('[PostcardDetection] Unlocked postcard: ${postcard.title}');
        }
      }
    } catch (e) {
      debugPrint('[PostcardDetection] Evaluation error: $e');
    } finally {
      _isEvaluating = false;
    }
  }

  void dispose() {
    _newlyEarnedController.close();
  }
}

final postcardDetectionServiceProvider = Provider<PostcardDetectionService>((ref) {
  final repo = ref.watch(postcardsRepositoryProvider);
  final service = PostcardDetectionService(repository: repo);
  ref.onDispose(service.dispose);
  return service;
});

final newlyEarnedPostcardStreamProvider = StreamProvider<Postcard>((ref) {
  if (!kPostcardsEnabled) {
    return const Stream.empty();
  }
  final service = ref.watch(postcardDetectionServiceProvider);
  return service.onNewlyEarned;
});
