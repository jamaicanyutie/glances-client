/// Core update-checking logic: fetch latest GitHub release, compare versions.
///
/// Pure functions (no Riverpod) so they can be unit-tested in isolation.
library;

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'github_release.dart';

/// GitHub repository to query for releases.
const String kGithubRepo = 'jamaicanyutie/glances-client';

/// Fetches the latest release from GitHub.
///
/// Returns [GithubRelease] on 200, null on 404 (no releases), null on any
/// [DioException] (offline, rate-limit, etc.). Never throws.
Future<GithubRelease?> fetchLatestRelease(Dio dio) async {
  try {
    final response = await dio.get(
      'https://api.github.com/repos/$kGithubRepo/releases/latest',
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        validateStatus: (status) => status == 200 || status == 404,
      ),
    );

    if (response.statusCode == 404) {
      return null;
    }

    return GithubRelease.fromJson(response.data as Map<String, dynamic>);
  } on DioException {
    // Offline, rate-limited, timeout, etc. — caller treats as 'check failed'.
    return null;
  }
}

/// Returns the installed app version as 'version+buildNumber' (e.g. '1.0.0+1').
Future<String> currentVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return '${packageInfo.version}+${packageInfo.buildNumber}';
}

/// Parses a semver-ish string into (major, minor, patch, build).
///
/// Handles both 'v1.2.3' (tag format) and '1.2.3+4' (installed format).
/// Leading 'v' is stripped. Missing build defaults to 0.
({int major, int minor, int patch, int build}) _parseVersion(String v) {
  var s = v.trim();
  if (s.startsWith('v')) {
    s = s.substring(1);
  }
  var build = 0;
  if (s.contains('+')) {
    final parts = s.split('+');
    s = parts[0];
    build = int.tryParse(parts[1]) ?? 0;
  }
  final versionParts = s.split('.');
  final major = int.tryParse(versionParts[0]) ?? 0;
  final minor = versionParts.length > 1 ? int.tryParse(versionParts[1]) ?? 0 : 0;
  final patch = versionParts.length > 2 ? int.tryParse(versionParts[2]) ?? 0 : 0;
  return (major: major, minor: minor, patch: patch, build: build);
}

/// Returns true if [tagName] represents a newer release than [installedVersion].
///
/// Compares major.minor.patch numerically; if equal, compares build numbers.
/// Pure function, no async.
bool isNewerRelease(String installedVersion, String tagName) {
  final installed = _parseVersion(installedVersion);
  final tag = _parseVersion(tagName);

  if (tag.major != installed.major) return tag.major > installed.major;
  if (tag.minor != installed.minor) return tag.minor > installed.minor;
  if (tag.patch != installed.patch) return tag.patch > installed.patch;
  return tag.build > installed.build;
}