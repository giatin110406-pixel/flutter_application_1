import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/home_screen.dart';
import '../widgets/splash_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/news/news_screen.dart';
import 'shell_scope.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    // Đường dẫn cũ: chuyển về tab đầu tiên.
    GoRoute(path: '/home', redirect: (context, state) => kTabPaths.first),
    // Khung 4 tab; mỗi tab là một nhánh có đường dẫn riêng và giữ trạng thái.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/news',
              builder: (context, state) => NewsScreen(key: newsScreenKey),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/notifications',
              builder: (context, state) => const NotificationsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/attendance',
              builder: (context, state) => AttendanceScreen(api: studentApi),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home/account',
              builder: (context, state) =>
                  AccountScreen(key: accountScreenKey, api: studentApi),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/news', builder: (context, state) => const UehNewsPage()),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Không tìm thấy trang: ${state.uri}'))),
);
