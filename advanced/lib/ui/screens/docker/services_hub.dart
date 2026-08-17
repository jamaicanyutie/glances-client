import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import '../processes/extended_processes_view.dart';
import '../processes/processes_screen.dart';
import '../programs/programs_screen.dart';
import '../vms/vms_screen.dart';
import 'docker_screen.dart';

/// Services hub: sub-tabs for the container overview, VMs and programs screens
/// (hidden when the server lacks their plugin) and the processes list.
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
    HubTab(
      id: 'vms',
      label: 'VMs',
      builder: _vms,
      capability: 'vms',
    ),
    HubTab(
      id: 'processes',
      label: 'Processes',
      builder: _processes,
    ),
    HubTab(
      id: 'programs',
      label: 'Programs',
      builder: _programs,
      capability: 'programlist',
    ),
    HubTab(
      id: 'extended',
      label: 'Extended',
      builder: _extended,
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
  return const DockerScreen(showAppBar: false);
}

Widget _vms(BuildContext context) {
  return const VmsScreen(showAppBar: false);
}

Widget _processes(BuildContext context) {
  return const ProcessesScreen(showAppBar: false);
}

Widget _programs(BuildContext context) {
  return const ProgramsScreen(showAppBar: false);
}

Widget _extended(BuildContext context) {
  return const ExtendedProcessesView();
}