import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saydian_app/services/app_update_service.dart';

void main() {
  PackageInfo package(String version, String build) => PackageInfo(
    appName: '赛电健康',
    packageName: 'com.saydian.app',
    version: version,
    buildNumber: build,
  );

  test(
    'iOS update manifest selects iOS values and detects a newer build',
    () async {
      final service = AppUpdateService(
        manifestUri: Uri.parse('https://app.saidian.cc/update.json'),
        targetPlatform: TargetPlatform.iOS,
        packageInfoLoader: () async => package('0.1.12', '14'),
        client: MockClient(
          (_) async => http.Response(
            '''
          {
            "android": {
              "version": "9.0.0",
              "build": 900,
              "download_url": "https://example.com/android"
            },
            "ios": {
              "version": "0.1.13",
              "build": 15,
              "download_url": "https://apps.apple.com/app/id123",
              "release_notes": "iOS 兼容性优化"
            }
          }
        ''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      final info = await service.check();

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '0.1.13');
      expect(info.latestBuild, 15);
      expect(info.releaseNotes, 'iOS 兼容性优化');
    },
  );

  test('same build and version is current', () async {
    final service = AppUpdateService(
      manifestUri: Uri.parse('https://app.saidian.cc/update.json'),
      targetPlatform: TargetPlatform.android,
      packageInfoLoader: () async => package('1.2.3', '20'),
      client: MockClient(
        (_) async => http.Response(
          '{"version":"1.2.3","build":20,'
          '"download_url":"https://app.saidian.cc/app.apk"}',
          200,
        ),
      ),
    );

    expect((await service.check()).hasUpdate, isFalse);
  });

  test(
    'default update endpoint is configured and insecure URLs are rejected',
    () async {
      final configured = AppUpdateService(targetPlatform: TargetPlatform.iOS);
      final insecure = AppUpdateService(
        manifestUri: Uri.parse('http://app.saidian.cc/update.json'),
        targetPlatform: TargetPlatform.iOS,
      );

      expect(configured.isConfigured, isTrue);
      await expectLater(insecure.check(), throwsA(isA<AppUpdateException>()));
    },
  );

  test('GitHub release response selects the Android APK', () async {
    final service = AppUpdateService(
      manifestUri: Uri.parse(
        'https://api.github.com/repos/saydian88-cmyk/saydianapp/releases/latest',
      ),
      targetPlatform: TargetPlatform.android,
      packageInfoLoader: () async => package('0.1.17', '21'),
      client: MockClient(
        (_) async => http.Response(
          '''
          {
            "tag_name":"android-v0.1.18+22",
            "body":"修复设备测量与商城流程",
            "assets":[{
              "name":"Saydian-0.1.18+22-release.apk",
              "browser_download_url":"https://github.com/saydian/app.apk"
            }]
          }
          ''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    final info = await service.check();
    expect(info.hasUpdate, isTrue);
    expect(info.latestVersion, '0.1.18');
    expect(info.latestBuild, 22);
    expect(info.releaseNotes, contains('设备测量'));
  });
}
