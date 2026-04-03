import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_blog/models/blog_post.dart';
import 'package:travel_blog/theme/app_theme.dart';
import 'package:travel_blog/widgets/seo_widgets.dart';

class PostCard extends StatelessWidget {
  final BlogPost post;
  final bool isFeatured;

  const PostCard({super.key, required this.post, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/post/${post.slug}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: isFeatured ? 16 / 9 : 4 / 3,
          child: post.imageUrl.isNotEmpty
              ? SeoImage(
                  src: post.imageUrl,
                  alt: '${post.festivalName} 썸네일',
                  child: Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  ),
                )
              : _placeholderImage(),
        ),
        // D-Day 뱃지
        if (post.isOngoing)
          Positioned(
            top: 12,
            left: 12,
            child: _badge('진행 중 🎉', AppTheme.accent),
          )
        else if (post.isUpcoming && post.daysUntilFestival <= 7)
          Positioned(
            top: 12,
            left: 12,
            child: _badge('D-${post.daysUntilFestival}', AppTheme.secondary),
          ),
        // 지역 뱃지
        Positioned(
          top: 12,
          right: 12,
          child: _badge('📍 ${post.region}', Colors.black54),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeoText(
            text: post.title,
            tag: TextRendererStyle.header2,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SeoText(
            text: post.marketingCopy.isNotEmpty ? post.marketingCopy : post.excerpt,
            tag: TextRendererStyle.paragraph,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MM.dd').format(post.festivalStart)} ~ '
                '${DateFormat('MM.dd').format(post.festivalEnd)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                DateFormat('yyyy.MM.dd').format(post.publishedAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          // 태그
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.tags
                  .take(3)
                  .map((tag) => _tagChip(context, tag))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagChip(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppTheme.primary.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.landscape, size: 64, color: AppTheme.primary.withOpacity(0.4)),
      ),
    );
  }
}
