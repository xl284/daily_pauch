import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/today/today_screen.dart';
import '../../features/tasks/tasks_list_screen.dart';
import '../../features/tasks/task_edit_screen.dart';
import '../../features/tasks/task_detail_screen.dart';
import '../../features/stats/stats_overview_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.today), label: '今日'),
                NavigationDestination(icon: Icon(Icons.list_alt), label: '任务'),
                NavigationDestination(icon: Icon(Icons.bar_chart), label: '统计'),
                NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tasks', builder: (_, __) => const TasksListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/stats', builder: (_, __) => const StatsOverviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/tasks/new',
        builder: (_, __) => const TaskEditScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (_, state) =>
            TaskDetailScreen(taskId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        builder: (_, state) =>
            TaskEditScreen(taskId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
