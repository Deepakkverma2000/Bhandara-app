import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'blocked_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingBlockStatus = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _refreshBlockStatus();
    AuthService.instance.authStateChanges.listen((_) {
      _refreshBlockStatus();
    });
  }

  Future<void> _refreshBlockStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        setState(() {
          _isBlocked = false;
          _checkingBlockStatus = false;
        });
      }
      return;
    }

    setState(() => _checkingBlockStatus = true);

    try {
      final blocked = await AuthService.instance.isCurrentUserBlocked();
      if (mounted) {
        setState(() {
          _isBlocked = blocked;
          _checkingBlockStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingBlockStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        if (_checkingBlockStatus) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_isBlocked) {
          return const BlockedScreen();
        }

        return const MainShell();
      },
    );
  }
}
