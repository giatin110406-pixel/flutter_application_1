import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'menu_nav_item.dart';
import 'menu_database.dart';
import '../../core/services/student_api.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, required this.api, required this.onNewsTap});

  final StudentApi api;
  final VoidCallback onNewsTap;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _db = MenuDatabase();

  /// Menu dự phòng khi chưa có cache và chưa tải được từ API, để drawer không bị trống.
  static const _fallbackItems = [
    MenuNavItem(id: -1, iconName: 'newspaper', menuName: 'Tin tức UEH', menuUrl: '', ordering: 0),
    MenuNavItem(id: -2, iconName: 'calendarDays', menuName: 'Sự kiện UEH', menuUrl: '', ordering: 1),
    MenuNavItem(id: -3, iconName: 'graduationCap', menuName: 'Xem điểm', menuUrl: '', ordering: 2),
    MenuNavItem(id: -4, iconName: 'userCheck', menuName: 'Định danh khuôn mặt', menuUrl: '', ordering: 3),
    MenuNavItem(id: -5, iconName: 'clock', menuName: 'Thời khóa biểu', menuUrl: '', ordering: 4),
    MenuNavItem(id: -6, iconName: 'filePen', menuName: 'Lịch thi', menuUrl: '', ordering: 5),
    MenuNavItem(id: -7, iconName: 'heartPulse', menuName: 'Chăm sóc sức khỏe', menuUrl: '', ordering: 6),
    MenuNavItem(id: -8, iconName: 'leaf', menuName: 'UEH Go Green Station', menuUrl: '', ordering: 7),
    MenuNavItem(id: -9, iconName: 'headset', menuName: 'Liên hệ trực tiếp UEH', menuUrl: '', ordering: 8),
    MenuNavItem(id: -10, iconName: 'coins', menuName: 'UEH Green Coin', menuUrl: '', ordering: 9),
    MenuNavItem(id: -11, iconName: 'solidCircleCheck', menuName: 'Đã điểm danh', menuUrl: '', ordering: 10),
  ];

  List<MenuNavItem> _items = _fallbackItems;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  /// Bước 1: đọc cache SQLite để hiện menu ngay.
  /// Bước 2: gọi /api/menu, nếu thành công thì ghi đè cache và cập nhật.
  /// Nếu lỗi mạng thì giữ menu đang có.
  Future<void> _loadMenu() async {
    try {
      final cached = await _db.loadAll();
      if (mounted && cached.isNotEmpty) setState(() => _items = cached);
    } catch (_) {
      // Lỗi đọc SQLite: dùng menu dự phòng, vẫn thử gọi API.
    }

    try {
      final fresh = await widget.api.getMenu();
      if (fresh.isEmpty) return;
      await _db.saveAll(fresh);
      if (mounted) setState(() => _items = fresh);
    } catch (_) {
      // Mất mạng hoặc chưa đăng nhập: giữ menu từ cache.
    }
  }

  void _onItemTap(MenuNavItem item) {
    Navigator.pop(context);
    if (item.iconName == 'newspaper') {
      widget.onNewsTap();
      return;
    }
    if (item.menuUrl.isNotEmpty) {
      launchUrl(Uri.parse(item.menuUrl), mode: LaunchMode.externalApplication);
    }
  }

  static const _iconMap = <String, FaIconData>{
    'newspaper': FontAwesomeIcons.newspaper,
    'calendarDays': FontAwesomeIcons.calendarDays,
    'chartLine': FontAwesomeIcons.chartLine,
    'graduationCap': FontAwesomeIcons.graduationCap,
    'userCheck': FontAwesomeIcons.userCheck,
    'clock': FontAwesomeIcons.clock,
    'filePen': FontAwesomeIcons.filePen,
    'heartPulse': FontAwesomeIcons.heartPulse,
    'leaf': FontAwesomeIcons.leaf,
    'headset': FontAwesomeIcons.headset,
    'coins': FontAwesomeIcons.coins,
    'solidCircleCheck': FontAwesomeIcons.solidCircleCheck,
  };

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 190,
            width: double.infinity,
            color: const Color(0xFF005F69),
            child: Center(
              child: Image.asset(
                'images/logo-header.png',
                width: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'UEH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    leading: FaIcon(
                      _iconMap[item.iconName] ??
                          FontAwesomeIcons.circleQuestion,
                      size: 20,
                      color: const Color(0xFF005F69),
                    ),
                    title: Text(item.menuName),
                    onTap: () => _onItemTap(item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
