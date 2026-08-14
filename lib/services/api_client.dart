import 'dart:async';
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
  Future<Map<String, Object?>> getCareMemberPreview({
    required int id,
    required String day,
  });
  Future<Map<String, Object?>> addCare(String mobile);
  Future<Map<String, Object?>> getMemberProfile();
  Future<void> saveMemberProfile({
    required String nickname,
    required int gender,
    required String birthday,
    required double height,
    required double weight,
    String? headPortrait,
  });
  Future<Map<String, Object?>> getActivityGoals();
  Future<void> saveActivityGoals({
    required int steps,
    required double distance,
    required int calories,
  });
  Future<List<Map<String, Object?>>> getArticles();
  Future<Map<String, Object?>> getArticle(int id);
  Future<Map<String, Object?>> getSingleArticle(int id);
  Future<List<Map<String, Object?>>> getNotifications({int page = 1});
  Future<Map<String, Object?>> getNotification(int id);
  Future<List<Map<String, Object?>>> getAiMessages({
    required int app,
    int page = 1,
  });
  Future<Map<String, Object?>> sendAiMessage({
    required int app,
    required String message,
    String? sessionId,
  });
  Future<List<Map<String, Object?>>> getOrders({int? status});
  Future<Map<String, Object?>> getOrderDetail(int id);
  Future<List<Map<String, Object?>>> getAddresses();
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch);
  Future<void> logout();
  Future<void> deleteAccount();
}

abstract interface class SaydianShopApi {
  Future<Map<String, Object?>> getShopHome();
  Future<Map<String, Object?>> getShopProduct(int id);
  Future<Map<String, Object?>> previewShopOrder({
    required int skuId,
    required int quantity,
  });
  Future<Map<String, Object?>> createShopOrder({
    required int skuId,
    required int quantity,
    required int addressId,
    String buyerMessage = '',
    num point = 0,
  });
  Future<Map<String, Object?>> getAddress(int id);
  Future<Map<String, Object?>> saveAddress({
    int? id,
    required String realname,
    required String mobile,
    required String addressDetails,
    required bool isDefault,
    required String region,
    required int provinceId,
    required int cityId,
    required int areaId,
  });
  Future<List<Map<String, Object?>>> getOrderExpress(int orderId);
}

abstract interface class SaydianCareApi {
  Future<List<Map<String, Object?>>> getCareInvitations();
  Future<void> respondCareInvitation({required int id, required bool accepted});
  Future<Set<String>> getCareShareSettings({
    required int type,
    required int memberId,
  });
  Future<void> saveCareShareSettings({
    required int type,
    required int memberId,
    required Set<String> settings,
  });
}

class SaydianApiClient implements SaydianApi, SaydianShopApi, SaydianCareApi {
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

  static const _requestTimeout = Duration(seconds: 20);

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
    final response = await _sendMultipart(request);
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
    final response = await _authorizedGet('/api/v1/member/care/my');
    Map<String, Object?> payload;
    try {
      payload = _decode(response);
    } on ApiException catch (error) {
      // The current backend can return a missing-route business code inside
      // an HTTP 200 response. Treat both transport and business 404/405 as
      // the documented optional-endpoint state so the local queue is kept.
      if (error.statusCode == 404 || error.statusCode == 405) {
        throw FeatureNotConfiguredException(
          '远程关爱接口暂未配置',
          statusCode: error.statusCode,
        );
      }
      rethrow;
    }
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
  Future<Map<String, Object?>> getMemberProfile() async {
    final response = await _authorizedGet('/api/v1/member/member/my');
    return _data(_decode(response));
  }

  @override
  Future<void> saveMemberProfile({
    required String nickname,
    required int gender,
    required String birthday,
    required double height,
    required double weight,
    String? headPortrait,
  }) async {
    final response = await _authorizedPostFields('/api/v1/member/member/save', {
      'nickname': nickname.trim(),
      'gender': '$gender',
      'birthday': birthday,
      'height': '$height',
      'weight': '$weight',
      if (headPortrait?.isNotEmpty ?? false) 'head_portrait': headPortrait!,
    });
    _decode(response);
  }

