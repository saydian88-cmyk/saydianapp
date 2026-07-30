import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/secure_vault.dart';

void main() {
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
}
