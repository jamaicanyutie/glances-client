import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import 'memory_screen.dart';

/// Memory hub: single overview sub-tab (hidden when the server lacks the
/// `mem` plugin).
class MemoryHub extends StatelessWidget {
  const MemoryHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by deep-link routes).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'overview',
      label: 'Overview',
      builder: _overview,
      capability: 'mem',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HubScaffold(
      title: 'Memory',
      tabs: _tabs,
      initialTabId: initialTabId,
    );
  }
}

Widget _overview(BuildContext context) {
  return const MemoryScreen();
}