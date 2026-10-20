/// Một bài tin lấy từ `/api/news`, `/api/news/featured`.
class NewsItem {
  const NewsItem({
    required this.uid,
    required this.catUid,
    required this.categoryName,
    required this.title,
    required this.shortDesc,
    required this.postDate,
    required this.sdgs,
    required this.isFeatured,
    required this.backgroundImg,
    required this.thumbnailImg,
  });

  final int uid;
  final int catUid;
  final String categoryName;
  final String title;
  final String shortDesc;
  final String postDate;
  final List<int> sdgs;
  final bool isFeatured;
  final String backgroundImg;
  final String thumbnailImg;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      uid: (json['uid'] as num).toInt(),
      catUid: (json['cat_uid'] as num?)?.toInt() ?? 0,
      categoryName: json['category_name']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      shortDesc: json['short_desc']?.toString().trim() ?? '',
      postDate: json['post_date']?.toString() ?? '',
      sdgs: (json['sdgs'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      isFeatured: json['is_featured'] == true,
      backgroundImg: json['background_img']?.toString() ?? '',
      thumbnailImg: json['thumbnail_img']?.toString() ?? '',
    );
  }

  /// Ngày đăng dạng dd/MM/yyyy, lấy từ `post_date` (ISO 8601).
  String get formattedDate {
    final date = DateTime.tryParse(postDate);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Một trang kết quả của `/api/news?cat_uid=...&limit=...&offset=...`.
class NewsPage {
  const NewsPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.items,
  });

  final int total;
  final int limit;
  final int offset;
  final List<NewsItem> items;

  factory NewsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return NewsPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Chi tiết bài viết từ `/api/news/{uid}`, `content` là chuỗi HTML.
class NewsDetail {
  const NewsDetail({required this.content});

  final String content;

  factory NewsDetail.fromJson(Map<String, dynamic> json) {
    return NewsDetail(content: json['content']?.toString() ?? '');
  }
}
