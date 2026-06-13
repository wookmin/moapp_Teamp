import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth_user.dart';
import '../../models/nickname_status.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_shell.dart';
import '../login/login_screen.dart';
import '../profile/nickname_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !AppRepositories.firebaseEnabled) {
      return const LoginScreen(firebaseAvailable: false);
    }

    return StreamBuilder<AuthUser?>(
      stream: AppRepositories.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return _NicknameGate(userId: snapshot.data!.id);
      },
    );
  }
}

class _NicknameGate extends StatefulWidget {
  const _NicknameGate({required this.userId});

  final String userId;

  @override
  State<_NicknameGate> createState() => _NicknameGateState();
}

class _NicknameGateState extends State<_NicknameGate> {
  late Future<NicknameStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _NicknameGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _refresh();
  }

  void _refresh() {
    _statusFuture = AppRepositories.profile.fetchNicknameStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NicknameStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final status = snapshot.data ?? const NicknameStatus();
        if (!status.hasNickname) {
          return NicknameSetupScreen(
            status: status,
            isInitialSetup: true,
            onSaved: () {
              setState(_refresh);
            },
          );
        }
        return const AppShell();
      },
    );
  }
}
