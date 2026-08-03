/// Riverpod providers for mDNS discovery of Glances servers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'discovered_server.dart';
import 'server_probe.dart';

/// mDNS service type Glances advertises.
const String kGlancesServiceType = '_glances._tcp';

/// Standard Glances REST API port.
const int kGlancesPort = 61209;

/// Streams Glances servers discovered on the local network via mDNS.
///
/// Emits a fresh list whenever a service appears or disappears, deduplicated
/// by host+port. Yields an empty list when discovery fails or times out so
/// the UI can show the "no servers found" state.
final serverDiscoveryProvider = StreamProvider<List<DiscoveredServer>>((ref) {
  final controller = StreamController<List<DiscoveredServer>>();
  final servers = <DiscoveredServer>[];
  var discoveryInFlight = false;

  Future<void> runDiscovery() async {
    if (discoveryInFlight) {
      return;
    }
    discoveryInFlight = true;
    final mdns = MDnsClient();
    try {
      await mdns.start();
      await for (final ptrRecord in mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(kGlancesServiceType),
        timeout: const Duration(seconds: 5),
      )) {
        await for (final srvRecord in mdns.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptrRecord.domainName),
          timeout: const Duration(seconds: 5),
        )) {
          final server = DiscoveredServer(
            name: ptrRecord.domainName,
            host: srvRecord.target,
            port: srvRecord.port,
          );
          final alreadyPresent = servers.any(
            (s) => s.host == server.host && s.port == server.port,
          );
          if (!alreadyPresent) {
            servers.add(server);
            controller.add(List.unmodifiable(servers));
          }
        }
      }
    } catch (_) {
      // Discovery failed (network down, no mDNS, etc.) — surface an empty
      // list so the UI can show the "no servers found" state.
      controller.add(const []);
    } finally {
      mdns.stop();
      discoveryInFlight = false;
    }
  }

  // Re-scan periodically so the list stays fresh while the Settings screen
  // is open. `invalidate` (Scan again) restarts the stream too.
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    runDiscovery();
  });

  runDiscovery();

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Holds the server the user picked from the discovery list.
class SelectedDiscoveredServerNotifier extends Notifier<DiscoveredServer?> {
  @override
  DiscoveredServer? build() => null;

  void select(DiscoveredServer server) {
    state = server;
  }
}

/// The server the user picked from the discovery list, if any.
final selectedDiscoveredServerProvider =
    NotifierProvider<SelectedDiscoveredServerNotifier, DiscoveredServer?>(
  SelectedDiscoveredServerNotifier.new,
);

/// Probes a user-entered address and reports whether a Glances API answers.
///
/// Keyed by the raw input (e.g. `glances.example.com` or `192.168.1.50:61209`);
/// the probe tries https before http for hostnames and resolves raw IPs
/// straight to http. Results are cached until the input changes (autoDispose
/// family).
final serverProbeProvider = FutureProvider.autoDispose
    .family<ConnectionTestResult, String>((ref, input) {
  return probeWithFallback(input);
});
