import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersOn = true;

  @override
  void initState() {
    super.initState();
    _loadReminderPref();
  }

  Future<void> _loadReminderPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _remindersOn = prefs.getBool('reminders_on') ?? true);
  }

  Future<void> _toggleReminders(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_on', val);
    setState(() => _remindersOn = val);
    if (val) {
      await NotificationService.showPracticeReminder();
    } else {
      await NotificationService.cancelAll();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = ['English', 'Hindi', 'Urdu', 'Arabic', 'French', 'Spanish'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text('Select Language',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            title: Text(lang,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textDark)),
            leading: Radio<String>(
              value: lang,
              groupValue: 'English',
              onChanged: (_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$lang selected (coming soon)'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              activeColor: AppColors.primary,
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text('Delete Account?',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textDark)),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: TextStyle(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AuthProvider>().deleteAccount();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeInDown(
              child: Text('Settings',
                  style: TextStyle(
                      color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),

            // Profile card
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user?.profilePicUrl != null
                          ? NetworkImage(user!.profilePicUrl!)
                          : null,
                      child: user?.profilePicUrl == null
                          ? Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'User',
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text(user?.email ?? '',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 13)),
                          if (user?.targetRole.isNotEmpty == true)
                            Text(user!.targetRole,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: AppColors.primary,
                ),
              ),
            ),

            // ✅ FIX: reminder switch now actually works
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Daily Reminders',
                trailing: Switch(
                  value: _remindersOn,
                  onChanged: _toggleReminders,
                  activeColor: AppColors.primary,
                ),
              ),
            ),

            // ✅ FIX: language now opens a picker dialog
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () => _showLanguageDialog(context),
              ),
            ),

            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _SettingsTile(
                icon: Icons.info_outline,
                title: 'About App',
                subtitle: 'Version 1.0.0',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'AI Mock Interviewer',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.smart_toy,
                      color: AppColors.primary, size: 40),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Danger zone
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      color: AppColors.error,
                      onTap: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (_) => false,
                          );
                        }
                      },
                    ),
                    Divider(color: AppColors.error.withOpacity(0.1), height: 1),
                    // ✅ FIX: now actually deletes account and navigates to Login
                    _SettingsTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      color: AppColors.error,
                      onTap: () => _showDeleteDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: color ?? textColor, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textGrey)
              : null),
    );
  }
}