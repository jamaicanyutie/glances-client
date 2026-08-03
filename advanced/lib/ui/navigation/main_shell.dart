import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sheet_dismissing_observer.dart';

/// Root scaffold hosting the bottom [NavigationBar] and the active branch
/// of the [StatefulShellRoute].
///
/// Tapping a tab resets the branch being left to its default state (any open
/// modal sheets are removed without their exit animation) and then switches
/// to the destination branch, so every tab always appears fresh when
/// selected.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.branchDismissers,
  });

  final StatefulNavigationShell navigationShell;

  /// One [SheetDismissingNavigatorObserver] per shell branch, index-aligned
  /// with [AppRouter]'s branch order.
  final List<SheetDismissingNavigatorObserver> branchDismissers;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.memory),
      selectedIcon: Icon(Icons.memory),
      label: 'CPU',
    ),
    NavigationDestination(
      icon: Icon(Icons.speed),
      selectedIcon: Icon(Icons.speed),
      label: 'Memory',
    ),
    NavigationDestination(
      icon: Icon(Icons.storage),
      selectedIcon: Icon(Icons.storage),
      label: 'Disks',
    ),
    NavigationDestination(
      icon: Icon(Icons.network_check),
      selectedIcon: Icon(Icons.network_check),
      label: 'Network',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Services',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          final int leavingIndex = widget.navigationShell.currentIndex;
          // Drop open modal sheets on the branch we are leaving *without*
          // running their exit animation. go_router's indexed-stack shell
          // freezes an inactive branch's tickers, so an animated pop would
          // linger as a frozen overlay that flashes back for a few
          // milliseconds when the tab is revisited. Removing the route
          // directly disposes the overlay immediately instead.
          widget.branchDismissers[leavingIndex].dismissAll();
          // Belt-and-braces: pop anything else pushed on the branch
          // navigator. No-op once only the first route remains (the case
          // after [SheetDismissingNavigatorObserver.dismissAll]).
          widget.navigationShell.route.branches[leavingIndex].navigatorKey
              .currentState
              ?.popUntil((Route<dynamic> route) => route.isFirst);
          widget.navigationShell.goBranch(
            index,
            // Navigate to the branch's initial route so the destination
            // shows its default (deep-linked) page.
            initialLocation: true,
          );
        },
        destinations: _destinations,
      ),
    );
  }
}
