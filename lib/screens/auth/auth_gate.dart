import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth_user.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_shell.dart';
import '../login/login_screen.dart';

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

        return const AppShell();
      },
    );
  }
}
