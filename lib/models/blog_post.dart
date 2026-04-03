/// 블로그 포스트 데이터 모델
class BlogPost {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String marketingCopy;
  final String content;        // Markdown 원문
  final String region;
  final String festivalName;
  final String imageUrl;
  final String affiliateLink;
  final String affillateLinkText;
  final String festivalAffiliateLink;
  final String festivalAffiliateLinkText;
  final DateTime publishedAt;
  final DateTime festivalStart;
  final DateTime festivalEnd;
  final List<String> tags;
  final SeoMeta seo;

  const BlogPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.marketingCopy,
    required this.content,
    required this.region,
    required this.festivalName,
    required this.imageUrl,
    required this.affiliateLink,
    required this.affillateLinkText,
    required this.festivalAffiliateLink,
    required this.festivalAffiliateLinkText,
    required this.publishedAt,
    required this.festivalStart,
    required this.festivalEnd,
    required this.tags,
    required this.seo,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String,
      marketingCopy: json['marketingCopy'] as String? ?? json['excerpt'] as String,
      content: json['content'] as String,
      region: json['region'] as String,
      festivalName: json['festivalName'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      affiliateLink: json['affiliateLink'] as String? ?? '',
      affillateLinkText: json['affiliateLinkText'] as String? ?? '여행 최적가 확인하기',
        festivalAffiliateLink: json['festivalAffiliateLink'] as String? ?? '',
        festivalAffiliateLinkText:
          json['festivalAffiliateLinkText'] as String? ?? '입장권/투어 확인하기',
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      festivalStart: DateTime.parse(json['festivalStart'] as String),
      festivalEnd: DateTime.parse(json['festivalEnd'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
      seo: SeoMeta.fromJson(json['seo'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'excerpt': excerpt,
        'marketingCopy': marketingCopy,
        'content': content,
        'region': region,
        'festivalName': festivalName,
        'imageUrl': imageUrl,
        'affiliateLink': affiliateLink,
        'affiliateLinkText': affillateLinkText,
        'festivalAffiliateLink': festivalAffiliateLink,
        'festivalAffiliateLinkText': festivalAffiliateLinkText,
        'publishedAt': publishedAt.toIso8601String(),
        'festivalStart': festivalStart.toIso8601String(),
        'festivalEnd': festivalEnd.toIso8601String(),
        'tags': tags,
        'seo': seo.toJson(),
      };

  /// D-Day 계산 (축제 시작까지 남은 일수)
  int get daysUntilFestival {
    final now = DateTime.now();
    if (festivalStart.isBefore(now) && festivalEnd.isAfter(now)) return 0;
    if (festivalEnd.isBefore(now)) return -1;
    return festivalStart.difference(now).inDays;
  }

  bool get isOngoing {
    final now = DateTime.now();
    return festivalStart.isBefore(now) && festivalEnd.isAfter(now);
  }

  bool get isUpcoming => festivalStart.isAfter(DateTime.now());
}

/// SEO 메타데이터
class SeoMeta {
  final String metaTitle;
  final String metaDescription;
  final String keywords;
  final String ogImage;

  const SeoMeta({
    required this.metaTitle,
    required this.metaDescription,
    required this.keywords,
    required this.ogImage,
  });

  factory SeoMeta.fromJson(Map<String, dynamic> json) => SeoMeta(
        metaTitle: json['metaTitle'] as String? ?? '',
        metaDescription: json['metaDescription'] as String? ?? '',
        keywords: json['keywords'] as String? ?? '',
        ogImage: json['ogImage'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'metaTitle': metaTitle,
        'metaDescription': metaDescription,
        'keywords': keywords,
        'ogImage': ogImage,
      };
}
