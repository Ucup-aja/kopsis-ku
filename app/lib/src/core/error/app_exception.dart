/// Stable client error model — ARCHITECTURE.md §6, API_CONTRACT.md §5.
///
/// All API failures map to [AppException] with a user-safe [message],
/// machine-readable [code], HTTP [statusCode], and optional field errors.
class AppException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final Map<String, String> fields;

  const AppException(
    this.message, {
    this.code = 'UNKNOWN',
    this.statusCode,
    this.fields = const {},
  });

  factory AppException.network(String details) => AppException(
        'Tidak dapat terhubung ke server. Periksa koneksi dan alamat server.',
        code: 'NETWORK_ERROR',
        fields: {'details': details},
      );

  factory AppException.unauthorized([String? msg]) => AppException(
        msg ?? 'Sesi berakhir. Silakan masuk kembali.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory AppException.validation(String msg, [Map<String, String> fields = const {}]) =>
      AppException(msg, code: 'VALIDATION_ERROR', statusCode: 422, fields: fields);

  @override
  String toString() => message;
}
