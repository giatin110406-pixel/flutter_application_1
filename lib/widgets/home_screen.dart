import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_drawer.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _webViewController;
  int _selectedIndex = 0;

  static const _orange = Color(0xFFF47721);
  static const _lightOrange = Color(0xFFFFC29E);

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://ueh.edu.vn/tintucmobile'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onNewsTap: () => _webViewController.loadRequest(
          Uri.parse('https://ueh.edu.vn/tintucmobile'),
        ),
      ),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Trang chủ',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => _webViewController.reload(),
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WebViewScreen(controller: _webViewController),
          _buildEmptyTab(FontAwesomeIcons.bullhorn, 'Thông báo'),
          _buildEmptyTab(FontAwesomeIcons.userCheck, 'Điểm danh'),
          _buildEmptyTab(FontAwesomeIcons.user, 'Tài khoản'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? _orange
                : _lightOrange,
            fontSize: 10,
          );
        }),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house, color: _lightOrange),
            selectedIcon: FaIcon(
              FontAwesomeIcons.house,
              color: _orange,
            ),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.bullhorn, color: _lightOrange),
            selectedIcon: FaIcon(
              FontAwesomeIcons.bullhorn,
              color: _orange,
            ),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.userCheck, color: _lightOrange),
            selectedIcon: FaIcon(
              FontAwesomeIcons.userCheck,
              color: _orange,
            ),
            label: 'Điểm danh',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.user, color: _lightOrange),
            selectedIcon: FaIcon(
              FontAwesomeIcons.user,
              color: _orange,
            ),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(FaIconData icon, String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 48, color: _orange),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

}
