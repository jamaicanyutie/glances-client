import 'package:flutter/widgets.dart';

import '../../components/hub_scaffold.dart';
import '../folders/folders_screen.dart';
import 'disks_screen.dart';

/// Disks hub: sub-tabs for the filesystems overview, disk I/O rates and the
/// folders screen (which is hidden when the server lacks the `folders` plugin).
class DisksHub extends StatelessWidget {
  const DisksHub({super.key, this.initialTabId});

  /// Sub-tab to select initially (used by the `/disks/folders` deep-link route).
  final String? initialTabId;

  static const List<HubTab> _tabs = <HubTab>[
    HubTab(
      id: 'filesystems',
      label: 'Filesystems',
      builder: _filesystems,
    ),
    HubTab(
      id: 'io',
      label: 'I/O',
      builder: _io,
    ),
    HubTab(
      id: 'folders',
      label: 'Folders',
      builder: _folders,
      capability: 'folders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HubScaffold(
      title: 'Disks',
      tabs: _tabs,
      initialTabId: initialTabId,
    );
  }
}

Widget _filesystems(BuildContext context) {
  return const DisksScreen(showAppBar: false);
}

Widget _io(BuildContext context) {
  return const DisksIoView(showAppBar: false);
}

Widget _folders(BuildContext context) {
  return const FoldersScreen(showAppBar: false);
}