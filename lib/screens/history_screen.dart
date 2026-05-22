import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/interview_provider.dart';
import '../models/interview_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<InterviewProvider>().loadHistory(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final interviews = context.watch<InterviewProvider>().history;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FadeInDown(
                  child: Text('Interview History',
                      style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            // Performance chart
            if (interviews.length >= 2)
              SliverToBoxAdapter(
                child: FadeInUp(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark ? null : [
                          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Score Trend', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: interviews.reversed.toList()
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value.averageScore))
                                        .toList(),
                                    isCurved: true,
                                    color: AppColors.primary,
                                    barWidth: 3,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                    ),
                                    dotData: const FlDotData(show: true),
                                  ),
                                ],
                                minY: 0, maxY: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // List
            interviews.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.history, color: AppColors.textGrey, size: 64),
                    const SizedBox(height: 16),
                    const Text('No interviews yet', style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
                    const Text('Start your first mock interview!', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ],
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final interview = interviews[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    child: _HistoryCard(interview: interview),
                  );
                },
                childCount: interviews.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final InterviewModel interview;
  const _HistoryCard({required this.interview});

  Color get _scoreColor {
    final s = interview.averageScore;
    if (s >= 8) return AppColors.success;
    if (s >= 6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _scoreColor.withValues(alpha: 0.2)),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(interview.topic,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(interview.level,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                ),
                const Spacer(),
                Text(
                  '${interview.averageScore.toStringAsFixed(1)}/10',
                  style: TextStyle(color: _scoreColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.quiz_outlined, color: AppColors.textGrey, size: 14),
                const SizedBox(width: 4),
                Text('${interview.questions.length} questions',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today_outlined, color: AppColors.textGrey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${interview.date.day}/${interview.date.month}/${interview.date.year}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
            if (interview.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                interview.summary,
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}