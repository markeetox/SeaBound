import 'package:cloud_firestore/cloud_firestore.dart';

import 'postcard_model.dart';
import 'postcards_flags.dart';

class PostcardsRepository {
  final FirebaseFirestore? _firestore;

  PostcardsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postcardsRef =>
      _db.collection('postcards');

  CollectionReference<Map<String, dynamic>> _userEarnedRef(String uid) =>
      _db.collection('users').doc(uid).collection('postcards');

  Stream<List<Postcard>> streamActivePostcards() {
    if (!kPostcardsEnabled) {
      return Stream.value(const []);
    }

    return _postcardsRef
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Postcard.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<EarnedPostcard>> streamUserEarnedPostcards(String uid) {
    if (!kPostcardsEnabled || uid.isEmpty) {
      return Stream.value(const []);
    }

    return _userEarnedRef(uid)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EarnedPostcard.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<bool> claimPostcard({
    required String uid,
    required Postcard postcard,
  }) async {
    if (!kPostcardsEnabled || uid.isEmpty || postcard.id.isEmpty) {
      return false;
    }

    final docRef = _userEarnedRef(uid).doc(postcard.id);

    return await _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        return false; // Already claimed, idempotent no-op
      }

      transaction.set(docRef, {
        'postcardId': postcard.id,
        'earnedAt': FieldValue.serverTimestamp(),
        'title': postcard.title,
      });

      return true;
    });
  }

  Future<void> savePostcard(Postcard postcard) async {
    if (postcard.id.isEmpty) {
      await _postcardsRef.add(postcard.toMap());
    } else {
      await _postcardsRef.doc(postcard.id).set(postcard.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deletePostcard(String postcardId) async {
    await _postcardsRef.doc(postcardId).delete();
  }
}
