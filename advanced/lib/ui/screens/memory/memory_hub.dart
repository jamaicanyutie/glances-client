import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import '../../components/metric_sheets.dart';
import 'memory_screen.dart';

/// Memory hub: sub-tabs for the memory overview and the swap usage sheet.
class MemoryHub extends StatelessWidget {
  const MemoryHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (reserved for deep-link routes).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'overview',
      label: 'Overview',
      builder: _overview,
    ),
    HubTab(
      id: 'swap',
      label: 'Swap',
      builder: _swap,
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
  return const MemoryScreen(showAppBar: false);
}

Widget _swap(BuildContext context) {
  return const SheetTabBody(child: SwapSheetBody());
}