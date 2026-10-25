import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../error/app_exception.dart';

/// Central HTTP client — the ONLY place that touches `package:http`.
///
/// Responsibilities (ARCHITECTURE.md §4):
/// - JSON encode/decode + consistent `{success,message,data,error}` parsing
/// - timeout, network-error mapping to [AppException]
/// - meaningful HTTP status mapping (API_CONTRACT.md §5)
///
/// UI and repositories must use this, never `http` directly.
/// Central HTTP client — the ONLY place that touches `package:http`.
///
/// Responsibilities (ARCHITECTURE.md §4):
/// - JSON encode/decode + consistent `{success,message,data,error}` parsing
/// - timeout, network-error mapping to [AppException]
/// - meaningful HTTP status mapping (API_CONTRACT.md §5)
///
/// UI and repositories must use this, never `http` directly.
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  ApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _http = httpClient ?? http.Client();

  /// URL default: port 8081 sesuai docker-compose.yml.
  /// Android emulator: http://10.0.2.2:8081/koperasi_siswa
  /// iOS emulator: http://10.0.3.2:8081/koperasi_siswa
  ///
  /// Build APK pakai --dart-define (bakar ke binary, jalan di device):
  ///   flutter build apk --release --dart-define=BACKEND_URL=https://`<host>`/koperasi_siswa
  static String _defaultBaseUrl() {
    const defined = String.fromEnvironment('BACKEND_URL');
    if (defined.isNotEmpty) return defined;
    final env = Platform.environment['FLUTTER_BACKEND_URL'];
    if (env != null && env.isNotEmpty) return env;
    return 'http://10.0.2.2:8081/koperasi_siswa';
  }

  Uri uri(String path, [Map<String, String>? query]) {
    final base = path.startsWith('http') ? path : '$baseUrl$path';
    final u = Uri.parse(base);
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: {...u.queryParameters, ...query});
  }

  Map<String, dynamic> _decode(String body, int statusCode) {
    if (body.isEmpty) {
      throw AppException(
        'Server mengembalikan respons kosong (HTTP $statusCode).',
        code: 'EMPTY_RESPONSE',
        statusCode: statusCode,
      );
    }
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw AppException(
        'Respons server tidak valid (HTTP $statusCode).',
        code: 'INVALID_RESPONSE',
        statusCode: statusCode,
      );
    }
  }

  Never _throwForEnvelope(Map<String, dynamic> d, int statusCode) {
    if (d['success'] == true) {
      throw StateError('Envelope sukses tidak boleh dilempar sebagai error');
    }
    final msg = d['message']?.toString() ?? 'Terjadi kesalahan.';
    final err = d['error'];
    Map<String, String> fields = const {};
    String code = 'REQUEST_FAILED';
    if (err is Map) {
      code = err['code']?.toString() ?? code;
      final f = err['fields'];
      if (f is Map) {
        fields = f.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    if (statusCode == 401) throw AppException.unauthorized(msg);
    if (statusCode == 422) throw AppException.validation(msg, fields);
    throw AppException(msg, code: code, statusCode: statusCode, fields: fields);
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String>? query}) async {
    try {
      final r = await _http.get(uri(path, query)).timeout(timeout);
      final d = _decode(r.body, r.statusCode);
      if (d['success'] != true || r.statusCode >= 400) {
        _throwForEnvelope(d, r.statusCode);
      }
      return d;
    } on TimeoutException {
      throw AppException.network('timeout');
    } on SocketException catch (e) {
      throw AppException.network(e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e.toString());
    }
  }

  Future<Map<String, dynamic>> postJson(
      String path, Map<String, dynamic> body) async {
    try {
      final r = await _http
          .post(uri(path),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(timeout);
      final d = _decode(r.body, r.statusCode);
      if (d['success'] != true || r.statusCode >= 400) {
        _throwForEnvelope(d, r.statusCode);
      }
      return d;
    } on TimeoutException {
      throw AppException.network('timeout');
    } on SocketException catch (e) {
      throw AppException.network(e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e.toString());
    }
  }

  /// Multipart POST (file upload). Returns decoded envelope map.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? query,
    Map<String, String> fields = const {},
    String? fileField,
    File? file,
  }) async {
    try {
      final req = http.MultipartRequest('POST', uri(path, query));
      req.fields.addAll(fields);
      if (fileField != null && file != null) {
        req.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }
      final streamed = await _http.send(req).timeout(timeout);
      final body = await streamed.stream.bytesToString();
      final d = _decode(body, streamed.statusCode);
      if (d['success'] != true || streamed.statusCode >= 400) {
        _throwForEnvelope(d, streamed.statusCode);
      }
      return d;
    } on TimeoutException {
      throw AppException.network('timeout');
    } on SocketException catch (e) {
      throw AppException.network(e.toString());
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e.toString());
    }
  }

  void close() => _http.close();
}
