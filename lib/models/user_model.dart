import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String university;
  final List<String> skills;
  final String targetRole;
  final String? profilePicUrl;
  final int totalInterviews;
  final double avgScore;
  final int streak;
  final DateTime? lastInterviewDate;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.university = '',
    this.skills = const [],
    this.targetRole = '',
    this.profilePicUrl,
    this.totalInterviews = 0,
    this.avgScore = 0.0,
    this.streak = 0,
    this.lastInterviewDate,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // ✅ FIX #10: lastInterviewDate Timestamp ya null dono handle karo
    // Agar String tha (purana data) to safely ignore karo
    DateTime? lastDate;
    final rawLast = map['lastInterviewDate'];
    if (rawLast is Timestamp) {
      lastDate = rawLast.toDate();
    } else if (rawLast is String && rawLast.isNotEmpty) {
      lastDate = DateTime.tryParse(rawLast);
    }

    // ✅ FIX: createdAt bhi Timestamp handle karo
    DateTime createdAt = DateTime.now();
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      university: map['university'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      targetRole: map['targetRole'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      totalInterviews: map['totalInterviews'] ?? 0,
      avgScore: (map['avgScore'] ?? 0.0).toDouble(),
      streak: map['streak'] ?? 0,
      lastInterviewDate: lastDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'university': university,
      'skills': skills,
      'targetRole': targetRole,
      'profilePicUrl': profilePicUrl,
      'totalInterviews': totalInterviews,
      'avgScore': avgScore,
      'streak': streak,
      'lastInterviewDate': lastInterviewDate != null
          ? Timestamp.fromDate(lastInterviewDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? university,
    List<String>? skills,
    String? targetRole,
    String? profilePicUrl,
    int? totalInterviews,
    double? avgScore,
    int? streak,
    DateTime? lastInterviewDate,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      university: university ?? this.university,
      skills: skills ?? this.skills,
      targetRole: targetRole ?? this.targetRole,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      totalInterviews: totalInterviews ?? this.totalInterviews,
      avgScore: avgScore ?? this.avgScore,
      streak: streak ?? this.streak,
      lastInterviewDate: lastInterviewDate ?? this.lastInterviewDate,
      createdAt: createdAt,
    );
  }
}