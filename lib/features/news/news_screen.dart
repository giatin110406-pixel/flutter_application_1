import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;

import 'news_item.dart';
import 'news_api.dart';
import '../../core/widgets/app_bottom_navigation.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

/// Ảnh icon SDG tiếng Việt, đặt tại assets/sdg/sdg-1.png đến sdg-17.png.
const _sdgAssetCount = 17;

// ─── Screen ──────────────────────────────────────────────────────────────────

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.onTabSelected});

  final ValueChanged<int>? onTabSelected;

  @override
  State<NewsScreen> createState() => NewsScreenState();
}

class UehNewsPage extends StatelessWidget {
  const UehNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Cuộc sống UEH'),
      ),
      body: const NewsScreen(),
    );
  }
}

/// catUid giả cho tab riêng "Tin tức nổi bật" (không thuộc 4 chuyên mục).
const _kFeaturedCatUid = -1;

class NewsCategory {
  final int catUid;
  final String name;

  const NewsCategory({required this.catUid, required this.name});
}

const _kUehCategories = [
  NewsCategory(catUid: 219, name: 'Cuộc sống UEH'),
  NewsCategory(catUid: 220, name: 'Khoa học - Góc nhìn chuyên gia'),
  NewsCategory(catUid: 221, name: 'Báo chí nói về UEH'),
  NewsCategory(catUid: 222, name: 'Tuyển sinh & Hướng nghiệp'),
];

class NewsScreenState extends State<NewsScreen> {
  static const _uehGreen = Color(0xFF006B78);

  final _api = NewsApi();

  List<NewsItem> _featured = const [];
  final Map<int, NewsItem> _latest = {};
  bool _isInitialLoading = true;
  Object? _initialError;

  // Tăng số này mỗi lần tải lại để bỏ qua kết quả của request cũ.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  /// Tải tin nổi bật và tin mới nhất của từng chuyên mục.
  Future<void> _loadInitial() async {
    final generation = ++_generation;
    setState(() {
      _isInitialLoading = true;
      _initialError = null;
    });

    try {
      final results = await Future.wait([
        _api.getFeatured(),
        for (final c in _kUehCategories)
          _api.getNews(catUid: c.catUid, limit: 1, offset: 0),
      ]);
      if (!mounted || generation != _generation) return;
      final featured = results.first as List<NewsItem>;

      setState(() {
        _featured = featured;
        _latest.clear();
        for (var i = 0; i < _kUehCategories.length; i++) {
          final page = results[i + 1] as NewsPage;
          if (page.items.isNotEmpty) {
            _latest[_kUehCategories[i].catUid] = page.items.first;
          }
        }
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _initialError = error;
        _isInitialLoading = false;
      });
    }
  }

  /// Bấm tên chuyên mục: mở trang riêng liệt kê các bài báo của chuyên mục đó.
  void _openCategory(int catUid, String catName) {
    final name = catName.isNotEmpty
        ? catName
        : _kUehCategories
              .firstWhere(
                (c) => c.catUid == catUid,
                orElse: () =>
                    NewsCategory(catUid: catUid, name: 'Chuyên mục $catUid'),
              )
              .name;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryScreen(
          catUid: catUid,
          catName: name,
          onOpenArticle: _openDetail,
          onTabSelected: widget.onTabSelected,
        ),
      ),
    );
  }

  /// Gọi từ AppBar (home_screen.dart) để tải lại toàn bộ tin.
  void reload() => _loadInitial();

  Future<void> _refresh() => _loadInitial();

  void _openDetail(NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArticleDetailScreen(
          item: item,
          onTabSelected: widget.onTabSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _uehGreen),
      );
    }
    if (_initialError != null) {
      return _ErrorView(
        message: _initialError.toString(),
        onRetry: _loadInitial,
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: RefreshIndicator(
        color: _uehGreen,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            const SliverToBoxAdapter(child: _Header()),

            // ── Tin nổi bật + 4 chuyên mục ──────────────────────────────────
            if (_featured.isNotEmpty)
              SliverToBoxAdapter(
                child: _FeaturedSection(
                  hero: _featured.first,
                  latestByCategory: _latest,
                  onTap: _openDetail,
                  onCategoryTap: _openCategory,
                  onFeaturedTap: () =>
                      _openCategory(_kFeaturedCatUid, 'Tin tức nổi bật'),
                ),
              ),

          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: const Column(
        children: [
          Text(
            'Tin tức',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF26F33), // cam UEH
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Thông tin mới nhất và kiến thức hữu ích từ UEH',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Featured section ────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.hero,
    required this.latestByCategory,
    required this.onTap,
    required this.onCategoryTap,
    required this.onFeaturedTap,
  });

  final NewsItem hero;
  final Map<int, NewsItem> latestByCategory;
  final ValueChanged<NewsItem> onTap;
  final void Function(int catUid, String catName) onCategoryTap;
  final VoidCallback onFeaturedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7F8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          _HeroCard(
            item: hero,
            onTap: () => onTap(hero),
            onFeaturedTap: onFeaturedTap,
          ),
          const SizedBox(height: 16),
          for (final category in _kUehCategories)
            if (latestByCategory[category.catUid] != null)
              _CategoryCard(
                category: category,
                item: latestByCategory[category.catUid]!,
                onTap: () => onTap(latestByCategory[category.catUid]!),
                onCategoryTap: () =>
                    onCategoryTap(category.catUid, category.name),
              ),
        ],
      ),
    );
  }
}

