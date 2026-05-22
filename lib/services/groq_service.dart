import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/question_model.dart';

class GroqService {
  static Future<String> _callGroq(List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse(AppConstants.groqBaseUrl),
      headers: {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConstants.groqModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Generate first question for interview
  static Future<String> generateFirstQuestion({
    required String topic,
    required String level,
    required List<String> userSkills,
    required String targetRole,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''You are a professional technical interviewer at a top tech company.
Your job is to conduct a mock interview.
Topic: $topic
Difficulty: $level
Candidate Skills: ${userSkills.join(', ')}
Target Role: $targetRole

Ask ONLY ONE clear interview question. Be professional and concise.
Do NOT add any explanation or preamble. Just ask the question directly.'''
      },
      {
        'role': 'user',
        'content': 'Start the interview with your first question.',
      }
    ];
    return await _callGroq(messages);
  }

  /// Generate follow-up question based on previous answer
  static Future<String> generateFollowUpQuestion({
    required String topic,
    required String level,
    required String previousQuestion,
    required String userAnswer,
    required List<String> askedQuestions,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''You are a professional technical interviewer.
Topic: $topic, Difficulty: $level.
Based on the candidate's answer, ask a relevant follow-up or new question.
Questions already asked: ${askedQuestions.join(' | ')}
Do NOT repeat questions. Ask ONE new question only. No preamble.'''
      },
      {'role': 'user', 'content': 'Q: $previousQuestion\nA: $userAnswer\n\nAsk next question.'}
    ];
    return await _callGroq(messages);
  }

  /// Evaluate user's answer and return JSON with score + feedback
  static Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String answer,
    required String topic,
    required String level,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''You are an expert interviewer evaluating a candidate's answer.
Topic: $topic, Level: $level.
Evaluate the answer and respond ONLY in this JSON format:
{
  "score": <number 1-10>,
  "feedback": "<detailed feedback in 2-3 sentences>",
  "missing_points": "<what was missing>",
  "correct_points": "<what was correct>"
}
No extra text. Pure JSON only.'''
      },
      {
        'role': 'user',
        'content': 'Question: $question\n\nCandidate Answer: $answer'
      }
    ];

    final raw = await _callGroq(messages);
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').stringMatch(raw);
      final clean = jsonMatch ?? raw;
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {'score': 5, 'feedback': raw, 'missing_points': '', 'correct_points': ''};
    }
  }

  /// Get a hint for current question
  static Future<String> getHint(String question, String topic) async {
    final messages = [
      {
        'role': 'system',
        'content': 'Give a very short hint (1-2 sentences) for this $topic interview question. '
            'Dont give the answer directly.'
      },
      {'role': 'user', 'content': question}
    ];
    return await _callGroq(messages);
  }

  /// Generate final interview summary
  static Future<Map<String, dynamic>> generateSummary({
    required List<QuestionModel> questions,
    required String topic,
    required String level,
  }) async {
    final qa = questions
        .map((q) => 'Q: ${q.questionText}\nA: ${q.userAnswer}\nScore: ${q.score}/10')
        .join('\n\n');

    final messages = [
      {
        'role': 'system',
        'content': '''You are an expert career coach reviewing a mock interview.
Analyze all answers and respond ONLY in this JSON format:
{
  "overall_score": <average score 0-10>,
  "summary": "<2-3 sentence overall assessment>",
  "strong_points": ["<point1>", "<point2>", "<point3>"],
  "weak_areas": ["<area1>", "<area2>"],
  "improvement_tips": ["<tip1>", "<tip2>", "<tip3>"],
  "verdict": "<Excellent|Good|Average|Needs Improvement>"
}
Pure JSON only.'''
      },
      {'role': 'user', 'content': 'Topic: $topic, Level: $level\n\n$qa'}
    ];

    final raw = await _callGroq(messages);
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').stringMatch(raw);
      final clean = jsonMatch ?? raw;
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {
        'overall_score': 5,
        'summary': raw,
        'strong_points': [],
        'weak_areas': [],
        'improvement_tips': [],
        'verdict': 'Average',
      };
    }
  }
}