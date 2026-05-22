import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Signup fields
  final _nameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureSignup = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose(); _loginPassCtrl.dispose();
    _nameCtrl.dispose(); _signUpEmailCtrl.dispose(); _signUpPassCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmail(
      _loginEmailCtrl.text.trim(), _loginPassCtrl.text,
    );
    if (ok && mounted) _goHome();
    else if (mounted) _showError(auth.errorMessage ?? 'Login failed');
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUpWithEmail(
      _nameCtrl.text.trim(),
      _signUpEmailCtrl.text.trim(),
      _signUpPassCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Sign up failed');
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _goHome();
    else if (mounted && auth.errorMessage != null) _showError(auth.errorMessage!);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
              children: [
                const SizedBox(height: 32),
                // Logo
                FadeInDown(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                      )],
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'AI Mock Interviewer',
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                // Tab bar
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? null : [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textGrey,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tab views
                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // Login form
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: Form(
                          key: _loginFormKey,
                          child: Column(
                            children: [
                              _buildField(
                                context: context,
                                controller: _loginEmailCtrl,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                validator: (v) => v!.contains('@') ? null : 'Enter valid email',
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                context: context,
                                controller: _loginPassCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscureLogin,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureLogin ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.textGrey),
                                  onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                                ),
                                validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Sign In',
                                isLoading: auth.status == AuthStatus.loading,
                                onTap: _signIn,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Signup form
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: Form(
                          key: _signUpFormKey,
                          child: Column(
                            children: [
                              _buildField(
                                context: context,
                                controller: _nameCtrl,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (v) => v!.isNotEmpty ? null : 'Enter name',
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                context: context,
                                controller: _signUpEmailCtrl,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                validator: (v) => v!.contains('@') ? null : 'Enter valid email',
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                context: context,
                                controller: _signUpPassCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscureSignup,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureSignup ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.textGrey),
                                  onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
                                ),
                                validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Create Account',
                                isLoading: auth.status == AuthStatus.loading,
                                onTap: _signUp,
                                icon: Icons.person_add,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: textColor.withOpacity(0.4))),
                  ),
                  Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                ]),
                const SizedBox(height: 16),

                // Google button
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: CustomButton(
                    text: 'Continue with Google',
                    isOutlined: true,
                    icon: Icons.g_mobiledata,
                    onTap: _googleSignIn,
                    isLoading: auth.status == AuthStatus.loading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkCard.withOpacity(0.5) : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}