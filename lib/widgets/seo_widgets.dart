import 'package:flutter/material.dart';
import 'package:seo_renderer/seo_renderer.dart';

class SeoText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final RenderTag tag;
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
    return RendererWidgets.text(
      text: text,
      style: style,
      tag: tag,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

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
    return RendererWidgets.image(
      src: src,
      alt: alt,
      child: child,
    );
  }
}