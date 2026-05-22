class QuestionModel {
  final String id;
  final String questionText;
  String userAnswer;
  double score; // 0-10
  String feedback;
  String? hint;
  bool hintUsed;
  DateTime? answeredAt;

  QuestionModel({
    required this.id,
    required this.questionText,
    this.userAnswer = '',
    this.score = 0,
    this.feedback = '',
    this.hint,
    this.hintUsed = false,
    this.answeredAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'questionText': questionText,
    'userAnswer': userAnswer,
    'score': score,
    'feedback': feedback,
    'hint': hint,
    'hintUsed': hintUsed,
    'answeredAt': answeredAt?.toIso8601String(),
  };

  factory QuestionModel.fromMap(Map<String, dynamic> map) => QuestionModel(
    id: map['id'] ?? '',
    questionText: map['questionText'] ?? '',
    userAnswer: map['userAnswer'] ?? '',
    score: (map['score'] ?? 0).toDouble(),
    feedback: map['feedback'] ?? '',
    hint: map['hint'],
    hintUsed: map['hintUsed'] ?? false,
    answeredAt: map['answeredAt'] != null
        ? DateTime.parse(map['answeredAt'])
        : null,
  );
}