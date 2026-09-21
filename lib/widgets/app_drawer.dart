import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onNewsTap});

  final VoidCallback onNewsTap;

  static const _items = [
    (title: 'Tin tức UEH', icon: FontAwesomeIcons.newspaper),
    (title: 'Sự kiện UEH', icon: FontAwesomeIcons.calendarDays),
    (title: 'Xem điểm', icon: FontAwesomeIcons.graduationCap),
    (title: 'Định danh khuôn mặt', icon: FontAwesomeIcons.userCheck),
    (title: 'Thời khóa biểu', icon: FontAwesomeIcons.clock),
    (title: 'Lịch thi', icon: FontAwesomeIcons.filePen),
    (title: 'Chăm sóc sức khỏe', icon: FontAwesomeIcons.heartPulse),
    (title: 'UEH Go Green Station', icon: FontAwesomeIcons.leaf),
    (title: 'Liên hệ trực tiếp UEH', icon: FontAwesomeIcons.headset),
    (title: 'UEH Green Coin', icon: FontAwesomeIcons.coins),
    (title: 'Đã điểm danh', icon: FontAwesomeIcons.solidCircleCheck),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
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
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    leading: FaIcon(
                      item.icon,
                      size: 20,
                      color: const Color(0xFF005F69),
                    ),
                    title: Text(item.title),
                    onTap: () {
                      Navigator.pop(context);
                      if (index == 0) onNewsTap();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
