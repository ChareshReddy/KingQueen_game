import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/providers/game_provider.dart';
import 'package:king_queen/screens/home/home_screen.dart';
import 'package:king_queen/widgets/gold_button.dart';
import 'package:king_queen/widgets/animated_raja_rani_background.dart';

enum AuthMode { login, signup, anonymous }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  AuthMode _mode = AuthMode.anonymous;
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedRajaRaniBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo().animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),
                  _buildModeToggle(),
                  const SizedBox(height: 32),
                  _buildFields(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                  Text(
                    'Developed by -Cherry😉',
                    style: GoogleFonts.outfit(
                      color: AppTheme.gold.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: const Icon(Icons.castle_rounded, color: AppTheme.gold, size: 60),
        ),
        const SizedBox(height: 20),
        Text(
          'KING QUEEN',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeButton('ANONYMOUS', AuthMode.anonymous),
        _modeButton('LOGIN', AuthMode.login),
        _modeButton('SIGNUP', AuthMode.signup),
      ],
    );
  }

  Widget _modeButton(String text, AuthMode mode) {
    bool isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.gold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppTheme.gold : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        if (_mode != AuthMode.login)
          _textField(_nameController, 'Display Name', Icons.person_outline),
        if (_mode != AuthMode.anonymous) ...[
          const SizedBox(height: 16),
          _textField(_emailController, 'Email Address', Icons.email_outlined),
          const SizedBox(height: 16),
          _textField(
            _passwordController, 
            'Password', 
            Icons.lock_outline, 
            obscure: _isObscured,
            suffix: IconButton(
              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold.withOpacity(0.5)),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ),
          ),
          if (_mode == AuthMode.signup) ...[
            const SizedBox(height: 16),
            _textField(
              _confirmPasswordController, 
              'Confirm Password', 
              Icons.lock_reset_rounded, 
              obscure: _isObscured,
            ),
          ],
        ],
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _textField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.gold.withOpacity(0.5)),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.gold, width: 1),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isLoading = ref.watch(gameProvider).isLoading;
    return GoldButton(
      text: _mode == AuthMode.anonymous ? 'ENTER ARENA' : (_mode == AuthMode.login ? 'LOGIN' : 'CREATE ACCOUNT'),
      isLoading: isLoading,
      onPressed: () async {
        try {
          if (_mode == AuthMode.anonymous) {
            if (_nameController.text.isEmpty) {
              _showError('Please enter a display name');
              return;
            }
            await ref.read(gameProvider.notifier).login(_nameController.text);
          } else if (_mode == AuthMode.login) {
            if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
              _showError('Please fill all fields');
              return;
            }
            await ref.read(gameProvider.notifier).loginWithEmail(_emailController.text, _passwordController.text);
          } else {
            if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
              _showError('Please fill all fields');
              return;
            }
            if (_passwordController.text != _confirmPasswordController.text) {
              _showError('Passwords do not match');
              return;
            }
            if (_passwordController.text.length < 6) {
              _showError('Password must be at least 6 characters');
              return;
            }
            await ref.read(gameProvider.notifier).signup(_emailController.text, _passwordController.text, _nameController.text);
          }
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } catch (e) {
          if (mounted) {
            _showError('Auth failed: $e');
          }
        }
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
