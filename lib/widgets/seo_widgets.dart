import 'package:flutter/material.dart';

// seo_renderer 패키지는 Flutter 3.22+ (dart:html 제거)와 호환되지 않아 제거됨.
// SEO는 web/index.html 메타 태그 + JSON-LD + sitemap.xml 방식으로 처리.

/// TextRendererStyle stub — 기존 코드 호환성을 위해 유지
enum TextRendererStyle { header1, header2, header3, header4, header5, header6, paragraph }

/// SEO용 텍스트 위젯 stub — seo_renderer 없이 일반 Text로 렌더링
class SeoText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextRendererStyle tag;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const SeoText({
    super.key,
    required this.text,
    required this.tag,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// SEO용 이미지 위젯 stub — child를 그대로 렌더링
class SeoImage extends StatelessWidget {
  final String src;
  final String alt;
  final Widget child;

  const SeoImage({
    super.key,
    required this.src,
    required this.alt,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}