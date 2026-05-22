import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_colors.dart';
import '../services/firestore_service.dart';

import 'package:shimmer/shimmer.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: FadeInDown(
                child: Text('Leaderboard 🏆',
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().leaderboardStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _buildShimmer(context);
                  }
                  final data = snap.data ?? [];
                  if (data.isEmpty) return _buildEmptyState(context);

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final entry = data[i];
                      final rank = i + 1;
                      return FadeInUp(
                        delay: Duration(milliseconds: i * 80),
                        child: _LeaderboardCard(entry: entry, rank: rank),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.1),
        highlightColor: isDark ? AppColors.darkSurface : Colors.grey.withOpacity(0.05),
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No leaders yet!', style: TextStyle(color: textColor.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  const _LeaderboardCard({required this.entry, required this.rank});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rank <= 3 ? _rankColor.withOpacity(0.08) : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rankColor.withOpacity(rank <= 3 ? 0.3 : 0.0)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor.withOpacity(0.2),
            ),
            child: Center(
              child: rank <= 3
                  ? Text(['🥇', '🥈', '🥉'][rank - 1], style: const TextStyle(fontSize: 18))
                  : Text('$rank', style: TextStyle(color: _rankColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['username'] ?? 'Anonymous',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                Text('${entry['totalInterviews'] ?? 0} interviews',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(entry['topScore'] ?? 0.0).toStringAsFixed(1)}',
                style: TextStyle(color: _rankColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('top score', style: TextStyle(color: AppColors.textGrey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}