import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/interview_model.dart';
import '../models/question_model.dart';
import '../services/groq_service.dart';
import '../services/firestore_service.dart';

enum InterviewStatus { idle, generating, active, evaluating, completed, error }

class InterviewProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final _uuid = const Uuid();

  InterviewStatus _status = InterviewStatus.idle;
  InterviewModel? _currentInterview;
  QuestionModel? _currentQuestion;
  String _currentTranscript = '';
  bool _isListening = false;
  String? _errorMessage;
  Map<String, dynamic>? _summaryData;
  List<InterviewModel> _history = [];

  InterviewStatus get status => _status;
  InterviewModel? get currentInterview => _currentInterview;
  QuestionModel? get currentQuestion => _currentQuestion;
  String get currentTranscript => _currentTranscript;
  bool get isListening => _isListening;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summaryData => _summaryData;
  List<InterviewModel> get history => _history;
  int get questionNumber => _currentInterview?.questions.length ?? 0;

  Future<void> startInterview({
    required String uid,
    required String topic,
    required String level,
    required int durationMinutes,
    required List<String> skills,
    required String targetRole,
  }) async {
    _status = InterviewStatus.generating;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentInterview = InterviewModel(
        id: _uuid.v4(),
        uid: uid,
        topic: topic,
        level: level,
        durationMinutes: durationMinutes,
        date: DateTime.now(),
      );

      final question = await GroqService.generateFirstQuestion(
        topic: topic,
        level: level,
        userSkills: skills,
        targetRole: targetRole,
      );

      _currentQuestion = QuestionModel(id: _uuid.v4(), questionText: question);
      _status = InterviewStatus.active;
      notifyListeners();
    } catch (e) {
      _status = InterviewStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateTranscript(String text) {
    _currentTranscript = text;
    notifyListeners();
  }

  void setListening(bool val) {
    _isListening = val;
    notifyListeners();
  }

  Future<void> submitAnswer(String answer) async {
    if (_currentQuestion == null || _currentInterview == null) return;

    _status = InterviewStatus.evaluating;
    notifyListeners();

    try {
      final evaluation = await GroqService.evaluateAnswer(
        question: _currentQuestion!.questionText,
        answer: answer,
        topic: _currentInterview!.topic,
        level: _currentInterview!.level,
      );

      _currentQuestion!.userAnswer = answer;
      _currentQuestion!.score = (evaluation['score'] ?? 5).toDouble();
      _currentQuestion!.feedback = evaluation['feedback'] ?? '';
      _currentQuestion!.answeredAt = DateTime.now();

      final updatedQuestions = [..._currentInterview!.questions, _currentQuestion!];
      _currentInterview = InterviewModel(
        id: _currentInterview!.id,
        uid: _currentInterview!.uid,
        topic: _currentInterview!.topic,
        level: _currentInterview!.level,
        durationMinutes: _currentInterview!.durationMinutes,
        questions: updatedQuestions,
        date: _currentInterview!.date,
      );

      _currentTranscript = '';
      _status = InterviewStatus.active;
      notifyListeners();
    } catch (e) {
      _status = InterviewStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> generateNextQuestion() async {
    if (_currentInterview == null) {
      _status = InterviewStatus.error;
      _errorMessage = 'Interview session not found. Please restart.';
      notifyListeners();
      return;
    }

    if (_currentInterview!.questions.isEmpty) {
      _status = InterviewStatus.error;
      _errorMessage = 'No questions found to follow up on.';
      notifyListeners();
      return;
    }

    _status = InterviewStatus.generating;
    notifyListeners();

    try {
      final askedQuestions = _currentInterview!.questions
          .map((q) => q.questionText)
          .toList();

      final lastQ = _currentInterview!.questions.last;
      final question = await GroqService.generateFollowUpQuestion(
        topic: _currentInterview!.topic,
        level: _currentInterview!.level,
        previousQuestion: lastQ.questionText,
        userAnswer: lastQ.userAnswer.isNotEmpty
            ? lastQ.userAnswer
            : 'No answer provided.',
        askedQuestions: askedQuestions,
      );

      _currentQuestion = QuestionModel(id: _uuid.v4(), questionText: question);
      _status = InterviewStatus.active;
      notifyListeners();
    } catch (e) {
      _status = InterviewStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<String> getHint() async {
    if (_currentQuestion == null || _currentInterview == null) return '';
    final hint = await GroqService.getHint(
      _currentQuestion!.questionText,
      _currentInterview!.topic,
    );
    _currentQuestion!.hint = hint;
    _currentQuestion!.hintUsed = true;
    notifyListeners();
    return hint;
  }

  Future<void> endInterview(String uid) async {
    if (_currentInterview == null) {
      _status = InterviewStatus.error;
      _errorMessage = 'Interview session not found. Please restart.';
      notifyListeners();
      return;
    }

    _status = InterviewStatus.evaluating;
    notifyListeners();

    try {
      final questions = _currentInterview!.questions;
      if (questions.isEmpty) {
        _summaryData = {
          'overall_score': 0,
          'summary': 'No questions were answered in this session.',
          'strong_points': [],
          'weak_areas': [],
          'improvement_tips': ['Try starting a new interview session.'],
          'verdict': 'Incomplete',
        };
      } else {
        _summaryData = await GroqService.generateSummary(
          questions: questions,
          topic: _currentInterview!.topic,
          level: _currentInterview!.level,
        );
      }

      final finalInterview = InterviewModel(
        id: _currentInterview!.id,
        uid: uid,
        topic: _currentInterview!.topic,
        level: _currentInterview!.level,
        durationMinutes: _currentInterview!.durationMinutes,
        questions: _currentInterview!.questions,
        totalScore: (_summaryData!['overall_score'] ?? 0).toDouble(),
        summary: _summaryData!['summary'] ?? '',
        strongPoints: List<String>.from(_summaryData!['strong_points'] ?? []),
        weakAreas: List<String>.from(_summaryData!['weak_areas'] ?? []),
        improvementTips: List<String>.from(_summaryData!['improvement_tips'] ?? []),
        date: _currentInterview!.date,
      );

      await _firestoreService.saveInterview(finalInterview);
      _currentInterview = finalInterview;
      _status = InterviewStatus.completed;

      // ✅ FIX #12: history reload karo taake History tab mein foran dikh sake
      _history = await _firestoreService.getUserInterviews(uid);

      notifyListeners();
    } catch (e) {
      _status = InterviewStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHistory(String uid) async {
    _history = await _firestoreService.getUserInterviews(uid);
    notifyListeners();
  }

  void reset() {
    _status = InterviewStatus.idle;
    _currentInterview = null;
    _currentQuestion = null;
    _currentTranscript = '';
    _summaryData = null;
    notifyListeners();
  }
}