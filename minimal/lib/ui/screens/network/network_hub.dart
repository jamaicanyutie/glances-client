import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import 'network_screen.dart';

/// Network hub: single interfaces sub-tab (hidden when the server lacks the
/// `network` plugin).
class NetworkHub extends StatelessWidget {
  const NetworkHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by deep-link routes).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'interfaces',
      label: 'Interfaces',
      builder: _interfaces,
      capability: 'network',
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
  return const NetworkScreen();
}