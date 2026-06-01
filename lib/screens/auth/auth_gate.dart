import 'package:flutter/material.dart';

import '../../models/auth_user.dart';
import '../../repositories/app_repositories.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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

        return const DashboardScreen();
      },
    );
  }
}
