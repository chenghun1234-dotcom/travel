import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seo_renderer/seo_renderer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_blog/models/blog_post.dart';
import 'package:travel_blog/services/blog_service.dart';
import 'package:travel_blog/theme/app_theme.dart';
import 'package:travel_blog/widgets/seo_widgets.dart';

class PostDetailScreen extends StatefulWidget {
  final String slug;
  const PostDetailScreen({super.key, required this.slug});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  BlogPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final post = await BlogService.instance.getPostBySlug(widget.slug);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_post == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('포스트를 찾을 수 없습니다.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(post),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 40 : 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMeta(post),
                      const SizedBox(height: 24),
                      _buildMarkdownBody(post),
                      const SizedBox(height: 40),
                      _buildAffiliateCard(post),
                      const SizedBox(height: 40),
                      _buildShareSection(post),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BlogPost post) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => context.go('/'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          post.festivalName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
        background: post.imageUrl.isNotEmpty
            ? SeoImage(
                src: post.imageUrl,
                alt: '${post.festivalName} 대표 이미지',
                child: Image.network(post.imageUrl, fit: BoxFit.cover),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => Share.share(
            '🎉 ${post.title}\n\n${post.excerpt}\n\nhttps://your-blog.github.io/post/${post.slug}',
          ),
        ),
      ],
    );
  }

  Widget _buildMeta(BlogPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeoText(
          text: post.title,
          tag: RenderTag.h1,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _infoChip(Icons.location_on, post.region, AppTheme.primary),
            _infoChip(
              Icons.calendar_today,
              '${DateFormat('MM.dd').format(post.festivalStart)} ~ ${DateFormat('MM.dd').format(post.festivalEnd)}',
              AppTheme.secondary,
            ),
            if (post.isOngoing)
              _infoChip(Icons.fiber_manual_record, '진행 중', AppTheme.accent)
            else if (post.isUpcoming)
              _infoChip(Icons.timer, 'D-${post.daysUntilFestival}', AppTheme.secondary),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: post.tags
              .map((t) => Chip(
                    label: Text('#$t',
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMarkdownBody(BlogPost post) {
    return MarkdownBody(
      data: post.content,
      styleSheet: MarkdownStyleSheet(
        h1: Theme.of(context).textTheme.headlineMedium,
        h2: Theme.of(context).textTheme.titleLarge,
        p: Theme.of(context).textTheme.bodyLarge,
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 4),
          ),
          color: AppTheme.primary.withOpacity(0.05),
        ),
      ),
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      },
    );
  }

  /// 마이리얼트립 제휴 링크 카드
  Widget _buildAffiliateCard(BlogPost post) {
    if (post.affiliateLink.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondary.withOpacity(0.15),
            AppTheme.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✈️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${post.region} 여행을 계획 중이신가요?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '축제 기간에 맞춰 숙소와 현지 투어를 지금 바로 예약하세요. 인기 숙소는 조기 마감될 수 있습니다!',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(post.affiliateLink);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.hotel, size: 18),
                  label: Text(post.affillateLinkText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (post.festivalAffiliateLink.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(post.festivalAffiliateLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.confirmation_num_outlined, size: 18),
                    label: Text(post.festivalAffiliateLinkText),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  '※ 파트너 활동의 일환으로 수수료를 제공받을 수 있음',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BlogPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이 글이 도움이 되었나요? 공유해 주세요 🙌',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => Share.share(
                '🎉 ${post.title}\nhttps://your-blog.github.io/post/${post.slug}',
              ),
              icon: const Icon(Icons.share),
              label: const Text('공유하기'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('더 많은 축제 보기'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
