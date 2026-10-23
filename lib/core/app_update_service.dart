import 'dart:convert';
import 'package:http/http.dart' as http;

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.parts, this.build);
  final List<int> parts;
  final int build;
  factory AppVersion.parse(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$').firstMatch(value.trim());
    if (match == null) throw const FormatException('Invalid app version');
    return AppVersion([for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)], int.parse(match.group(4) ?? '0'));
  }
  @override
  int compareTo(AppVersion other) {
    for (var i = 0; i < 3; i++) {
      final difference = parts[i].compareTo(other.parts[i]);
      if (difference != 0) return difference;
    }
    return build.compareTo(other.build);
  }
}
class AppUpdateResult {
  const AppUpdateResult({required this.newer, required this.version, required this.apkUrl});
  final bool newer;
  final String version;
  final Uri apkUrl;
}
class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final latest = Uri.parse('https://api.github.com/repos/frances09f-lgtm/jobpilot-ai/releases/latest');
  void close() => _client.close();
  static Uri trustedAsset(String value, {required String name}) {
    final uri = Uri.parse(value);
    final prefix = '/frances09f-lgtm/jobpilot-ai/releases/download/';
    if (uri.scheme != 'https' || uri.host != 'github.com' || uri.userInfo.isNotEmpty || !uri.path.startsWith(prefix) || uri.pathSegments.length != 6 || uri.pathSegments.last != name || uri.hasQuery || uri.hasFragment) throw const FormatException('Invalid release download URL');
    return uri;
  }
  Future<Map<String, dynamic>> _json(Uri url) async {
    final response = await _client.get(url, headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'JobPilot-AI'}).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw FormatException('Update check failed (HTTP ${response.statusCode}). Try again later.');
    if (response.bodyBytes.length > 200000) throw const FormatException('Invalid release data');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  Future<AppUpdateResult> check(String installed) async {
    final release = await _json(latest);
    if (release['draft'] != false || release['prerelease'] != false) throw const FormatException('No stable update available');
    final assets = (release['assets'] as List).cast<Map<String, dynamic>>();
    final apk = assets.singleWhere((asset) => asset['name'] == 'JobPilot-AI.apk');
    final apkUrl = trustedAsset(apk['browser_download_url'] as String, name: 'JobPilot-AI.apk');
    var version = release['tag_name'] as String;
    final manifests = assets.where((asset) => asset['name'] == 'jobpilot-release.json').toList();
    // The owner keeps the v0.1.0 link fixed; this versioned metadata identifies
    // the APK actually uploaded, rather than comparing the reused tag alone.
    if (manifests.isNotEmpty) {
      final url = trustedAsset(manifests.single['browser_download_url'] as String, name: 'jobpilot-release.json');
      final manifest = await _json(url);
      version = manifest['version'] as String;
      if (trustedAsset(manifest['apk_url'] as String, name: 'JobPilot-AI.apk') != apkUrl) throw const FormatException('Release metadata does not match APK');
    }
    return AppUpdateResult(newer: AppVersion.parse(version).compareTo(AppVersion.parse(installed)) > 0, version: version, apkUrl: apkUrl);
  }
}
