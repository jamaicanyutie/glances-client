/// Data models for GitHub release information.
///
/// Hand-written fromJson (no json_serializable) to avoid build_runner.
library;

class GithubAsset {
  const GithubAsset({
    required this.name,
    required this.browserDownloadUrl,
    this.size,
  });

  final String name;
  final String browserDownloadUrl;
  final int? size;

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      name: json['name'] as String,
      browserDownloadUrl: json['browser_download_url'] as String,
      size: json['size'] as int?,
    );
  }
}

class GithubRelease {
  const GithubRelease({
    required this.tagName,
    required this.name,
    this.publishedAt,
    required this.assets,
  });

  final String tagName;
  final String name;
  final String? publishedAt;
  final List<GithubAsset> assets;

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    final assetsJson = json['assets'] as List<dynamic>? ?? const [];
    return GithubRelease(
      tagName: json['tag_name'] as String,
      name: json['name'] as String,
      publishedAt: json['published_at'] as String?,
      assets: assetsJson
          .map((e) => GithubAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the first asset ending with '.apk', or null if none.
  GithubAsset? get apkAsset {
    for (final asset in assets) {
      if (asset.name.endsWith('.apk')) {
        return asset;
      }
    }
    return null;
  }
}
