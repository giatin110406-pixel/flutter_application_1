import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/home_screen.dart';
import '../widgets/splash_screen.dart';
import '../../features/news/news_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/news',
      builder: (context, state) => const UehNewsPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Không tìm thấy trang: ${state.uri}')),
  ),
);
