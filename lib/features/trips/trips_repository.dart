import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_model.dart';

class TripsRepository {
  final FirebaseFirestore _firestore;

  TripsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tripsRef =>
      _firestore.collection('trips');

  Stream<List<Trip>> getUserTripsStream(String userId) {
    return _tripsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<Trip>> getTripsOnce(String userId) async {
    final snap = await _tripsRef
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map((doc) => Trip.fromMap(doc.data(), doc.id)).toList();
  }

  Stream<Trip?> getTripByIdStream(String tripId) {
    return _tripsRef.doc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Trip.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> createTrip(Trip trip) async {
    await _tripsRef.add(trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    await _tripsRef.doc(trip.id).update({
      'title': trip.title,
      'date': Timestamp.fromDate(trip.date),
      'locationName': trip.locationName,
      'species': trip.species,
      'notes': trip.notes,
    });
  }

  Stream<List<Trip>> getSharedTripsStream(String userId) {
    return _tripsRef
        .where('sharedWith', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updateTripSharing(String tripId, List<String> friendUids) async {
    await _tripsRef.doc(tripId).update({
      'sharedWith': friendUids,
    });
  }

  Future<void> toggleTripReaction(String tripId, String userId, bool isLike) async {
    final docRef = _tripsRef.doc(tripId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final trip = Trip.fromMap(snap.data()!, snap.id);
    final currentlyLiked = trip.isLikedBy(userId);
    final currentlyDisliked = trip.isDislikedBy(userId);

    if (isLike) {
      if (currentlyLiked) {
        // Toggle off like
        await docRef.update({
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Add like and ensure dislike is removed
        await docRef.update({
          'likedBy': FieldValue.arrayUnion([userId]),
          if (currentlyDisliked) 'dislikedBy': FieldValue.arrayRemove([userId]),
        });
      }
    } else {
      if (currentlyDisliked) {
        // Toggle off dislike
        await docRef.update({
          'dislikedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Add dislike and ensure like is removed
        await docRef.update({
          'dislikedBy': FieldValue.arrayUnion([userId]),
          if (currentlyLiked) 'likedBy': FieldValue.arrayRemove([userId]),
        });
      }
    }
  }

  Future<void> deleteTrip(String tripId) async {
    await _tripsRef.doc(tripId).delete();
  }
}
