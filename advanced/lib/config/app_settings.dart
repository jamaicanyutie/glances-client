import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default poll cadence for the live dashboard (matches the Glances server's
/// ~1 s snapshot rate without hammering the host).
const int kDefaultPollingIntervalSeconds = 2;

/// Default re-fetch cadence for the CPU history chart.
const int kDefaultHistoryRefreshIntervalSeconds = 5;

/// Immutable user configuration persisted in [SharedPreferences].
///
/// [serverUrl] is null until the user has configured a Glances server — the
/// app then shows the first-run hint on the Home screen ("Open settings").
class AppSettings {
  const AppSettings({
    required this.serverUrl,
    required this.allowInsecureTls,
    required this.pollingIntervalSeconds,
    required this.historyRefreshIntervalSeconds,
  });

  /// Defaults used on first launch: no server configured, TLS verification
  /// relaxed (Tailscale / self-signed LAN certificates), 2 s poll.
  factory AppSettings.defaults() => const AppSettings(
        serverUrl: null,
        allowInsecureTls: true,
        pollingIntervalSeconds: kDefaultPollingIntervalSeconds,
        historyRefreshIntervalSeconds: kDefaultHistoryRefreshIntervalSeconds,
      );

  /// Normalized base URL of the Glances REST API server (scheme + host, no
  /// trailing slash), or null when not configured yet.
  final String? serverUrl;

  /// Whether the HTTP client accepts self-signed / untrusted TLS
  /// certificates (required for Tailscale-hosted and LAN-only servers).
  final bool allowInsecureTls;

  /// Seconds between live-dashboard polls.
  final int pollingIntervalSeconds;

  /// Seconds between CPU-history chart re-fetches.
  final int historyRefreshIntervalSeconds;

  AppSettings copyWith({
    String? serverUrl,
    bool? allowInsecureTls,
    int? pollingIntervalSeconds,
    int? historyRefreshIntervalSeconds,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      allowInsecureTls: allowInsecureTls ?? this.allowInsecureTls,
      pollingIntervalSeconds:
          pollingIntervalSeconds ?? this.pollingIntervalSeconds,
      historyRefreshIntervalSeconds:
          historyRefreshIntervalSeconds ?? this.historyRefreshIntervalSeconds,
    );
  }
}

/// Loads and persists the [AppSettings] in [SharedPreferences].
///
/// Storage keys mirror the phone app (`settings.*`), so the saved state is
/// conceptually interchangeable. Every mutation writes through to the store
/// before publishing the new state.
final class AppSettingsController extends AsyncNotifier<AppSettings> {
  static const String _keyServerUrl = 'settings.serverUrl';
  static const String _keyAllowInsecureTls = 'settings.allowInsecureTls';
  static const String _keyPollingInterval = 'settings.pollingIntervalSeconds';
  static const String _keyHistoryInterval = 'settings.historyRefreshIntervalSeconds';

  @override
  Future<AppSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppSettings(
      serverUrl: prefs.getString(_keyServerUrl),
      allowInsecureTls: prefs.getBool(_keyAllowInsecureTls) ?? true,
      pollingIntervalSeconds:
          prefs.getInt(_keyPollingInterval) ?? kDefaultPollingIntervalSeconds,
      historyRefreshIntervalSeconds: prefs.getInt(_keyHistoryInterval) ??
          kDefaultHistoryRefreshIntervalSeconds,
    );
  }

  Future<void> _save(AppSettings next) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (next.serverUrl == null) {
      await prefs.remove(_keyServerUrl);
    } else {
      await prefs.setString(_keyServerUrl, next.serverUrl!);
    }
    await prefs.setBool(_keyAllowInsecureTls, next.allowInsecureTls);
    await prefs.setInt(_keyPollingInterval, next.pollingIntervalSeconds);
    await prefs.setInt(_keyHistoryInterval, next.historyRefreshIntervalSeconds);
    state = AsyncData<AppSettings>(next);
  }

  /// Persists a new server base URL (already normalized by [ServerConfig.normalize]).
  Future<void> setServerUrl(String? serverUrl) =>
      _save(state.value!.copyWith(serverUrl: serverUrl));

  /// Persists the TLS trust setting.
  Future<void> setAllowInsecureTls(bool value) =>
      _save(state.value!.copyWith(allowInsecureTls: value));

  /// Persists the live-dashboard poll interval.
  Future<void> setPollingIntervalSeconds(int seconds) =>
      _save(state.value!.copyWith(pollingIntervalSeconds: seconds));

  /// Persists the history-chart re-fetch interval.
  Future<void> setHistoryRefreshIntervalSeconds(int seconds) =>
      _save(state.value!.copyWith(historyRefreshIntervalSeconds: seconds));
}

/// Provides the current [AppSettings].
final settingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

/// Live-dashboard poll cadence derived from [settingsProvider].
final refreshIntervalProvider = Provider<Duration>((ref) {
  final AppSettings settings =
      ref.watch(settingsProvider).value ?? AppSettings.defaults();
  return Duration(seconds: settings.pollingIntervalSeconds);
});

/// CPU-history chart re-fetch cadence derived from [settingsProvider].
final historyRefreshIntervalProvider = Provider<Duration>((ref) {
  final AppSettings settings =
      ref.watch(settingsProvider).value ?? AppSettings.defaults();
  return Duration(seconds: settings.historyRefreshIntervalSeconds);
});
