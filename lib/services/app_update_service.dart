import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUri,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final Uri downloadUri;
  final String releaseNotes;
  final bool forceUpdate;

  bool get hasUpdate =>
      latestBuild > currentBuild ||
      (latestBuild == currentBuild &&
          _compareVersions(latestVersion, currentVersion) > 0);
}

class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    Uri? manifestUri,
    TargetPlatform? targetPlatform,
    Future<PackageInfo> Function()? packageInfoLoader,
  }) : _client = client ?? http.Client(),
       _manifestUri = manifestUri ?? _configuredManifestUri(),
       _targetPlatform = targetPlatform ?? defaultTargetPlatform,
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final http.Client _client;
  final Uri? _manifestUri;
  final TargetPlatform _targetPlatform;
  final Future<PackageInfo> Function() _packageInfoLoader;

  bool get isConfigured => _manifestUri != null;

  Future<AppUpdateInfo> check() async {
    final manifestUri = _manifestUri;
    if (manifestUri == null) {
      throw const AppUpdateException('在线更新服务暂未配置');
    }
    if (manifestUri.scheme != 'https') {
      throw const AppUpdateException('更新地址必须使用 HTTPS');
    }

    final response = await _client
        .get(manifestUri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AppUpdateException('暂时无法获取版本信息');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const AppUpdateException('版本信息格式不正确');
    }
    final root = decoded.map((key, value) => MapEntry('$key', value));
    final data = root['data'] is Map
        ? (root['data'] as Map).map((key, value) => MapEntry('$key', value))
        : root;
    final platformKey = switch (_targetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => throw const AppUpdateException('当前平台不支持在线更新'),
    };
    final platformData = data[platformKey] is Map
        ? (data[platformKey] as Map).map(
            (key, value) => MapEntry('$key', value),
          )
        : data;
    final latestVersion =
        '${platformData['version'] ?? platformData['latest_version'] ?? ''}'
            .trim();
    final latestBuild = _asInt(
      platformData['build'] ??
          platformData['build_number'] ??
          platformData['version_code'],
    );
    final downloadUrl =
        '${platformData['download_url'] ?? platformData['url'] ?? ''}'.trim();
    final downloadUri = Uri.tryParse(downloadUrl);
    if (latestVersion.isEmpty || latestBuild <= 0 || downloadUri == null) {
      throw const AppUpdateException('版本信息缺少版本号或下载地址');
    }
    if (downloadUri.scheme != 'https') {
      throw const AppUpdateException('下载地址必须使用 HTTPS');
    }

    final package = await _packageInfoLoader();
    return AppUpdateInfo(
      currentVersion: package.version,
      currentBuild: int.tryParse(package.buildNumber) ?? 0,
      latestVersion: latestVersion,
      latestBuild: latestBuild,
      downloadUri: downloadUri,
      releaseNotes:
          '${platformData['release_notes'] ?? platformData['notes'] ?? ''}'
              .trim(),
      forceUpdate:
          platformData['force_update'] == true ||
          platformData['force'] == true ||
          '${platformData['force_update']}' == '1',
    );
  }

  Future<void> openDownload(AppUpdateInfo info) async {
    if (!await launchUrl(
      info.downloadUri,
      mode: LaunchMode.externalApplication,
    )) {
      throw const AppUpdateException('无法打开安全下载地址');
    }
  }

  static Uri? _configuredManifestUri() {
    const value = String.fromEnvironment('SAYDIAN_UPDATE_MANIFEST_URL');
    if (value.trim().isEmpty) return null;
    return Uri.tryParse(value.trim());
  }
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}'.trim()) ?? 0;

int _compareVersions(String left, String right) {
  final a = left.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final b = right.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final length = a.length > b.length ? a.length : b.length;
  for (var index = 0; index < length; index++) {
    final av = index < a.length ? a[index] : 0;
    final bv = index < b.length ? b[index] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}
