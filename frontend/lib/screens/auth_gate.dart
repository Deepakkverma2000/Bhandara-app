import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'blocked_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  bool _checkingBlockStatus = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _syncSession();
    Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthStateChange);
    AuthService.instance.addListener(_syncSession);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_syncSession);
    super.dispose();
  }

  void _onAuthStateChange(AuthState data) {
    if (!mounted) return;
    _applySession(data.session);
  }

  void _syncSession() {
    if (!mounted) return;
    _applySession(Supabase.instance.client.auth.currentSession);
  }

  void _applySession(Session? session) {
    final signedOut = session == null;

    setState(() {
      _session = session;
      if (signedOut) {
        _isBlocked = false;
        _checkingBlockStatus = false;
      }
    });

    if (signedOut) {
      NotificationService.instance.resetForSignOut();
      return;
    }

    _refreshBlockStatus();
    NotificationService.instance.initialize();
  }

  Future<void> _refreshBlockStatus() async {
    if (_session == null) return;

    setState(() => _checkingBlockStatus = true);

    try {
      final blocked = await AuthService.instance.isCurrentUserBlocked();
      if (!mounted || _session == null) return;
      setState(() {
        _isBlocked = blocked;
        _checkingBlockStatus = false;
      });
    } catch (_) {
      if (mounted && _session != null) {
        setState(() => _checkingBlockStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginScreen(key: ValueKey('login'));
    }

    if (_checkingBlockStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isBlocked) {
      return const BlockedScreen(key: ValueKey('blocked'));
    }

    return const MainShell(key: ValueKey('main'));
  }
}
