import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../features/drawer_menu/app_drawer.dart';
import '../router/shell_scope.dart';
import 'app_bottom_navigation.dart';

/// Khung chung của 4 tab: AppBar, drawer và thanh menu dưới.
/// Nội dung từng tab do router dựng và truyền vào qua [navigationShell].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _uehGreen = Color(0xFF006B78);
  static const _titles = ['Trang chủ', 'Thông báo', 'Điểm danh', 'Tài khoản'];

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      drawer: AppDrawer(
        api: studentApi,
        onNewsTap: () {
          context.push('/news');
        },
      ),
      appBar: AppBar(
        backgroundColor: _uehGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _titles[index],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          if (index == 0)
            IconButton(
              tooltip: 'Tải lại',
              onPressed: () => newsScreenKey.currentState?.reload(),
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
            ),
          if (index == 3)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => accountScreenKey.currentState?.logout(),
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: index,
        // Bấm lại tab đang chọn thì về màn hình gốc của tab đó.
        onSelected: (i) =>
            navigationShell.goBranch(i, initialLocation: i == index),
      ),
    );
  }
}

/// Tab Thông báo (chưa có nội dung).
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.bullhorn, size: 48, color: Color(0xFF006B78)),
          SizedBox(height: 12),
          Text('Thông báo', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
