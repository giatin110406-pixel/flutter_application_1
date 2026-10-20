import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'menu_nav_item.dart';

/// Cache menu drawer trong SQLite. Đọc từ đây khi mở app hoặc khi mất mạng.
class MenuDatabase {
  static const _dbName = 'ueh_menu.db';
  static const _dbVersion = 1;
  static const _table = 'menu_items';

  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = p.join(await getDatabasesPath(), _dbName);
    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY,
            icon_name TEXT NOT NULL,
            menu_name TEXT NOT NULL,
            menu_url TEXT NOT NULL,
            ordering INTEGER NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  /// Đọc menu đã cache, sắp theo `ordering`. Trả về rỗng nếu chưa có cache.
  Future<List<MenuNavItem>> loadAll() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'ordering ASC');
    return rows.map(MenuNavItem.fromRow).toList();
  }

  /// Thay toàn bộ cache bằng danh sách mới trong một transaction,
  /// để nếu lỗi giữa chừng thì cache cũ vẫn còn nguyên.
  Future<void> saveAll(List<MenuNavItem> items) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(_table);
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          _table,
          item.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
