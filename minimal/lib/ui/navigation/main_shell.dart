import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root scaffold hosting the bottom [NavigationBar] and the active branch
/// of the [StatefulShellRoute].
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: _destinations,
      ),
    );
  }
}
