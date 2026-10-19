/// Model error klien: [message] aman ditampilkan ke user, [code] untuk penanganan program.
class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => message;
}