/// Tin nổi bật: ảnh ở trên, khối xanh bên dưới có nhãn, icon SDG và tiêu đề.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.item,
    required this.onTap,
    required this.onFeaturedTap,
  });

  static const _panelColor = Color(0xFF2E6470);

  final NewsItem item;
  final VoidCallback onTap;
  final VoidCallback onFeaturedTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black38,
      color: _panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              // Tin không có ảnh nền thì dùng thumbnail thay thế.
              child: _NetworkImage(
                url: item.backgroundImg.isNotEmpty
                    ? item.backgroundImg
                    : item.thumbnailImg,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                // Bấm nhãn: mở tab riêng gồm các tin nổi bật.
                InkWell(
                  onTap: onFeaturedTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'TIN TỨC NỔI BẬT',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                if (item.sdgs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SdgChips(sdgs: item.sdgs, size: 40),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: onTap,
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ một chuyên mục: tên chuyên mục, icon SDG và tiêu đề tin mới nhất, không có hình.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.item,
    required this.onTap,
    required this.onCategoryTap,
  });

  final NewsCategory category;
  final NewsItem item;
  final VoidCallback onTap;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        elevation: 1,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bấm tên chuyên mục: mở trang các bài báo của chuyên mục đó.
              InkWell(
                onTap: onCategoryTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    category.name.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF006B78),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (item.sdgs.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SdgChips(sdgs: item.sdgs, size: 36),
              ],
              const SizedBox(height: 8),
              // Bấm tiêu đề: mở trình đọc bài báo.
              InkWell(
                onTap: onTap,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.3,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFF006B78).withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF006B78),
        ),
      ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

/// Dãy icon SDG của tin. Bỏ qua số ngoài khoảng 1–17.
class _SdgChips extends StatelessWidget {
  const _SdgChips({required this.sdgs, this.size = 24});

  final List<int> sdgs;
  final double size;

