import 'package:go_router/go_router.dart';

import '../screens/cpu/cpu_screen.dart';
import '../screens/disks/disks_screen.dart';
import '../screens/docker/docker_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/memory/memory_screen.dart';
import '../screens/network/network_screen.dart';
import 'server_config_gate.dart';

/// Central route table.
///
/// Six bottom-navigation branches (Home, CPU, Memory, Disks, Network,
/// Services) live in a [StatefulShellRoute.indexedStack] so each branch
/// keeps its own navigation stack and state.
///
/// v1 has no drill-down routes: the dashboard is display-only and every
/// screen is reachable from the bottom navigation bar.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ServerConfigGate(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/cpu',
                builder: (context, state) => const CpuScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/memory',
                builder: (context, state) => const MemoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/disks',
                builder: (context, state) => const DisksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/network',
                builder: (context, state) => const NetworkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/docker',
                builder: (context, state) => const DockerScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
