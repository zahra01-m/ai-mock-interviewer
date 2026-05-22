import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class InterviewModel {
  final String id;
  final String uid;
  final String topic;
  final String level;
  final int durationMinutes;
  final List<QuestionModel> questions;
  final double totalScore;
  final String summary;
  final List<String> strongPoints;
  final List<String> weakAreas;
  final List<String> improvementTips;
  final DateTime date;

  InterviewModel({
    required this.id,
    required this.uid,
    required this.topic,
    required this.level,
    required this.durationMinutes,
    this.questions = const [],
    this.totalScore = 0,
    this.summary = '',
    this.strongPoints = const [],
    this.weakAreas = const [],
    this.improvementTips = const [],
    required this.date,
  });

  double get averageScore {
    if (questions.isEmpty) return 0;
    return questions.map((q) => q.score).reduce((a, b) => a + b) /
        questions.length;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'topic': topic,
    'level': level,
    'durationMinutes': durationMinutes,
    'questions': questions.map((q) => q.toMap()).toList(),
    'totalScore': totalScore,
    'summary': summary,
    'strongPoints': strongPoints,
    'weakAreas': weakAreas,
    'improvementTips': improvementTips,
    // date yahan String — firestore_service.dart mein Timestamp override karta hai
    'date': date.toIso8601String(),
  };

  factory InterviewModel.fromMap(Map<String, dynamic> map) {
    // ✅ FIX: Timestamp, String, aur null — teeno handle karo
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return InterviewModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      topic: map['topic'] ?? '',
      level: map['level'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 10,
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      totalScore: (map['totalScore'] ?? 0).toDouble(),
      summary: map['summary'] ?? '',
      strongPoints: List<String>.from(map['strongPoints'] ?? []),
      weakAreas: List<String>.from(map['weakAreas'] ?? []),
      improvementTips: List<String>.from(map['improvementTips'] ?? []),
      date: parsedDate,
    );
  }
}