  @override
  Widget build(BuildContext context) {
    final valid = sdgs
        .where((sdg) => sdg >= 1 && sdg <= _sdgAssetCount)
        .toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final sdg in valid)
          Image.asset(
            'assets/sdg/sdg-$sdg.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => SizedBox.square(
              dimension: size,
              child: Center(child: Text('$sdg')),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Color(0xFF006B78),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tải được tin tức',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B78),
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Article detail ──────────────────────────────────────────────────────────

class _ArticleDetailScreen extends StatefulWidget {
  const _ArticleDetailScreen({required this.item, this.onTabSelected});

  final NewsItem item;
  final ValueChanged<int>? onTabSelected;

  @override
  State<_ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<_ArticleDetailScreen> {
  final _api = NewsApi();
  late Future<NewsDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _api.getNewsDetail(widget.item.uid);
  }

  void _reload() {
    setState(() => _detail = _api.getNewsDetail(widget.item.uid));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: const Color(0xFF006B78),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              const Text(
                'Trang chủ',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              Text(
                item.categoryName,
                style: const TextStyle(fontSize: 14, color: Color(0xFF08747A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF006B78),
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
          if (item.formattedDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.formattedDate,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          FutureBuilder<NewsDetail>(
            future: _detail,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF006B78)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Không tải được nội dung: ${snapshot.error}',
                  style: const TextStyle(color: Colors.grey),
                );
              }
              return Html(
                data: snapshot.data?.content ?? '',
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(17),
                    lineHeight: const LineHeight(1.5),
                    color: const Color(0xFF171717),
                  ),
                  'p': Style(
                    textAlign: TextAlign.justify,
                    margin: Margins.only(bottom: 15),
                  ),
                  'em': Style(fontStyle: FontStyle.italic),
                  'i': Style(fontStyle: FontStyle.italic),
                  'a': Style(color: const Color(0xFF08747A)),
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) {
          widget.onTabSelected?.call(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ─── Category screen ─────────────────────────────────────────────────────────

/// Trang các bài báo của một chuyên mục, mở khi bấm tên chuyên mục.
class _CategoryScreen extends StatefulWidget {
  const _CategoryScreen({
    required this.catUid,
    required this.catName,
    required this.onOpenArticle,
    this.onTabSelected,
  });

  final int catUid;
  final String catName;
  final ValueChanged<NewsItem> onOpenArticle;
  final ValueChanged<int>? onTabSelected;

  @override
  State<_CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<_CategoryScreen> {
  static const _uehGreen = Color(0xFF006B78);
  static const _pageSize = 10;

  final _api = NewsApi();
  final _scrollController = ScrollController();
  final List<NewsItem> _items = [];
  // Đoạn mở đầu của từng bài, lấy từ nội dung đầy đủ và nhớ lại theo uid.
  final Map<int, Future<String>> _intros = {};
  int _page = 1;
  int _total = 0;
  bool _isLoading = true;
  Object? _error;

  int get _totalPages => (_total / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Tải trang [page] (đánh số từ 1) rồi cuộn lên đầu danh sách.
  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<NewsItem> items;
      final int total;
      if (widget.catUid == _kFeaturedCatUid) {
        items = await _api.getFeatured();
        total = items.length;
      } else {
        final result = await _api.getNews(
          catUid: widget.catUid,
          limit: _pageSize,
          offset: (page - 1) * _pageSize,
        );
        items = result.items;
        total = result.total;
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _total = total;
        _page = page;
        _isLoading = false;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  /// Đoạn văn đầu tiên có chữ của bài; lỗi hoặc không có thì dùng mô tả ngắn.
  Future<String> _introOf(NewsItem item) {
    return _intros.putIfAbsent(item.uid, () async {
      try {
        final detail = await _api.getNewsDetail(item.uid);
        final doc = html_parser.parse(detail.content);
        for (final p in doc.querySelectorAll('p')) {
          final text = p.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (text.isNotEmpty) return text;
        }
      } catch (_) {}
      return item.shortDesc;
    });
  }

  Widget _body() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _uehGreen));
    }
    if (_error != null) {
      return _ErrorView(
        message: _error.toString(),
        onRetry: () => _loadPage(_page),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          color: _uehGreen,
          onRefresh: () => _loadPage(_page),
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Trang chủ',
                      style: TextStyle(fontSize: 16, color: _uehGreen),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  Text(
                    widget.catName,
                    style: const TextStyle(fontSize: 16, color: _uehGreen),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Không có bài viết nào trong chuyên mục này',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ),
              for (final item in _items)
                _CategoryArticleCard(
                  item: item,
                  intro: _introOf(item),
                  onTap: () => widget.onOpenArticle(item),
                ),
              if (_totalPages > 1)
                _Pager(
                  page: _page,
                  totalPages: _totalPages,
                  onPage: _isLoading ? null : _loadPage,
                ),
            ],
          ),
        ),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: _uehGreen,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: _uehGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Trang chủ'),
      ),
      body: _body(),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) {
          widget.onTabSelected?.call(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Thanh chia trang: Về đầu | 1 2 3 | … | Tới cuối. Hiện cửa sổ 3 số trang quanh trang hiện tại.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  static const _uehGreen = Color(0xFF2E6470);
  static const _border = Color(0xFFDDDDDD);

  final int page;
  final int totalPages;
  final ValueChanged<int>? onPage;

  @override
  Widget build(BuildContext context) {
    final windowSize = totalPages < 3 ? totalPages : 3;
    final start = (page - 1).clamp(1, totalPages - windowSize + 1);
    final end = start + windowSize - 1;

    final cells = <Widget>[
      _cell('Về đầu', enabled: page > 1, onTap: () => onPage?.call(1)),
      for (var p = start; p <= end; p++)
        _cell('$p', selected: p == page, onTap: () => onPage?.call(p)),
      if (end < totalPages)
        _cell('…', onTap: () => onPage?.call(end + 1)),
      _cell(
        'Tới cuối',
        enabled: page < totalPages,
        onTap: () => onPage?.call(totalPages),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < cells.length; i++) ...[
                    if (i > 0) const VerticalDivider(width: 1, color: _border),
                    cells[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String label, {
    bool selected = false,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled && !selected && onPage != null ? onTap : null,
      child: Container(
        color: selected ? _uehGreen : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            color: selected
                ? Colors.white
                : enabled
                ? _uehGreen
                : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}

class _CategoryArticleCard extends StatelessWidget {
  const _CategoryArticleCard({
    required this.item,
    required this.intro,
    required this.onTap,
  });

  final NewsItem item;
  final Future<String> intro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF006B78),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                // Hiện mô tả ngắn trong lúc chờ, rồi thay bằng cả đoạn đầu.
                FutureBuilder<String>(
                  future: intro,
                  initialData: item.shortDesc,
                  builder: (context, snapshot) => _WrappedIntro(
                    imageUrl: item.thumbnailImg,
                    sdgs: item.sdgs,
                    text: snapshot.data ?? '',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hình bên trái, icon SDG rồi đoạn intro bên phải hình; chữ chạy hết bên phải
/// hình thì xuống dưới và trải rộng hết chiều ngang thẻ (kiểu hình float trên web).
class _WrappedIntro extends StatelessWidget {
  const _WrappedIntro({
    required this.imageUrl,
    required this.sdgs,
    required this.text,
  });

  static const _style = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: Color(0xFF171717),
  );
  static const _gap = 14.0;
  static const _sdgSize = 36.0;
  static const _sdgSpacing = 4.0;

  final String imageUrl;
  final List<int> sdgs;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final imageWidth = width * 0.38;
        final imageHeight = imageWidth * 2 / 3;
        final rightWidth = width - imageWidth - _gap;

        final sdgCount = sdgs.where((s) => s >= 1 && s <= _sdgAssetCount).length;
        final perRow = ((rightWidth + _sdgSpacing) / (_sdgSize + _sdgSpacing))
            .floor()
            .clamp(1, 17);
        final sdgRows = sdgCount == 0 ? 0 : (sdgCount / perRow).ceil();
        final sdgHeight = sdgRows == 0
            ? 0.0
            : sdgRows * _sdgSize + (sdgRows - 1) * _sdgSpacing + 8;

        // Số dòng chữ nằm vừa bên phải hình, phần còn lại xuống dưới.
        final lineHeight = _style.fontSize! * _style.height!;
        final fitLines = ((imageHeight - sdgHeight) / lineHeight).floor();

        var beside = '';
        var below = text;
        if (fitLines > 0 && text.isNotEmpty) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: _style),
            textDirection: TextDirection.ltr,
            maxLines: fitLines,
          )..layout(maxWidth: rightWidth);
          if (painter.didExceedMaxLines) {
            final cut = painter
                .getPositionForOffset(
                  Offset(rightWidth, (fitLines - 0.5) * lineHeight),
                )
                .offset;
            beside = text.substring(0, cut).trimRight();
            below = text.substring(cut).trimLeft();
          } else {
            beside = text;
            below = '';
          }
          painter.dispose();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: _NetworkImage(url: imageUrl),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sdgRows > 0) ...[
                        _SdgChips(sdgs: sdgs, size: _sdgSize),
                        const SizedBox(height: 8),
                      ],
                      if (beside.isNotEmpty) Text(beside, style: _style),
                    ],
                  ),
                ),
              ],
            ),
            if (below.isNotEmpty)
              Text(below, style: _style, textAlign: TextAlign.justify),
          ],
        );
      },
    );
  }
}
