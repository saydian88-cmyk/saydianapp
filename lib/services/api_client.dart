import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'secure_vault.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final Object? code;

  @override
  String toString() => message;
}

class FeatureNotConfiguredException extends ApiException {
  const FeatureNotConfiguredException(super.message, {super.statusCode});
}

class BatchUploadResult {
  const BatchUploadResult({
    required this.acceptedIds,
    required this.rejected,
    required this.nextCursor,
  });

  final Set<String> acceptedIds;
  final Map<String, String> rejected;
  final String? nextCursor;
}

abstract interface class SaydianApi {
  Future<Session> login(String username, String password);
  Future<Session> register(String mobile, String password);
  Future<List<Map<String, Object?>>> getCareMembers();
  Future<Map<String, Object?>> addCare(String mobile);
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch);
  Future<void> logout();
  Future<void> deleteAccount();
}

class SaydianApiClient implements SaydianApi {
  SaydianApiClient(this._vault, {http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri =
          baseUri ??
          Uri.parse(
            const String.fromEnvironment(
              'SAYDIAN_API_BASE_URL',
              defaultValue: 'https://app.saidian.cc',
            ),
          );

  final SessionVault _vault;
  final http.Client _client;
  final Uri _baseUri;

  Uri _uri(String path, [Map<String, String>? query]) =>
      _baseUri.resolve(path).replace(queryParameters: query);

  @override
  Future<Session> login(String username, String password) => _authenticate(
    '/api/v1/site/login',
    {'username': username, 'password': password, 'group': 'app'},
  );

  @override
  Future<Session> register(String mobile, String password) => _authenticate(
    '/api/v1/site/register',
    {'mobile': mobile, 'password': password, 'group': 'app'},
  );

  Future<Session> _authenticate(String path, Map<String, String> fields) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields);
    final response = await http.Response.fromStream(await _client.send(request));
    final payload = _decode(response);
    final data = _data(payload);
    final member = data['member'];
    final memberMap = member is Map ? member : const <Object?, Object?>{};
    final expiresIn = (data['expiration_time'] as num?)?.toInt() ?? 43200;
    final session = Session(
      accessToken: '${data['access_token'] ?? ''}',
      refreshToken: '${data['refresh_token'] ?? ''}',
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
      memberId: '${memberMap['id'] ?? ''}',
      displayName:
          '${memberMap['nickname'] ?? memberMap['username'] ?? '赛电用户'}',
    );
    if (session.accessToken.isEmpty) {
      throw const ApiException('登录响应缺少 access_token');
    }
    await _vault.writeSession(session);
    return session;
  }

  @override
  Future<List<Map<String, Object?>>> getCareMembers() async {
    final response = await _authorizedGet('/api/v1/member/care');
    final payload = _decode(response);
    final data = payload['data'];
    final rawList = data is List
        ? data
        : data is Map && data['list'] is List
        ? data['list'] as List
        : const [];
    return rawList
        .whereType<Map>()
        .map((value) => value.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  @override
  Future<Map<String, Object?>> addCare(String mobile) async {
    final normalized = mobile.trim();
    if (!RegExp(r'^\d{6,20}$').hasMatch(normalized)) {
      throw const ApiException('请输入正确的手机号');
    }
    final response = await _authorizedPostFields('/api/v1/member/care', {
      'mobile': normalized,
    });
    return _data(_decode(response));
  }

  @override
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch) async {
    final response = await _authorizedPostJson(
      '/api/v1/member/health-records/batch',
      batch.toJson(),
      headers: {
        'Idempotency-Key':
            '${batch.records.firstOrNull?.id ?? 'empty'}-${batch.records.length}',
      },
    );
    if (response.statusCode == 404 || response.statusCode == 405) {
      throw FeatureNotConfiguredException(
        '批量健康同步接口未配置',
        statusCode: response.statusCode,
      );
    }
    final payload = _decode(response);
    final data = _data(payload);
    final accepted = data['accepted'];
    final rejected = data['rejected'];
    return BatchUploadResult(
      acceptedIds: accepted is List
          ? accepted.map((value) => '$value').toSet()
          : batch.records.map((record) => record.id).toSet(),
      rejected: rejected is List
          ? {
              for (final item in rejected.whereType<Map>())
                '${item['id']}': '${item['reason'] ?? '未知原因'}',
            }
          : const {},
      nextCursor: data['nextCursor']?.toString(),
    );
  }

  @override
  Future<void> logout() async {
    try {
      final response = await _authorizedPostJson(
        '/api/v1/site/logout',
        const {},
      );
      if (response.statusCode == 404 || response.statusCode == 405) {
        throw FeatureNotConfiguredException(
          '服务端退出接口未配置，已仅清除本机会话',
          statusCode: response.statusCode,
        );
      }
      _decode(response);
    } finally {
      await _vault.clearSession();
    }
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _authorizedPostJson(
      '/api/v1/member/account/delete',
      const {'confirm': true},
    );
    if (response.statusCode == 404 || response.statusCode == 405) {
      throw FeatureNotConfiguredException(
        '账号注销接口未配置',
        statusCode: response.statusCode,
      );
    }
    _decode(response);
    await _vault.clearSession();
  }

  Future<http.Response> _authorizedGet(String path) async {
    final session = await _requiredSession();
    return _client.get(
      _uri(path),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
  }

  Future<http.Response> _authorizedPostJson(
    String path,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final session = await _requiredSession();
    return _client.post(
      _uri(path),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        ...headers,
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _authorizedPostFields(
    String path,
    Map<String, String> fields,
  ) async {
    final session = await _requiredSession();
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..fields.addAll(fields);
    return http.Response.fromStream(await _client.send(request));
  }

  Future<Session> _requiredSession() async {
    final session = await _vault.readSession();
    if (session == null) throw const ApiException('请先登录', statusCode: 401);
    if (session.isExpired) {
      throw const FeatureNotConfiguredException('Token 刷新接口未配置');
    }
    return session;
  }

  Map<String, Object?> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException('服务器返回了无法解析的数据', statusCode: response.statusCode);
    }
    if (decoded is! Map) {
      throw ApiException('服务器响应格式不正确', statusCode: response.statusCode);
    }
    final payload = decoded.map((key, value) => MapEntry('$key', value));
    final code = payload['code'];
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (code is num && code.toInt() != 200)) {
      throw ApiException(
        '${payload['message'] ?? '请求失败'}',
        statusCode: response.statusCode,
        code: code,
      );
    }
    return payload;
  }

  Map<String, Object?> _data(Map<String, Object?> payload) {
    final data = payload['data'];
    if (data is! Map) return <String, Object?>{};
    return data.map((key, value) => MapEntry('$key', value));
  }
}
