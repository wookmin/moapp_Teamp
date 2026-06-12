import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../repositories/app_repositories.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.firebaseAvailable = true});

  final bool firebaseAvailable;

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

  Future<void> _signInWithGoogle() {
    return _runAuthAction(AppRepositories.auth.signInWithGoogle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            SvgPicture.asset(
              'assets/appLogo.svg',
              height: 36,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 64),
            Text(
              '먹을 건 놓치지 않고,\n살 건 정확하게',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '냉장고 속 재료와 소비기한을 정리하고 필요한 장보기만 빠르게 확인하세요.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 36),
            if (!widget.firebaseAvailable) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.devices_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '웹 미리보기에서는 화면만 확인할 수 있어요. 계정과 냉장고 데이터는 모바일 앱에서 연결됩니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            _GoogleLoginButton(
              onPressed: _isLoading || !widget.firebaseAvailable
                  ? null
                  : _signInWithGoogle,
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
              onPressed: widget.firebaseAvailable ? _showEmailLogin : null,
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
                        onSubmit: _isSignUp
                            ? _createUserWithEmail
                            : _signInWithEmail,
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

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              shape: BoxShape.circle,
            ),
            child: const Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Google로 계속하기'),
        ],
      ),
    );
  }
}
