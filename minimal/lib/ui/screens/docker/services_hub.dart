import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import 'docker_screen.dart';

/// Services hub: single containers sub-tab (hidden when the server lacks the
/// `containers` plugin).
class ServicesHub extends StatelessWidget {
  const ServicesHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by deep-link routes).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'containers',
      label: 'Containers',
      builder: _containers,
      capability: 'containers',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HubScaffold(
      title: 'Services',
      tabs: _tabs,
      initialTabId: initialTabId,
    );
  }
}

Widget _containers(BuildContext context) {
  return const DockerScreen();
}