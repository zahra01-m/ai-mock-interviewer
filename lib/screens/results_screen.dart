import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../providers/interview_provider.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Color _scoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX #13: context.read pehle karo — pushAndRemoveUntil ke baad
    // context use karna unsafe hota hai
    final interviewProvider = context.read<InterviewProvider>();
    final interview = interviewProvider.currentInterview;
    final summary = interviewProvider.summaryData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    if (interview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final score = interview.averageScore;
    final verdict = summary?['verdict'] ?? 'Average';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Score hero
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      FadeInDown(
                        child: Text(
                          'Interview Complete! 🎉',
                          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Score circle
                      ZoomIn(
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          width: 150, height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_scoreColor(score), _scoreColor(score).withOpacity(0.6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _scoreColor(score).withOpacity(0.4),
                                blurRadius: 30, spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                score.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const Text('/ 10', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _scoreColor(score).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _scoreColor(score)),
                          ),
                          child: Text(
                            verdict,
                            style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: Text(
                          '${interview.topic} • ${interview.level} • ${interview.questions.length} Questions',
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary
              if (interview.summary.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _Card(
                        title: '📝 Summary',
                        child: Text(interview.summary,
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14, height: 1.6)),
                      ),
                    ),
                  ),
                ),

              // Strong points
              if (interview.strongPoints.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _Card(
                        title: '✅ Strong Points',
                        child: Column(
                          children: interview.strongPoints.map((p) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(p, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13))),
                                  ],
                                ),
                              ),
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

              // Weak areas
              if (interview.weakAreas.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _Card(
                        title: '⚠️ Areas to Improve',
                        child: Column(
                          children: interview.weakAreas.map((a) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(a, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13))),
                                  ],
                                ),
                              ),
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

              // Improvement tips
              if (interview.improvementTips.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _Card(
                        title: '💡 Tips for Improvement',
                        child: Column(
                          children: interview.improvementTips.map((tip) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb, color: AppColors.warning, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(tip, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, height: 1.5))),
                                  ],
                                ),
                              ),
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

              // Q&A breakdown
              SliverToBoxAdapter(
                child: FadeInUp(
                  delay: const Duration(milliseconds: 1100),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _Card(
                      title: '📊 Question Breakdown',
                      child: Column(
                        children: interview.questions.asMap().entries.map((e) {
                          final i = e.key;
                          final q = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Q${i + 1}: ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Expanded(
                                      child: Text(q.questionText,
                                          style: TextStyle(color: textColor, fontSize: 13),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _scoreColor(q.score).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${q.score.toStringAsFixed(0)}/10',
                                          style: TextStyle(color: _scoreColor(q.score), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                if (q.feedback.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 20),
                                    child: Text(q.feedback,
                                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.4),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),

              // Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CustomButton(
                        text: 'Share Results',
                        isOutlined: true,
                        icon: Icons.share,
                        onTap: () => Share.share(
                          '🎯 I scored ${score.toStringAsFixed(1)}/10 on ${interview.topic} '
                              '(${interview.level}) interview on AI Mock Interviewer!\n'
                              'Verdict: $verdict\n\nPractice and improve with AI Mock Interviewer!',
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Back to Home',
                        icon: Icons.home,
                        onTap: () {
                          // ✅ FIX #13: provider pehle read karo, navigate baad mein
                          interviewProvider.reset();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (_) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}