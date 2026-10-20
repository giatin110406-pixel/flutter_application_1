import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
  static const _pageSize = 10;
  static const _loadMoreThreshold = 300.0;

  final _api = NewsApi();
  final _scrollController = ScrollController();

  int _selectedCatUid = NewsApi.defaultCatUid;
  String _selectedCatName = 'Cuộc sống UEH';
  bool _isCategoryLoading = false;

  List<NewsItem> _featured = const [];
  final List<NewsItem> _items = [];
  int _total = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  Object? _initialError;

  // Tăng số này mỗi lần tải lại để bỏ qua kết quả của request cũ.
  int _generation = 0;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Tải tin nổi bật và trang đầu của danh mục song song.
  Future<void> _loadInitial() async {
    final generation = ++_generation;
    setState(() {
      _isInitialLoading = true;
      _initialError = null;
    });

    try {
      final featured = await _api.getFeatured();
      final page = await _api.getNews(
        catUid: _selectedCatUid,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted || generation != _generation) return;

      setState(() {
        _featured = featured;
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
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

  /// Chuyển đổi chuyên mục khi bấm vào Category Chip hoặc tên chuyên mục ở thẻ tin.
  Future<void> _selectCategory(
    int catUid, [
    String? catName,
    bool scrollToCategory = false,
  ]) async {
    final name = catName ??
        _kUehCategories
            .firstWhere(
              (c) => c.catUid == catUid,
              orElse: () =>
                  NewsCategory(catUid: catUid, name: 'Chuyên mục $catUid'),
            )
            .name;

    if (_selectedCatUid == catUid && _items.isNotEmpty) {
      if (scrollToCategory && _scrollController.hasClients) {
        _scrollController.animateTo(
          500,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    final generation = ++_generation;
    setState(() {
      _selectedCatUid = catUid;
      _selectedCatName = name;
      _items.clear();
      _total = 0;
      _isCategoryLoading = true;
    });

    if (scrollToCategory && _scrollController.hasClients) {
      _scrollController.animateTo(
        500,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }

    try {
      final page = await _api.getNews(
        catUid: catUid,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _isCategoryLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _isCategoryLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được tin chuyên mục: $error')),
      );
    }
  }

  /// Lazy load: lấy trang kế tiếp khi người dùng cuộn gần cuối danh sách.
  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || _isCategoryLoading || !_hasMore) return;
    final generation = _generation;
    setState(() => _isLoadingMore = true);

    try {
      final page = await _api.getNews(
        catUid: _selectedCatUid,
        limit: _pageSize,
        offset: _items.length,
      );
      if (!mounted || generation != _generation) return;

      setState(() {
        _items.addAll(page.items);
        // Nếu API trả rỗng dù total còn lớn, dừng lại để không gọi lặp vô hạn.
        _total = page.items.isEmpty ? _items.length : page.total;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải thêm được tin: $error')),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      _loadMore();
    }
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
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            const SliverToBoxAdapter(child: _Header()),

            // ── Tin nổi bật: 1 tin lớn + 4 tin nhỏ ──────────────────────────
            if (_featured.isNotEmpty)
              SliverToBoxAdapter(
                child: _FeaturedSection(
                  featured: _featured,
                  onTap: _openDetail,
                  onCategoryTap: (catUid, catName) =>
                      _selectCategory(catUid, catName, true),
                ),
              ),

            // ── Tiêu đề danh mục tin tức ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _uehGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCatName.toUpperCase(),
                        style: const TextStyle(
                          color: _uehGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Danh sách tin hoặc trạng thái tải chuyên mục ────────────────
            if (_isCategoryLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: _uehGreen),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Không có bài viết nào trong chuyên mục này',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _items[index];
                      return _NewsListTile(
                        item: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),

            // ── Footer: spinner khi đang tải, thông báo khi hết ──────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(color: _uehGreen)
                      : !_hasMore && _items.isNotEmpty
                      ? const Text(
                          'Đã tải hết tin',
                          style: TextStyle(color: Color(0xFF999999)),
                        )
                      : const SizedBox.shrink(),
                ),
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
              color: Color(0xFF006B78),
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
    required this.featured,
    required this.onTap,
    required this.onCategoryTap,
  });

  final List<NewsItem> featured;
  final ValueChanged<NewsItem> onTap;
  final void Function(int catUid, String catName) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final hero = featured.first;
    final smallItems = featured.skip(1).take(4).toList();

    return Container(
      color: const Color(0xFFF4F7F8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          _HeroCard(
            item: hero,
            onTap: () => onTap(hero),
            onCategoryTap: hero.catUid > 0
                ? () => onCategoryTap(hero.catUid, hero.categoryName)
                : null,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.64,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final item in smallItems)
                _SmallCard(
                  item: item,
                  onTap: () => onTap(item),
                  onCategoryTap: () {
                    int catUid = item.catUid;
                    String catName = item.categoryName;
                    if (catUid <= 0) {
                      final match = _kUehCategories.firstWhere(
                        (c) =>
                            c.name.toLowerCase() ==
                            catName.trim().toLowerCase(),
                        orElse: () => const NewsCategory(
                          catUid: 219,
                          name: 'Cuộc sống UEH',
                        ),
                      );
                      catUid = match.catUid;
                      catName = match.name;
                    }
                    onCategoryTap(catUid, catName);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.item,
    required this.onTap,
    this.onCategoryTap,
  });

  final NewsItem item;
  final VoidCallback onTap;
  final VoidCallback? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Tin không có ảnh nền thì dùng thumbnail thay thế.
            _NetworkImage(
              url: item.backgroundImg.isNotEmpty
                  ? item.backgroundImg
                  : item.thumbnailImg,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.categoryName.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onCategoryTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006B78),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categoryName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SdgChips(sdgs: item.sdgs),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.item,
    required this.onTap,
    required this.onCategoryTap,
  });

  final NewsItem item;
  final VoidCallback onTap;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    // Tên chuyên mục in hoa (VD: CUỘC SỐNG UEH, KHOA HỌC - GÓC NHÌN CHUYÊN GIA...)
    final categoryText = item.categoryName.isNotEmpty
        ? item.categoryName.toUpperCase()
        : 'CHUYÊN MỤC';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _NetworkImage(url: item.thumbnailImg),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng chữ xanh in hoa tên chuyên mục theo đúng web tintucmobile Thầy chiếu
                    InkWell(
                      onTap: onCategoryTap,
                      borderRadius: BorderRadius.circular(2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                categoryText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF005F69),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: Color(0xFF005F69),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SdgChips(sdgs: item.sdgs, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List tile ───────────────────────────────────────────────────────────────

class _NewsListTile extends StatelessWidget {
  const _NewsListTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                height: 84,
                child: _NetworkImage(url: item.thumbnailImg),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.categoryName.isNotEmpty)
                        Text(
                          item.categoryName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF006B78),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 6),
                      _SdgChips(sdgs: item.sdgs, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
