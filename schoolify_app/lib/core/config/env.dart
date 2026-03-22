/// Compile-time configuration via `--dart-define` (see README).
///
/// **Dependency:** Supabase project URL + anon key from dashboard; never commit secrets.
///
/// **Shared dev project** (use these with `--dart-define` for local / dev builds):
/// - `SUPABASE_URL=https://vmkibeakzshjchhsqokz.supabase.co`
/// - `SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZta2liZWFrenNoamNoaHNxb2t6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwOTg4MDksImV4cCI6MjA4OTY3NDgwOX0.ud8d4HjQTSLTebtiuw_iWkB1WmmF0qHAHRI7nswhWHA`
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// OneSignal App ID (safe to ship in the client). REST API key stays on the server only.
  static const String onesignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
