import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = [
    _OnboardingData(
      icon: Icons.psychology,
      color: AppColors.primary,
      title: 'AI-Powered Interviews',
      subtitle: 'Experience real interview pressure with our intelligent AI interviewer that adapts to your skill level.',
    ),
    _OnboardingData(
      icon: Icons.mic,
      color: AppColors.info,
      title: 'Voice-Based Practice',
      subtitle: 'Answer questions by speaking naturally. Get instant transcription and evaluation just like a real interview.',
    ),
    _OnboardingData(
      icon: Icons.analytics,
      color: AppColors.success,
      title: 'Track Your Progress',
      subtitle: 'Detailed analytics, performance charts, and AI-powered tips to help you continuously improve.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('Skip', style: TextStyle(color: AppColors.textGrey)),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
                ),
              ),

              // Indicator + Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _ctrl,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.2),
                        dotHeight: 8, dotWidth: 8, expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                      icon: _page == _pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                      onTap: () {
                        if (_page == _pages.length - 1) {
                          _complete();
                        } else {
                          _ctrl.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardingData({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withOpacity(0.15),
                border: Border.all(color: data.color.withOpacity(0.3), width: 2),
              ),
              child: Icon(data.icon, color: data.color, size: 80),
            ),
          ),
          const SizedBox(height: 48),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor, fontSize: 26,
                fontWeight: FontWeight.bold, height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 15, height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}