import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../features/drawer_menu/app_drawer.dart';
import 'app_bottom_navigation.dart';
import '../../features/account/account_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/news/news_screen.dart';
import '../services/student_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _uehGreen = Color(0xFF006B78);

  // GlobalKey để gọi reload() trên NewsScreen từ Drawer / AppBar
  final _newsKey = GlobalKey<NewsScreenState>();
  final _accountKey = GlobalKey<AccountScreenState>();
  final _studentApi = StudentApi();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        api: _studentApi,
        onNewsTap: () {
          context.push('/news');
        },
      ),
      appBar: AppBar(
        backgroundColor: _uehGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _tabTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Tải lại',
              onPressed: () => _newsKey.currentState?.reload(),
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
            ),
          if (_selectedIndex == 3)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => _accountKey.currentState?.logout(),
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          NewsScreen(
            key: _newsKey,
            onTabSelected: (index) => setState(() => _selectedIndex = index),
          ),
          _buildEmptyTab(FontAwesomeIcons.bullhorn, 'Thông báo'),
          AttendanceScreen(api: _studentApi),
          AccountScreen(key: _accountKey, api: _studentApi),
        ],
      ),
      bottomNavigationBar: _buildBottomMenu(),
    );
  }

  String _tabTitle(int index) {
    const titles = ['Trang chủ', 'Thông báo', 'Điểm danh', 'Tài khoản'];
    return titles[index];
  }

  Widget _buildBottomMenu() {
    return AppBottomNavigation(
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildEmptyTab(FaIconData icon, String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 48, color: _uehGreen),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
