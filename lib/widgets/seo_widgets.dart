import 'package:flutter/material.dart';
import 'package:seo_renderer/seo_renderer.dart';

// TextRendererStyle을 seo_widgets.dart를 임포트한 파일에서도 사용할 수 있도록 re-export
export 'package:seo_renderer/seo_renderer.dart' show TextRendererStyle;

/// SEO용 텍스트 위젯 — TextRenderer(0.6.0 API) 래퍼
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
    return TextRenderer(
      style: tag,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}

/// SEO용 이미지 위젯 — ImageRenderer(0.6.0 API) 래퍼
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
    return ImageRenderer(
      alt: alt,
      src: src,
      child: child,
    );
  }
}