  @override
  Future<Map<String, Object?>> getActivityGoals() async {
    final response = await _authorizedGet(
      '/api/v1/member/member-mubiao/preview',
    );
    return _data(_decode(response));
  }

  @override
  Future<void> saveActivityGoals({
    required int steps,
    required double distance,
    required int calories,
  }) async {
    final response = await _authorizedPostFields(
      '/api/v1/member/member-mubiao',
      {'steps': '$steps', 'juli': '$distance', 'reliang': '$calories'},
    );
    _decode(response);
  }

  @override
  Future<List<Map<String, Object?>>> getArticles() async {
    final response = await _performRequest(
      () => _client.get(_uri('/api/rf-article/article/index')),
    );
    return _list(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getArticle(int id) async {
    final response = await _performRequest(
      () => _client.get(_uri('/api/rf-article/article/view', {'id': '$id'})),
    );
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getSingleArticle(int id) async {
    final response = await _performRequest(
      () => _client.get(
        _uri('/api/rf-article/article-single/view', {'id': '$id'}),
      ),
    );
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getNotifications({int page = 1}) async {
    final response = await _authorizedGet('/api/v1/member/notify', {
      'page': '$page',
    });
    return _list(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getNotification(int id) async {
    final response = await _authorizedGet('/api/v1/member/notify/$id');
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getAiMessages({
    required int app,
    int page = 1,
  }) async {
    final response = await _authorizedGet('/api/rf-article/chat/index', {
      'app': '$app',
      'page': '$page',
    });
    return _list(_decode(response));
  }

  @override
  Future<Map<String, Object?>> sendAiMessage({
    required int app,
    required String message,
    String? sessionId,
  }) async {
    final response =
        await _authorizedPostFields('/api/rf-article/chat/create', {
          'app': '$app',
          'message': message.trim(),
          if (sessionId?.isNotEmpty ?? false) 'session_id': sessionId!,
        });
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getOrders({int? status}) async {
    final response = await _authorizedGet(
      '/api/inv-shop/v1/member/order/index',
      {'page': '1', if (status != null) 'synthesize_status': '$status'},
    );
    return _list(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getOrderDetail(int id) async {
    final response = await _authorizedGet(
      '/api/inv-shop/v1/member/order/view',
      {'id': '$id'},
    );
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getAddresses() async {
    final response = await _authorizedGet('/api/v1/member/address', const {
      'page': '1',
    });
    return _list(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getShopHome() async {
    final response = await _performRequest(
      () => _client.get(_uri('/api/v1/pages', const {'code': 'SHOP_HOME'})),
    );
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getShopProduct(int id) async {
    final response = await _performRequest(
      () => _client.get(
        _uri('/api/inv-shop/v1/product/product/view', {'id': '$id'}),
      ),
    );
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> previewShopOrder({
    required int skuId,
    required int quantity,
  }) async {
    final data = jsonEncode({'sku_id': skuId, 'num': quantity});
    final response = await _authorizedGet(
      '/api/inv-shop/v1/order/order/preview',
      {'type': 'buy_now', 'data': data, 'is_channel': '0'},
    );
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> createShopOrder({
    required int skuId,
    required int quantity,
    required int addressId,
    String buyerMessage = '',
    num point = 0,
  }) async {
    final response = await _authorizedPostJson(
      '/api/inv-shop/v1/order/order/create',
      {
        'merchant_id': 0,
        'is_channel': 0,
        'address_id': addressId,
        'buyer_message': buyerMessage.trim(),
        'data': jsonEncode({'sku_id': skuId, 'num': quantity}),
        'shipping_type': 1,
        'type': 'buy_now',
        'point': point,
      },
    );
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> getAddress(int id) async {
    final response = await _authorizedGet('/api/v1/member/address/$id');
    return _data(_decode(response));
  }

  @override
  Future<Map<String, Object?>> saveAddress({
    int? id,
    required String realname,
    required String mobile,
    required String addressDetails,
    required bool isDefault,
    required String region,
    required int provinceId,
    required int cityId,
    required int areaId,
  }) async {
    final body = <String, Object?>{
      'realname': realname.trim(),
      'mobile': mobile.trim(),
      'address_details': addressDetails.trim(),
      'is_default': isDefault ? 1 : 0,
      'region': region,
      'province_id': provinceId,
      'city_id': cityId,
      'area_id': areaId,
    };
    final response = id == null
        ? await _authorizedPostJson('/api/v1/member/address', body)
        : await _authorizedPutJson('/api/v1/member/address/$id', body);
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getOrderExpress(int orderId) async {
    final response = await _authorizedGet(
      '/api/inv-shop/v1/member/order-product-express/details',
      {'order_id': '$orderId'},
    );
    final data = _data(_decode(response));
    final rawList = data['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map>()
        .map((value) => value.map((key, value) => MapEntry('$key', value)))
        .toList();
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
    Map<String, Object?> payload;
    try {
      payload = _decode(response);
    } on ApiException catch (error) {
      // The current backend can return a missing-route business code inside
      // an HTTP 200 response. Normalize it to the documented optional API.
      if (error.statusCode == 404 || error.statusCode == 405) {
        throw FeatureNotConfiguredException(
          '批量健康同步接口未配置',
          statusCode: error.statusCode,
        );
      }
      rethrow;
    }
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

  Future<http.Response> _authorizedGet(
    String path, [
    Map<String, String>? query,
  ]) async {
    final session = await _requiredSession();
    return _performRequest(
      () => _client.get(
        _uri(path, query),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      ),
    );
  }

  Future<http.Response> _authorizedPostJson(
    String path,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final session = await _requiredSession();
    return _performRequest(
      () => _client.post(
        _uri(path),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body),
      ),
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
    return _sendMultipart(request);
  }

  Future<http.Response> _authorizedPutJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final session = await _requiredSession();
    return _performRequest(
      () => _client.put(
        _uri(path),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _sendMultipart(http.MultipartRequest request) async {
    final streamed = await _performRequest(() => _client.send(request));
    return _performRequest(() => http.Response.fromStream(streamed));
  }

  Future<T> _performRequest<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException('网络连接超时，请检查网络后重试', code: 'NETWORK_TIMEOUT');
    } on http.ClientException {
      throw const ApiException('网络连接失败，请检查网络后重试', code: 'NETWORK_UNAVAILABLE');
    }
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
    final businessStatus = code is num && code >= 400 && code < 600
        ? code.toInt()
        : response.statusCode;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (code is num && code.toInt() != 200)) {
      throw ApiException(
        '${payload['message'] ?? '请求失败'}',
        statusCode: businessStatus,
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

  List<Map<String, Object?>> _list(Map<String, Object?> payload) {
    final data = payload['data'];
    final values = data is List
        ? data
        : data is Map && data['list'] is List
        ? data['list'] as List
        : const [];
    return values
        .whereType<Map>()
        .map((value) => value.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  @override
  Future<Map<String, Object?>> getCareMemberPreview({
    required int id,
    required String day,
  }) async {
    final response = await _authorizedGet('/api/v1/member/care/preview', {
      'id': '$id',
      'day': day,
    });
    return _data(_decode(response));
  }

  @override
  Future<List<Map<String, Object?>>> getCareInvitations() async {
    final response = await _authorizedGet('/api/v1/member/care');
    return _list(_decode(response));
  }

  @override
  Future<void> respondCareInvitation({
    required int id,
    required bool accepted,
  }) async {
    final response = await _authorizedPostFields('/api/v1/member/care/save', {
      'id': '$id',
      'examine_status': accepted ? '1' : '2',
    });
    _decode(response);
  }

  @override
  Future<Set<String>> getCareShareSettings({
    required int type,
    required int memberId,
  }) async {
    final response = await _authorizedGet(
      '/api/v1/member/care-setting/preview',
      {'type': '$type', 'to_member_id': '$memberId'},
    );
    final data = _data(_decode(response));
    final raw = data['setting'];
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        decoded = const <Object?>[];
      }
    }
    return decoded is List ? decoded.map((value) => '$value').toSet() : {};
  }

  @override
  Future<void> saveCareShareSettings({
    required int type,
    required int memberId,
    required Set<String> settings,
  }) async {
    final response =
        await _authorizedPostFields('/api/v1/member/care-setting', {
          'type': '$type',
          'to_member_id': '$memberId',
          'setting': jsonEncode(settings.toList()..sort()),
        });
    _decode(response);
  }
}
