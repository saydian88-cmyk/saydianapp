import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/secure_vault.dart';

void main() {
  test('care member list uses the mini-program member endpoint', () async {
    final vault = MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/member/care/my');
      return http.Response('{"code":200,"data":[]}', 200);
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(await api.getCareMembers(), isEmpty);
  });

  test('add care uses authenticated multipart mobile contract', () async {
    final vault = MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/member/care');
      expect(request.headers['authorization'], 'Bearer test-access-token');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data;'),
      );
      expect(request.body, contains('name="mobile"'));
      expect(request.body, contains('13800138000'));
      return http.Response(
        '{"code":200,"message":"成功","data":{"id":9,"member_id":1,"to_member_id":2}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    final result = await api.addCare('13800138000');

    expect(result['id'], 9);
    expect(result['to_member_id'], 2);
  });

  test('add care rejects malformed mobile before making a request', () async {
    final api = SaydianApiClient(
      MemorySessionVault(),
      client: MockClient((_) async => fail('request should not be sent')),
    );

    expect(() => api.addCare('abc'), throwsA(isA<ApiException>()));
  });

  test('business error code is preserved when HTTP status is 200', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"code":401,"message":"Unauthorized","data":{}}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    await expectLater(
      api.getCareMembers(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.code, 'code', 401),
      ),
    );
  });

  test(
    'missing health batch endpoint is reported as not configured when HTTP is 200',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/member/health-records/batch');
        return http.Response(
          '{"code":404,"message":"页面未找到。","data":{}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = SaydianApiClient(
        _authenticatedVault(),
        client: client,
        baseUri: Uri.parse('https://example.invalid'),
      );
      final record = HealthRecord(
        id: 'record-1',
        metric: HealthMetric.heartRate,
        values: const {'value': 72},
        unit: 'bpm',
        measuredAt: DateTime.utc(2026, 8, 13),
        timezone: '+08:00',
        deviceId: 'ET488',
        firmwareVersion: '1.0.0',
        quality: 'good',
        source: MeasurementSource.wearable,
        rawVersion: 1,
      );

      await expectLater(
        api.uploadHealthBatch(SyncBatch(cursor: null, records: [record])),
        throwsA(
          isA<FeatureNotConfiguredException>().having(
            (error) => error.message,
            'message',
            '批量健康同步接口未配置',
          ),
        ),
      );
    },
  );

  test('health encyclopedia uses the mini-program public endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/rf-article/article/index');
      return http.Response(
        '{"code":200,"data":[{"id":3,"title":"健康百科"}]}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = SaydianApiClient(
      MemorySessionVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    final articles = await api.getArticles();

    expect(articles.single['id'], 3);
  });

  test('network failures are normalized to an offline ApiException', () async {
    final api = SaydianApiClient(
      MemorySessionVault(),
      client: MockClient(
        (request) async =>
            throw http.ClientException('Failed host lookup', request.url),
      ),
      baseUri: Uri.parse('https://example.invalid'),
    );

    await expectLater(
      api.getArticles(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'NETWORK_UNAVAILABLE')
            .having((error) => error.message, 'message', '网络连接失败，请检查网络后重试'),
      ),
    );
  });

  test('privacy agreement uses the single-article endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/rf-article/article-single/view');
      expect(request.url.queryParameters['id'], '3');
      return http.Response(
        '{"code":200,"data":{"id":3,"title":"隐私协议"}}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = SaydianApiClient(
      MemorySessionVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect((await api.getSingleArticle(3))['title'], '隐私协议');
  });

  test('orders send the authenticated synthesize status contract', () async {
    final vault = MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/inv-shop/v1/member/order/index');
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['synthesize_status'], '2');
      expect(request.headers['authorization'], 'Bearer test-access-token');
      return http.Response('{"code":200,"data":[]}', 200);
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(await api.getOrders(status: 2), isEmpty);
  });

  test('all orders omit the synthesize status filter', () async {
    final vault = MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
    final client = MockClient((request) async {
      expect(request.url.path, '/api/inv-shop/v1/member/order/index');
      expect(
        request.url.queryParameters.containsKey('synthesize_status'),
        isFalse,
      );
      return http.Response('{"code":200,"data":[]}', 200);
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(await api.getOrders(), isEmpty);
  });

  test('shop home uses the public SHOP_HOME page contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/pages');
      expect(request.url.queryParameters['code'], 'SHOP_HOME');
      expect(request.headers.containsKey('authorization'), isFalse);
      return http.Response(
        '{"code":200,"data":{"items":[{"type":"tabs"}]}}',
        200,
      );
    });
    final api = SaydianApiClient(
      MemorySessionVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect((await api.getShopHome())['items'], isA<List>());
  });

  test('order preview sends the mini-program buy-now query contract', () async {
    final vault = _authenticatedVault();
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/inv-shop/v1/order/order/preview');
      expect(request.url.queryParameters['type'], 'buy_now');
      expect(request.url.queryParameters['is_channel'], '0');
      expect(jsonDecode(request.url.queryParameters['data']!), {
        'sku_id': 2975,
        'num': 2,
      });
      expect(request.headers['authorization'], 'Bearer test-access-token');
      return http.Response('{"code":200,"data":{"products":[]}}', 200);
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(
      await api.previewShopOrder(skuId: 2975, quantity: 2),
      contains('products'),
    );
  });

  test('create order sends the confirmed JSON checkout contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/inv-shop/v1/order/order/create');
      expect(request.headers['authorization'], 'Bearer test-access-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['address_id'], 8);
      expect(body['shipping_type'], 1);
      expect(body['type'], 'buy_now');
      expect(body['buyer_message'], '请尽快发货');
      expect(jsonDecode(body['data'] as String), {'sku_id': 2975, 'num': 2});
      return http.Response('{"code":200,"data":{"id":99}}', 200);
    });
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    final order = await api.createShopOrder(
      skuId: 2975,
      quantity: 2,
      addressId: 8,
      buyerMessage: '请尽快发货',
    );
    expect(order['id'], 99);
  });

  test('address create uses authenticated JSON region fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/member/address');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['realname'], '张三');
      expect(body['province_id'], 440000);
      expect(body['city_id'], 440300);
      expect(body['area_id'], 440305);
      expect(body['is_default'], 1);
      return http.Response('{"code":200,"data":{"id":8}}', 200);
    });
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(
      (await api.saveAddress(
        realname: '张三',
        mobile: '13800138000',
        addressDetails: '科技园 1 号',
        isDefault: true,
        region: '广东省 深圳市 南山区',
        provinceId: 440000,
        cityId: 440300,
        areaId: 440305,
      ))['id'],
      8,
    );
  });

  test('activity goals use the confirmed multipart field names', () async {
    final vault = MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/member/member-mubiao');
      expect(request.headers['authorization'], 'Bearer test-access-token');
      expect(request.body, contains('name="steps"'));
      expect(request.body, contains('10000'));
      expect(request.body, contains('name="juli"'));
      expect(request.body, contains('6.5'));
      expect(request.body, contains('name="reliang"'));
      expect(request.body, contains('800'));
      return http.Response('{"code":200,"data":{}}', 200);
    });
    final api = SaydianApiClient(
      vault,
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    await api.saveActivityGoals(steps: 10000, distance: 6.5, calories: 800);
  });

  test('care invitation response uses the prototype status contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/member/care/save');
      expect(request.body, contains('name="id"'));
      expect(request.body, contains('19'));
      expect(request.body, contains('name="examine_status"'));
      expect(request.body, contains('2'));
      return http.Response('{"code":200,"data":{}}', 200);
    });
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    await api.respondCareInvitation(id: 19, accepted: false);
  });

  test('care share settings decode the server JSON list', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/member/care-setting/preview');
      expect(request.url.queryParameters, {'type': '2', 'to_member_id': '7'});
      return http.Response(
        '{"code":200,"data":{"setting":"[\\"heart_rate\\",\\"sleep\\"]"}}',
        200,
      );
    });
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    expect(await api.getCareShareSettings(type: 2, memberId: 7), {
      'heart_rate',
      'sleep',
    });
  });

  test('care share settings save a stable sorted JSON list', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/member/care-setting');
      expect(request.body, contains('name="type"'));
      expect(request.body, contains('name="to_member_id"'));
      expect(request.body, contains('["heart_rate","sleep"]'));
      return http.Response('{"code":200,"data":{}}', 200);
    });
    final api = SaydianApiClient(
      _authenticatedVault(),
      client: client,
      baseUri: Uri.parse('https://example.invalid'),
    );

    await api.saveCareShareSettings(
      type: 2,
      memberId: 7,
      settings: {'sleep', 'heart_rate'},
    );
  });
}

MemorySessionVault _authenticatedVault() =>
    MemorySessionVault()
      ..session = Session(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        memberId: '1',
        displayName: '测试用户',
      );
