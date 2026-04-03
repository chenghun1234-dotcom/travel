import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:travel_blog/models/blog_post.dart';

/// GitHub Pages에서 JSON 포스트 목록을 불러오는 서비스
class BlogService {
  // 로컬 assets 에서 포스트 인덱스 로드 (빌드 시 포함된 파일)
  static const String _postsIndexPath = 'assets/posts/index.json';
  static const String _festivalDataPath = 'assets/data/festivals.json';

  static BlogService? _instance;
  static BlogService get instance => _instance ??= BlogService._();
  BlogService._();

  List<BlogPost> _cachedPosts = [];
  bool _loaded = false;

  /// 전체 포스트 목록 로드
  Future<List<BlogPost>> getAllPosts() async {
    if (_loaded) return _cachedPosts;
    try {
      final jsonStr = await rootBundle.loadString(_postsIndexPath);
      final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
      _cachedPosts = data
          .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      _loaded = true;
    } catch (_) {
      _cachedPosts = [];
    }
    return _cachedPosts;
  }

  /// 슬러그로 단일 포스트 조회
  Future<BlogPost?> getPostBySlug(String slug) async {
    final posts = await getAllPosts();
    try {
      return posts.firstWhere((p) => p.slug == slug);
    } catch (_) {
      return null;
    }
  }

  /// 지역 필터링
  Future<List<BlogPost>> getPostsByRegion(String region) async {
    final posts = await getAllPosts();
    return posts.where((p) => p.region == region).toList();
  }

  /// 진행 중인 축제 포스트
  Future<List<BlogPost>> getOngoingFestivalPosts() async {
    final posts = await getAllPosts();
    return posts.where((p) => p.isOngoing).toList();
  }

  /// 예정된 축제 포스트
  Future<List<BlogPost>> getUpcomingFestivalPosts() async {
    final posts = await getAllPosts();
    return posts.where((p) => p.isUpcoming).toList();
  }

  /// 검색
  Future<List<BlogPost>> searchPosts(String query) async {
    final posts = await getAllPosts();
    final q = query.toLowerCase();
    return posts.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.region.toLowerCase().contains(q) ||
          p.festivalName.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  void invalidateCache() {
    _loaded = false;
    _cachedPosts = [];
  }

  /// 단순 JSON 포맷 로드 (assets/data/festivals.json)
  /// - 요청 예시의 List<dynamic> 구조와 호환
  Future<List<Map<String, dynamic>>> loadFestivalFeed() async {
    try {
      final jsonStr = await rootBundle.loadString(_festivalDataPath);
      final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (_) {
      // 폴백: 기존 posts/index.json 데이터 기반으로 생성
      final posts = await getAllPosts();
      return posts
          .map(
            (p) => {
              'id': p.id,
              'slug': p.slug,
              'title': p.title,
              'image': p.imageUrl,
              'date':
                  '${p.festivalStart.toIso8601String().split('T').first} ~ ${p.festivalEnd.toIso8601String().split('T').first}',
              'location': p.region,
              'content': p.content,
              'affiliate_link': p.affiliateLink,
            },
          )
          .toList(growable: false);
    }
  }
}
