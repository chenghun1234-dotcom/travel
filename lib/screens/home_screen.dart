import 'package:flutter/material.dart';
import 'package:travel_blog/models/blog_post.dart';
import 'package:travel_blog/services/blog_service.dart';
import 'package:travel_blog/widgets/festival_card.dart';
import 'package:travel_blog/widgets/seo_widgets.dart';
import 'package:travel_blog/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BlogPost> _posts = [];
  List<BlogPost> _filtered = [];
  bool _isLoading = true;
  String _selectedRegion = '전체';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _regions = ['전체', '서울', '부산', '제주', '전주', '강릉', '경주', '인천', '수원', '안동'];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final posts = await BlogService.instance.getAllPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _filtered = posts;
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _posts.where((p) {
        final matchesRegion =
            _selectedRegion == '전체' || p.region == _selectedRegion;
        final matchesSearch = _searchQuery.isEmpty ||
            p.title.contains(_searchQuery) ||
            p.festivalName.contains(_searchQuery);
        return matchesRegion && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildRegionFilter()),
          SliverToBoxAdapter(child: _buildSectionTitle('✨ 이번 달 축제')),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : isWide
                      ? _buildWideGrid()
                      : _buildMobileList(),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          const Text('🇰🇷', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const SeoText(
            text: '한국 축제 여행',
            tag: RenderTag.h2,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () {}, child: const Text('축제 캘린더')),
        TextButton(onPressed: () {}, child: const Text('지역별')),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SeoText(
              text: '🎉 대한민국 축제 여행 가이드',
              tag: RenderTag.h1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const SeoText(
              text: 'AI가 매일 업데이트하는 전국 축제 정보',
              tag: RenderTag.p,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '축제명, 지역을 검색하세요',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (v) {
          _searchQuery = v;
          _applyFilter();
        },
      ),
    );
  }

  Widget _buildRegionFilter() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _regions.length,
        itemBuilder: (context, i) {
          final region = _regions[i];
          final isSelected = region == _selectedRegion;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(region),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedRegion = region);
                _applyFilter();
              },
              selectedColor: AppTheme.primary.withOpacity(0.15),
              checkmarkColor: AppTheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  SliverGrid _buildWideGrid() {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => FestivalCard(post: _filtered[index]),
        childCount: _filtered.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
    );
  }

  SliverList _buildMobileList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => FestivalCard(post: _filtered[index]),
        childCount: _filtered.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('검색 결과가 없습니다.\n다른 키워드로 검색해 보세요.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(24),
      color: AppTheme.textPrimary,
      child: const Column(
        children: [
          Text('🇰🇷 한국 축제 여행 블로그',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('AI가 매일 업데이트 · 한국관광공사 TourAPI 4.0 활용',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          SizedBox(height: 8),
          Text('© 2026 KoreaFestivalTrip. Powered by Gemini 1.5 Flash & Flutter',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
