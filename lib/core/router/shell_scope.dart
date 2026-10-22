import 'package:flutter/widgets.dart';

import '../../features/account/account_screen.dart';
import '../../features/news/news_screen.dart';
import '../services/student_api.dart';

/// Đường dẫn của 4 tab dưới thanh menu, đúng thứ tự trên thanh.
const kTabPaths = [
  '/home/news',
  '/home/notifications',
  '/home/attendance',
  '/home/account',
];

/// Dùng chung giữa router (dựng các tab) và khung HomeScreen (AppBar, drawer).
final studentApi = StudentApi();
final newsScreenKey = GlobalKey<NewsScreenState>();
final accountScreenKey = GlobalKey<AccountScreenState>();
