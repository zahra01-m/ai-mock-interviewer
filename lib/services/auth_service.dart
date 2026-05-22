import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ FIX: GoogleSignIn ko properly configure karo.
  // Error 10 (DEVELOPER_ERROR) tab aata hai jab SHA-1 fingerprint Firebase mein
  // register nahi hota, ya scopes missing hoti hain.
  // Scopes explicitly declare karo:
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user!.updateDisplayName(name);

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    return await getUserData(cred.user!.uid);
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // ✅ FIX: pehle sign out karo taake fresh account picker khule
      // Yeh Error 10 ka ek common cause hai — stale session
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;

      // ✅ FIX: idToken null check — agar null hai to clear error do
      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed: Could not get ID token.\n'
              'Please ensure SHA-1 fingerprint is added in Firebase Console:\n'
              'Firebase Console → Project Settings → Your App → Add Fingerprint\n'
              'Run: cd android && ./gradlew signingReport  to get your SHA-1.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      // Check if user exists in Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        final user = UserModel(
          uid: uid,
          name: cred.user!.displayName ?? 'User',
          email: cred.user!.email ?? '',
          profilePicUrl: cred.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(user.toMap());
        return user;
      }
      return UserModel.fromMap(doc.data()!);

    } catch (e) {
      // ✅ FIX: Error 10 ko friendly message mein convert karo
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google Sign-In setup error (Code 10).\n'
              'Fix: Add your app\'s SHA-1 fingerprint to Firebase Console.\n'
              '1. Run: cd android && ./gradlew signingReport\n'
              '2. Copy the SHA-1 value\n'
              '3. Firebase Console → Project Settings → Your Android App → Add Fingerprint\n'
              '4. Download the new google-services.json and replace it in android/app/',
        );
      }
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).delete();
      await _firestore.collection(AppConstants.leaderboardCollection).doc(uid).delete();
    }
    await currentUser?.delete();
  }
}