import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../repositories/app_repositories.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showEmailLogin() {
    setState(() {
      _showEmailForm = true;
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      _goToDashboard();
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '오류가 발생했습니다. 다시 시도해주세요.';
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmail() {
    return _runAuthAction(() async {
      await AppRepositories.auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    });
  }

  Future<void> _createUserWithEmail() {
    return _runAuthAction(() async {
      await AppRepositories.auth.createUserWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    });
  }

  Future<void> _signInWithKakao() {
    return _runAuthAction(AppRepositories.auth.signInWithKakao);
  }

  Future<void> _signInWithGoogle() {
    return _runAuthAction(AppRepositories.auth.signInWithGoogle);
  }

  Future<void> _signInWithApple() {
    return _runAuthAction(AppRepositories.auth.signInWithApple);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            SvgPicture.asset(
              'assets/appLogo.svg',
              height: 36,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 54),
            Text(
              '오늘의 냉장고를\n바로 확인하세요',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '소비기한 알림, 보관 팁, 장보기 추천을 계정에 맞춰 이어서 사용할 수 있어요.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 42),
            _SocialLoginButton(
              label: '카카오로 계속하기',
              icon: Icons.chat_bubble_rounded,
              backgroundColor: const Color(0xFFFFE812),
              foregroundColor: const Color(0xFF241E1F),
              onPressed: _isLoading ? null : _signInWithKakao,
            ),
            const SizedBox(height: 12),
            _SocialLoginButton(
              label: 'Google로 계속하기',
              icon: Icons.g_mobiledata_rounded,
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
            const SizedBox(height: 12),
            _SocialLoginButton(
              label: 'Apple로 계속하기',
              icon: Icons.apple_rounded,
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '또는',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _showEmailLogin,
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('이메일로 계속하기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showEmailForm
                  ? Padding(
                      key: const ValueKey('email-form'),
                      padding: const EdgeInsets.only(top: 18),
                      child: _EmailLoginForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        isSignUp: _isSignUp,
                        errorMessage: _errorMessage,
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onSubmit: _isSignUp ? _createUserWithEmail : _signInWithEmail,
                        onToggleSignUp: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty-email-form')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailLoginForm extends StatelessWidget {
  const _EmailLoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.isSignUp,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.onToggleSignUp,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool isSignUp;
  final VoidCallback onTogglePasswordVisibility;
  final Future<void> Function() onSubmit;
  final VoidCallback onToggleSignUp;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            context,
            hintText: '이메일',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: _inputDecoration(
            context,
            hintText: '비밀번호',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              tooltip: obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isSignUp ? '회원가입' : '로그인'),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignUp ? '이미 계정이 있으신가요?' : '계정이 없으신가요?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: onToggleSignUp,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(isSignUp ? '로그인' : '회원가입'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
