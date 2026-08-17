import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import '../ip/ip_screen.dart';
import '../ports/ports_screen.dart';
import '../wifi/wifi_screen.dart';
import 'network_screen.dart';

/// Network hub: sub-tabs for the interface counters, IP/Wi-Fi/Ports screens
/// (hidden when the server lacks their plugin) and the connections summary.
class NetworkHub extends StatelessWidget {
  const NetworkHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by deep-link routes).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'interfaces',
      label: 'Interfaces',
      builder: _interfaces,
    ),
    HubTab(
      id: 'ip',
      label: 'IP',
      builder: _ip,
      capability: 'ip',
    ),
    HubTab(
      id: 'wifi',
      label: 'Wi-Fi',
      builder: _wifi,
      capability: 'wifi',
    ),
    HubTab(
      id: 'ports',
      label: 'Ports',
      builder: _ports,
      capability: 'ports',
    ),
    HubTab(
      id: 'connections',
      label: 'Connections',
      builder: _connections,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HubScaffold(
      title: 'Network',
      tabs: _tabs,
      initialTabId: initialTabId,
    );
  }
}

Widget _interfaces(BuildContext context) {
  return const NetworkScreen(showAppBar: false);
}

Widget _ip(BuildContext context) {
  return const IpScreen(showAppBar: false);
}

Widget _wifi(BuildContext context) {
  return const WifiScreen(showAppBar: false);
}

Widget _ports(BuildContext context) {
  return const PortsScreen(showAppBar: false);
}

Widget _connections(BuildContext context) {
  return const NetworkConnectionsView(showAppBar: false);
}