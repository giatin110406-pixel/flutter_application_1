import 'dart:convert';

import 'package:http/http.dart' as http;

import 'news_item.dart';

/// Gọi các API tin tức công khai (không cần đăng nhập).
class NewsApi {
  NewsApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://api.ngoisaoviet.info';
  static const defaultCatUid = 219;
  // Request đầu tiên có thể chậm (đã đo ~20 giây), nên timeout đủ dài và thử lại một lần.
  static const _timeout = Duration(seconds: 30);

  final http.Client _client;

  /// 5 tin nổi bật: tin đầu dùng `background_img`, 4 tin sau dùng `thumbnail_img`.
  Future<List<NewsItem>> getFeatured() async {
    final response = await _get(Uri.parse('$baseUrl/api/news/featured'));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List<dynamic>) {
      throw const NewsApiException('Phản hồi tin nổi bật không hợp lệ.');
    }
    return decoded
        .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy một trang tin của danh mục. Dùng `offset` để tải trang kế tiếp.
  Future<NewsPage> getNews({
    int catUid = defaultCatUid,
    required int limit,
    required int offset,
  }) async {
    final uri = Uri.parse('$baseUrl/api/news').replace(
      queryParameters: {
        'cat_uid': '$catUid',
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final response = await _get(uri);
    return NewsPage.fromJson(_decodeObject(response));
  }

  /// Lấy nội dung HTML đầy đủ của một bài.
  Future<NewsDetail> getNewsDetail(int uid) async {
    final response = await _get(Uri.parse('$baseUrl/api/news/$uid'));
    return NewsDetail.fromJson(_decodeObject(response));
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _getWithRetry(uri);
    } catch (_) {
      throw const NewsApiException('Không thể kết nối máy chủ tin tức.');
    }
    if (response.statusCode != 200) {
      throw NewsApiException(
        'Máy chủ trả về lỗi (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  /// Thử lại đúng một lần nếu request đầu bị lỗi hoặc quá thời gian.
  Future<http.Response> _getWithRetry(Uri uri) async {
    try {
      return await _client.get(uri).timeout(_timeout);
    } catch (_) {
      return _client.get(uri).timeout(_timeout);
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw const NewsApiException('Phản hồi tin tức không hợp lệ.');
  }
}

class NewsApiException implements Exception {
  const NewsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
