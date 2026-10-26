import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final uid = credential.user!.uid;
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);

      // Do NOT store email in the public user document
      await _firestore.collection('users').doc(uid).set({
        'username': displayName,
        'usernameLower': displayName.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<Map<String, dynamic>?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data();
      }
      return null;
    });
  }
}
