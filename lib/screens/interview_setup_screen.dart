import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/interview_provider.dart';
import '../widgets/custom_button.dart';
import 'interview_room_screen.dart';

import 'package:permission_handler/permission_handler.dart';

class InterviewSetupScreen extends StatefulWidget {
  final String? preselectedTopic;
  const InterviewSetupScreen({super.key, this.preselectedTopic});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  late String _selectedTopic;
  String _selectedLevel = 'Intermediate';
  int _selectedDuration = 10;

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.preselectedTopic ?? AppConstants.topics.first;
  }

  Future<void> _startInterview() async {
    // Request permissions first
    final micStatus = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();

    if (micStatus.isDenied || cameraStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone and Camera permissions are required for the interview.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final interviewProvider = context.read<InterviewProvider>();
    interviewProvider.reset();

    await interviewProvider.startInterview(
      uid: user.uid,
      topic: _selectedTopic,
      level: _selectedLevel,
      durationMinutes: _selectedDuration,
      skills: user.skills,
      targetRole: user.targetRole,
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InterviewRoomScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    FadeInRight(
                      child: Text('Setup Interview',
                          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic
                      FadeInUp(
                        child: _sectionLabel('Select Topic', textColor),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: AppConstants.topics.map((t) => _Chip(
                            label: t,
                            selected: _selectedTopic == t,
                            onTap: () => setState(() => _selectedTopic = t),
                          )).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Level
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _sectionLabel('Difficulty Level', textColor),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          children: AppConstants.levels.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LevelCard(
                              level: l,
                              selected: _selectedLevel == l,
                              onTap: () => setState(() => _selectedLevel = l),
                            ),
                          )).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Duration
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _sectionLabel('Interview Duration', textColor),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: Row(
                          children: AppConstants.interviewDurations.map((d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _Chip(
                                label: '${d}m',
                                selected: _selectedDuration == d,
                                onTap: () => setState(() => _selectedDuration = d),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Summary card
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryItem(label: 'Topic', value: _selectedTopic),
                              _SummaryItem(label: 'Level', value: _selectedLevel),
                              _SummaryItem(label: 'Duration', value: '${_selectedDuration}min'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Start button
                      Consumer<InterviewProvider>(
                        builder: (_, p, __) => FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: CustomButton(
                            text: 'Start Interview 🚀',
                            isLoading: p.status == InterviewStatus.generating,
                            onTap: _startInterview,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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

  Widget _sectionLabel(String text, Color textColor) => Text(
    text,
    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.2)),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]
              : (isDark ? null : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? AppColors.textGrey : AppColors.textDark),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String level;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({required this.level, required this.selected, required this.onTap});

  static const _icons = {
    'Beginner': Icons.signal_cellular_alt_1_bar,
    'Intermediate': Icons.signal_cellular_alt_2_bar,
    'Advanced': Icons.signal_cellular_alt,
    'Mock Final Round': Icons.military_tech,
  };

  static const _colors = {
    'Beginner': AppColors.success,
    'Intermediate': AppColors.info,
    'Advanced': AppColors.warning,
    'Mock Final Round': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final color = _colors[level] ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.1)), width: 1.5),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(_icons[level] ?? Icons.bar_chart, color: color, size: 22),
            const SizedBox(width: 12),
            Text(level, style: TextStyle(
              color: selected ? textColor : (isDark ? AppColors.textGrey : AppColors.textDark),
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            )),
            if (selected) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: isDark ? AppColors.primaryLight : AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}