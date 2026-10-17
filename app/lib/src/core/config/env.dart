/// Environment configuration — single source of truth for base URL.
///
/// Priority: `--dart-define=API_BASE_URL=...` > default localhost.
/// Examples:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.100.12/koperasi_siswa
///   flutter build apk --release --dart-define=API_BASE_URL=https://koperasi.sekolah.id
///
/// ARCHITECTURE.md §7: environment-specific values must not live in business code.
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/koperasi_siswa',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProd => appEnv == 'prod';
}
