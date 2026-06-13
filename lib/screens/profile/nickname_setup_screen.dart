import 'package:flutter/material.dart';

import '../../models/nickname_status.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/firebase_profile_repository.dart';
import '../../widgets/common_app_bar.dart';

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({
    super.key,
    required this.status,
    this.isInitialSetup = false,
    this.onSaved,
  });

  final NicknameStatus status;
  final bool isInitialSetup;
  final VoidCallback? onSaved;

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.status.nickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _controller.text.trim();
    final validationError = FirebaseProfileRepository.validateNickname(
      nickname,
    );
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await AppRepositories.profile.updateNickname(nickname);
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canChange = widget.status.canChange;

    return Scaffold(
      appBar: widget.isInitialSetup
          ? null
          : const CommonAppBar(showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              widget.isInitialSetup ? '닉네임을 정해주세요' : '닉네임 변경',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isInitialSetup
                  ? '커뮤니티와 공유 냉장고에서 사용할 이름이에요.'
                  : canChange
                  ? '닉네임은 변경 후 7일 동안 다시 바꿀 수 없어요.'
                  : '${_formatDate(widget.status.nextChangeAt!)}부터 다시 변경할 수 있어요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              enabled: canChange,
              autofocus: widget.isInitialSetup,
              maxLength: 12,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (canChange && !_isSaving) _save();
              },
              decoration: InputDecoration(
                labelText: '닉네임',
                hintText: '2~12자',
                helperText: '한글, 영문, 숫자, 밑줄을 사용할 수 있어요.',
                errorText: _errorMessage,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canChange && !_isSaving ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isInitialSetup ? '시작하기' : '변경하기'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
