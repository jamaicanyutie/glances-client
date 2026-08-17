import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import '../../components/metric_sheets.dart';
import '../gpu/gpu_screen.dart';
import 'cpu_screen.dart';

/// CPU hub: sub-tabs for the overview, per-core and history sheets and the GPU
/// screen (which is hidden when the server lacks the `gpu` plugin).
class CpuHub extends StatelessWidget {
  const CpuHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by the `/cpu/gpu` deep-link route).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'overview',
      label: 'Overview',
      builder: _overview,
    ),
    HubTab(
      id: 'percore',
      label: 'Per-Core',
      builder: _perCore,
    ),
    HubTab(
      id: 'history',
      label: 'History',
      builder: _history,
    ),
    HubTab(
      id: 'gpu',
      label: 'GPU',
      builder: _gpu,
      capability: 'gpu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HubScaffold(
      title: 'CPU',
      tabs: _tabs,
      initialTabId: initialTabId,
    );
  }
}

Widget _overview(BuildContext context) {
  return const CpuScreen(showAppBar: false);
}

Widget _perCore(BuildContext context) {
  return const SheetTabBody(child: PerCoreSheetBody());
}

Widget _history(BuildContext context) {
  return const SheetTabBody(child: CpuHistorySheetBody());
}

Widget _gpu(BuildContext context) {
  return const GpuScreen(showAppBar: false);
}