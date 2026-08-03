/// Riverpod providers for the update-checking feature.
///
/// Exposes:
/// - [updateCheckProvider]: fetches the latest GitHub release (auto-disposes).
/// - [updateAvailableProvider]: true when a newer release exists.
/// - [downloadAndInstall]: downloads the APK and launches the installer.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'github_release.dart';
import 'update_checker.dart';

/// Dio client for GitHub API (plain, no insecure-TLS adapter).
final _githubDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

/// Fetches the latest release from GitHub. Auto-disposes when unused.
///
/// Returns null on 404, network error, or rate-limit — the Settings screen
/// treats null as "update check failed / no release".
final updateCheckProvider = FutureProvider.autoDispose<GithubRelease?>((ref) async {
  final dio = ref.watch(_githubDioProvider);
  return fetchLatestRelease(dio);
});

/// True when a newer release is available on GitHub.
///
/// Watches [updateCheckProvider], then compares the installed version
/// against the release tag. Returns false if the check failed or no release.
final updateAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final release = await ref.watch(updateCheckProvider.future);
  if (release == null) {
    return false;
  }
  final installed = await currentVersion();
  return isNewerRelease(installed, release.tagName);
});

/// Downloads the APK from the release and launches the system installer.
///
/// - Downloads to a temp file via [getTemporaryDirectory].
/// - Uses a plain Dio (no insecure-TLS) with progress callback (ignored here).
/// - On success, calls [OpenFilex.open] to launch the Android package installer.
/// - On failure, rethrows a descriptive [Exception].
Future<void> downloadAndInstall(GithubRelease release) async {
  final asset = release.apkAsset;
  if (asset == null) {
    throw Exception('No APK asset found in release ${release.tagName}');
  }

  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/${asset.name}';

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  try {
    await dio.download(
      asset.browserDownloadUrl,
      filePath,
      onReceiveProgress: (received, total) {
        // Progress available for UI if needed; ignored here.
      },
    );
  } on DioException catch (e) {
    throw Exception('Download failed: ${e.message}');
  }

  final result = await OpenFilex.open(filePath);
  if (result.type != ResultType.done) {
    throw Exception('Failed to launch installer: ${result.message}');
  }
}