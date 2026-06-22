import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Session? get session => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String? get displayName {
    final user = currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata;
    return metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user.email?.split('@').first;
  }

  String? get email => currentUser?.email;

  String? get avatarUrl {
    final user = currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata;
    return metadata?['avatar_url'] as String? ?? metadata?['picture'] as String?;
  }

  GoogleSignIn _googleSignIn() {
    return GoogleSignIn(
      serverClientId: SupabaseConfig.googleWebClientId,
      scopes: const ['email', 'profile'],
    );
  }

  Future<void> signInWithGoogle() async {
    if (SupabaseConfig.googleWebClientId.contains('PASTE_YOUR_WEB_CLIENT_ID')) {
      throw Exception(
        'Add your Web OAuth Client ID (not Android) in lib/config/supabase_config.dart',
      );
    }

    final googleSignIn = _googleSignIn();

    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception(
        'Google did not return an ID token. Use the Web client ID in supabase_config.dart and check SHA-1.',
      );
    }

    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      notifyListeners();
    } on AuthException catch (error) {
      if (error.message.contains('Unacceptable audience')) {
        throw Exception(
          'Wrong Google Client ID. In supabase_config.dart use the Web application client ID '
          '(not the Android client ID). It must match Supabase → Auth → Google → Client ID exactly.',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn().signOut();
    } catch (_) {}

    await _client.auth.signOut(scope: SignOutScope.global);

    if (_client.auth.currentSession != null) {
      await _client.auth.signOut(scope: SignOutScope.local);
    }

    notifyListeners();
  }

  Future<bool> isCurrentUserBlocked() async {
    final user = currentUser;
    if (user == null) return false;

    final data = await _client
        .from('users')
        .select('is_blocked')
        .eq('id', user.id)
        .maybeSingle();

    return data?['is_blocked'] == true;
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final data = await _client
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

    return data?['is_admin'] == true;
  }
}
