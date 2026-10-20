/// Một mục của Menu Drawer, lấy từ `GET /api/menu` (snake_case).
class MenuNavItem {
  const MenuNavItem({
    required this.id,
    required this.iconName,
    required this.menuName,
    required this.menuUrl,
    required this.ordering,
  });

  final int id;
  final String iconName;
  final String menuName;
  final String menuUrl;
  final int ordering;

  /// Map JSON từ API sang model, các field đều có thể thiếu nên đọc an toàn.
  factory MenuNavItem.fromMap(Map<String, dynamic> map) {
    return MenuNavItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      iconName: map['icon_name']?.toString() ?? '',
      menuName: map['menu_name']?.toString() ?? '',
      menuUrl: map['menu_url']?.toString() ?? '',
      ordering: (map['ordering'] as num?)?.toInt() ?? 0,
    );
  }

  /// Dùng khi ghi vào SQLite. Tên cột khớp với bảng `menu_items`.
  Map<String, Object?> toRow() => {
    'id': id,
    'icon_name': iconName,
    'menu_name': menuName,
    'menu_url': menuUrl,
    'ordering': ordering,
  };

  factory MenuNavItem.fromRow(Map<String, Object?> row) {
    return MenuNavItem(
      id: row['id'] as int,
      iconName: row['icon_name'] as String,
      menuName: row['menu_name'] as String,
      menuUrl: row['menu_url'] as String,
      ordering: row['ordering'] as int,
    );
  }
}
