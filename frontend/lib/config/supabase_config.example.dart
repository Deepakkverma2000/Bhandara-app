/// Copy this file to `supabase_config.dart` and fill in your values.
/// Do not commit `supabase_config.dart` — it is gitignored.
class SupabaseConfig {
  static const url = 'https://YOUR_PROJECT_ID.supabase.co';

  static const anonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Google Cloud → Credentials → OAuth 2.0 → type **Web application** (NOT Android).
  /// Must match exactly: Supabase Dashboard → Authentication → Providers → Google → Client ID.
  static const googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
}
