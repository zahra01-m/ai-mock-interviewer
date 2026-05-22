import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/interview_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User ────────────────────────────────────────────────

  Future<void> updateUserProfile(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update(user.toMap());
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
  }

  Future<void> updateUserStats(String uid, double score) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return;

    final user = UserModel.fromMap(doc.data()!);
    final newTotal = user.totalInterviews + 1;
    final newAvg =
        ((user.avgScore * user.totalInterviews) + score) / newTotal;

    // Streak logic
    int newStreak = user.streak;
    final now = DateTime.now();
    final lastDate = user.lastInterviewDate;

    if (lastDate == null) {
      newStreak = 1;
    } else {
      final difference = DateTime(now.year, now.month, now.day)
          .difference(
          DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'totalInterviews': newTotal,
      'avgScore': newAvg,
      'streak': newStreak,
      'lastInterviewDate': Timestamp.fromDate(now), // ✅ Timestamp use karo
    });
  }

  // ─── Interview ───────────────────────────────────────────

  Future<void> saveInterview(InterviewModel interview) async {
    // ✅ FIX: date ko Timestamp ke tor par save karo — String nahi
    // String save karne se orderBy('date') Firestore index fail karta tha
    // jis ki wajah se history silently empty return hoti thi
    final data = interview.toMap();
    data['date'] = Timestamp.fromDate(interview.date);

    await _db
        .collection(AppConstants.interviewsCollection)
        .doc(interview.id)
        .set(data);

    await updateUserStats(interview.uid, interview.averageScore);
    await _updateLeaderboard(interview.uid, interview.averageScore);
  }

  Future<List<InterviewModel>> getUserInterviews(String uid) async {
    try {
      final snap = await _db
          .collection(AppConstants.interviewsCollection)
          .where('uid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      return snap.docs.map((d) {
        final data = d.data();
        // ✅ FIX: Timestamp ya String dono handle karo — purane records bhi kaam karein
        if (data['date'] is Timestamp) {
          data['date'] =
              (data['date'] as Timestamp).toDate().toIso8601String();
        }
        return InterviewModel.fromMap(data);
      }).toList();
    } catch (e) {
      // ✅ FIX: agar orderBy index nahi bana to bina sorting ke try karo
      // Console mein index banana ka link aayega — zaroor banao
      final snap = await _db
          .collection(AppConstants.interviewsCollection)
          .where('uid', isEqualTo: uid)
          .limit(20)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        if (data['date'] is Timestamp) {
          data['date'] =
              (data['date'] as Timestamp).toDate().toIso8601String();
        }
        return InterviewModel.fromMap(data);
      }).toList();

      // Client side sort karo
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  // ─── Leaderboard ─────────────────────────────────────────

  Future<void> _updateLeaderboard(String uid, double score) async {
    final doc = await _db
        .collection(AppConstants.leaderboardCollection)
        .doc(uid)
        .get();

    final userDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!userDoc.exists) return;

    final user = UserModel.fromMap(userDoc.data()!);

    final existingTop =
    (doc.exists ? (doc.data()?['topScore'] ?? 0) : 0).toDouble();

    // ✅ FIX: pehli dafa bhi update karo, aur sirf better score par update karo
    if (!doc.exists || score > existingTop) {
      await _db
          .collection(AppConstants.leaderboardCollection)
          .doc(uid)
          .set({
        'uid': uid,
        'username': user.name,
        'topScore': score,
        'totalInterviews': user.totalInterviews,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      // ✅ FIX: score better nahi tha to sirf totalInterviews update karo
      await _db
          .collection(AppConstants.leaderboardCollection)
          .doc(uid)
          .update({
        'totalInterviews': user.totalInterviews,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> leaderboardStream() {
    return _db
        .collection(AppConstants.leaderboardCollection)
        .orderBy('topScore', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}