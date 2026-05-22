import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _uniCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  List<String> _selectedSkills = [];
  bool _loading = false;

  final _skills = [
    'Flutter', 'Java', 'Python', 'C++', 'JavaScript',
    'React', 'Node.js', 'SQL', 'Machine Learning', 'Android', 'iOS',
    'Spring Boot', 'Django', 'MongoDB', 'Docker', 'AWS'
  ];

  @override
  void dispose() {
    _uniCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // ✅ FIX #11: mounted check — agar widget dispose ho chuka ho to setState mat karo
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final updated = user.copyWith(
        university: _uniCtrl.text.trim(),
        targetRole: _roleCtrl.text.trim(),
        skills: _selectedSkills,
      );

      await FirestoreService().updateUserProfile(updated);

      // ✅ FIX: mounted check after async operation
      if (!mounted) return;

      context.read<AuthProvider>().updateUser(updated);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Setup Profile 🎯',
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Help us personalize your interview experience',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 32),

                _label('University / College', textColor),
                const SizedBox(height: 8),
                _field(_uniCtrl, 'e.g. COMSATS University', Icons.school_outlined, isDark),

                const SizedBox(height: 20),
                _label('Target Role', textColor),
                const SizedBox(height: 8),
                _field(_roleCtrl, 'e.g. Flutter Developer, Backend Engineer', Icons.work_outline, isDark),

                const SizedBox(height: 24),
                _label('Your Skills (select all that apply)', textColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _skills.map((s) {
                    final selected = _selectedSkills.contains(s);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) _selectedSkills.remove(s);
                        else _selectedSkills.add(s);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.primaryGradient : null,
                          color: selected ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark ? null : [
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(s,
                            style: TextStyle(
                              color: selected ? Colors.white : (isDark ? AppColors.textGrey : AppColors.textDark),
                              fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
                CustomButton(
                  text: 'Save & Continue',
                  icon: Icons.arrow_forward,
                  isLoading: _loading,
                  onTap: _save,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                  child: const Center(
                    child: Text('Skip for now', style: TextStyle(color: AppColors.textGrey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color textColor) => Text(
    text, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, bool isDark) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textGrey),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}