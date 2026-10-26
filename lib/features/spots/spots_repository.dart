import 'package:cloud_firestore/cloud_firestore.dart';

import 'spot_model.dart';

class SpotsRepository {
  final FirebaseFirestore _firestore;

  SpotsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _spotsRef =>
      _firestore.collection('spots');

  Stream<List<Spot>> getAllSpotsStream() {
    return _spotsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Spot.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<Spot>> getAllSpotsOnce() async {
    final snap = await _spotsRef.get();
    return snap.docs.map((doc) => Spot.fromMap(doc.data(), doc.id)).toList();
  }

  Stream<Spot?> getSpotByIdStream(String spotId) {
    return _spotsRef.doc(spotId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Spot.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> createSpot(Spot spot) async {
    await _spotsRef.add(spot.toMap());
  }

  Future<void> updateSpot(Spot spot) async {
    await _spotsRef.doc(spot.id).update({
      'name': spot.name,
      'description': spot.description,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'species': spot.species,
    });
  }

  Future<void> deleteSpot(String spotId) async {
    await _spotsRef.doc(spotId).delete();
  }
}
