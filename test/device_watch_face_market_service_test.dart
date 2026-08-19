import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saydian_app/services/device_watch_face_market_service.dart';

void main() {
  test(
    'loads the W9S market profile and parses available watch faces',
    () async {
      late Uri requested;
      final service = DeviceWatchFaceMarketService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response('''
          {
            "pageIndex": 1,
            "pageCount": 14,
            "counts": 160,
            "results": [
              {
                "name": "296JL041",
                "fileLenght": 189520,
                "fileUrl": "https://www.vphband.com/themebin/watch041",
                "previewUrl": "https://www.vphband.com/themebin/watch041.png",
                "available": true
              },
              {
                "name": "disabled",
                "fileLenght": 100,
                "fileUrl": "https://www.vphband.com/themebin/disabled",
                "previewUrl": "https://www.vphband.com/themebin/disabled.png",
                "available": false
              }
            ]
          }
        ''', 200);
        }),
      );

      final result = await service.loadPage();

      expect(requested.host, 'www.vphband.com');
      expect(requested.queryParameters['dialShape'], '56');
      expect(requested.queryParameters['binProtocol'], '2');
      expect(requested.queryParameters['deviceNumber'], '6702');
      expect(requested.queryParameters['deviceVersion'], '11.95.01.00');
      expect(result.pageCount, 14);
      expect(result.total, 160);
      expect(result.items, hasLength(1));
      expect(result.items.single.name, '296JL041');
      expect(result.items.single.fileLength, 189520);
    },
  );

  test('reports malformed market responses as a user facing error', () async {
    final service = DeviceWatchFaceMarketService(
      client: MockClient((_) async => http.Response('not-json', 200)),
    );

    await expectLater(
      service.loadPage(),
      throwsA(
        isA<DeviceWatchFaceMarketException>().having(
          (error) => error.message,
          'message',
          contains('无法识别'),
        ),
      ),
    );
  });
}
