import 'package:flutter/material.dart';
import 'package:seo_renderer/seo_renderer.dart';
import 'package:travel_blog/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('블로그 소개'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RendererWidgets.text(
                  tag: RenderTag.h1,
                  text: '🇰🇷 한국 축제 여행 블로그란?',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                RendererWidgets.text(
                  tag: RenderTag.p,
                  text:
                      '한국관광공사 TourAPI 4.0과 Google Gemini AI를 활용하여 '
                      '전국 각지의 축제 정보를 매일 자동으로 업데이트하는 블로그입니다. '
                      '단순한 일정 나열이 아닌, 실제 여행자의 시선으로 작성된 감성적인 여행 가이드를 제공합니다.',
                  style: const TextStyle(fontSize: 15, height: 1.8),
                ),
                const SizedBox(height: 32),
                _buildDivider('✨ 주요 기능'),
                const SizedBox(height: 16),
                _buildFeatureRow('🤖', 'AI 자동화',
                    'Gemini 1.5 Flash가 매일 아침 새로운 축제 글을 작성합니다.'),
                _buildFeatureRow('🗂️', '공식 데이터',
                    '한국관광공사 TourAPI 4.0으로 정확하고 신뢰할 수 있는 정보를 수집합니다.'),
                _buildFeatureRow('🔗', '여행 예약',
                    '마이리얼트립 파트너 링크로 최적가 숙소·투어·입장권을 바로 연결합니다.'),
                _buildFeatureRow('🔍', 'SEO 최적화',
                    'seo_renderer 패키지로 구글·네이버 봇이 콘텐츠를 정확히 읽도록 처리합니다.'),
                _buildFeatureRow('📱', '크로스플랫폼',
                    'Flutter Web으로 모바일·태블릿·데스크톱 모두 완벽 지원합니다.'),
                const SizedBox(height: 32),
                _buildDivider('💡 운영 방식'),
                const SizedBox(height: 16),
                _buildStepCard('1', 'TourAPI 데이터 수집',
                    '매일 오전 6시 GitHub Actions가 전국 축제 데이터를 자동 수집합니다.'),
                _buildStepCard('2', 'AI 블로그 글 생성',
                    'Gemini 1.5 Flash가 여행자 시선의 감성적인 블로그 포스트를 작성합니다.'),
                _buildStepCard('3', 'SEO 메타 업데이트',
                    '검색 엔진에 노출될 수 있도록 제목·설명·키워드를 자동 갱신합니다.'),
                _buildStepCard('4', 'GitHub Pages 배포',
                    'Flutter Web 빌드 후 GitHub Pages로 무료 자동 배포됩니다.'),
                const SizedBox(height: 40),
                _buildNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(width: 12),
      const Expanded(child: Divider()),
    ]);
  }

  Widget _buildFeatureRow(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RendererWidgets.text(
                  tag: RenderTag.h2,
                  text: title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String step, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Text('ℹ️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '본 블로그는 마이리얼트립 파트너 활동의 일환으로 ''
              '일부 링크 클릭 시 수수료를 제공받을 수 있습니다.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
