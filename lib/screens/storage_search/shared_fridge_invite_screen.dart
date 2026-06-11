import 'package:flutter/material.dart';

import '../../models/shared_fridge.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class SharedFridgeInviteArguments {
  const SharedFridgeInviteArguments({
    required this.ownerUid,
    required this.code,
  });

  final String ownerUid;
  final String code;
}

class SharedFridgeInviteScreen extends StatefulWidget {
  const SharedFridgeInviteScreen({required this.arguments, super.key});

  final SharedFridgeInviteArguments arguments;

  @override
  State<SharedFridgeInviteScreen> createState() =>
      _SharedFridgeInviteScreenState();
}

class _SharedFridgeInviteScreenState extends State<SharedFridgeInviteScreen> {
  late Future<SharedFridgeInvite> _inviteFuture;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _inviteFuture = AppRepositories.sharedFridges.fetchInvite(
      ownerUid: widget.arguments.ownerUid,
      code: widget.arguments.code,
    );
  }

  void _retry() {
    setState(() {
      _inviteFuture = AppRepositories.sharedFridges.fetchInvite(
        ownerUid: widget.arguments.ownerUid,
        code: widget.arguments.code,
      );
    });
  }

  Future<void> _join() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    try {
      await AppRepositories.sharedFridges.acceptInvite(
        ownerUid: widget.arguments.ownerUid,
        code: widget.arguments.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구 냉장고가 연결됐어요.')));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/storage-search', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('참여하지 못했어요: $error')));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: FutureBuilder<SharedFridgeInvite>(
        future: _inviteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyStateView(
                icon: Icons.link_off_rounded,
                title: '초대 링크를 열 수 없어요',
                message:
                    snapshot.error?.toString().replaceFirst(
                      'Bad state: ',
                      '',
                    ) ??
                    '만료되었거나 사용할 수 없는 링크입니다.',
                action: TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 확인'),
                ),
              ),
            );
          }

          final invite = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '${invite.fridgeName}에\n초대받았어요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                invite.canEdit
                    ? '참여하면 재료를 확인하고 함께 추가할 수 있어요.'
                    : '참여하면 냉장고 재료와 소비기한을 확인할 수 있어요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(
                    invite.canEdit
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                  ),
                  title: const Text('내 권한'),
                  subtitle: Text(invite.canEdit ? '함께 관리' : '보기만 가능'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isJoining ? null : _join,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isJoining
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('친구 냉장고 연결하기'),
              ),
              const SizedBox(height: 10),
              Text(
                '초대 링크는 생성일로부터 7일 동안 유효합니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
