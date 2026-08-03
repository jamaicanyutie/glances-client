import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../screens/alerts/alerts_screen.dart';
import '../screens/cpu/cpu_screen.dart';
import '../screens/disks/disks_screen.dart';
import '../screens/docker/container_detail_screen.dart';
import '../screens/docker/docker_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/ip/ip_screen.dart';
import '../screens/memory/memory_screen.dart';
import '../screens/network/network_screen.dart';
import '../screens/ports/ports_screen.dart';
import '../screens/processes/process_detail_screen.dart';
import '../screens/processes/processes_screen.dart';
import '../screens/sensors/sensors_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/system/system_screen.dart';
import '../screens/vms/vms_screen.dart';
import '../screens/wifi/wifi_screen.dart';
import 'main_shell.dart';
import 'sheet_dismissing_observer.dart';

/// Central route table.
///
/// Six bottom-navigation branches (Home, CPU, Memory, Disks, Network,
/// Services) live in a [StatefulShellRoute.indexedStack] so each branch
/// keeps its own navigation stack and state.
///
/// `/processes`, `/containers/:id`, `/settings`, `/sensors`, `/system` and
/// `/alerts` are top-level routes: they are pushed on top of the shell
/// (covering the bottom navigation bar).
abstract final class AppRouter {
  /// Number of shell branches below — keep in sync with the branch list.
  static const int _shellBranchCount = 6;

  /// One [SheetDismissingNavigatorObserver] per shell branch, index-aligned
  /// with the branch list. The shell uses these to drop open modal sheets
  /// without their (freezing-prone) exit animation when a tab is switched.
  static final List<SheetDismissingNavigatorObserver> branchDismissers =
      List<SheetDismissingNavigatorObserver>.generate(
    _shellBranchCount,
    (int index) => SheetDismissingNavigatorObserver(),
  );

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
          branchDismissers: AppRouter.branchDismissers,
        ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[0]],
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[1]],
            routes: <RouteBase>[
              GoRoute(
                path: '/cpu',
                builder: (context, state) => const CpuScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[2]],
            routes: <RouteBase>[
              GoRoute(
                path: '/memory',
                builder: (context, state) => const MemoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[3]],
            routes: <RouteBase>[
              GoRoute(
                path: '/disks',
                builder: (context, state) => const DisksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[4]],
            routes: <RouteBase>[
              GoRoute(
                path: '/network',
                builder: (context, state) => const NetworkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: <NavigatorObserver>[AppRouter.branchDismissers[5]],
            routes: <RouteBase>[
              GoRoute(
                path: '/docker',
                builder: (context, state) => const DockerScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/processes',
        builder: (context, state) => const ProcessesScreen(),
      ),
      GoRoute(
        path: '/processes/:pid',
        builder: (context, state) => ProcessDetailScreen(
          pid: int.parse(state.pathParameters['pid']!),
        ),
      ),
      GoRoute(
        path: '/containers/:id',
        builder: (context, state) =>
            ContainerDetailScreen(containerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/sensors',
        builder: (context, state) => const SensorsScreen(),
      ),
      GoRoute(
        path: '/system',
        builder: (context, state) => const SystemScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/ip',
        builder: (context, state) => const IpScreen(),
      ),
      GoRoute(
        path: '/wifi',
        builder: (context, state) => const WifiScreen(),
      ),
      GoRoute(
        path: '/ports',
        builder: (context, state) => const PortsScreen(),
      ),
      GoRoute(
        path: '/vms',
        builder: (context, state) => const VmsScreen(),
      ),
    ],
  );
}
