import 'package:flutter/material.dart';
import 'package:seo_renderer/seo_renderer.dart';
import 'package:travel_blog/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('블로그 소개')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextRenderer(
                  text: const Text(
                    '🇰🇷 한국 축제 여행 블로그란?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),
                TextRenderer(
                  text: const Text(
                    '한국관광공사 TourAPI 4.0과 Google Gemini AI를 활용하여 '
                    '전국 각지의 축제 정보를 매일 자동으로 업데이트하는 블로그입니다. '
                    '단순한 일정 나열이 아닌, 실제 여행자의 시선으로 작성된 감성적인 여행 가이드를 제공합니다.',
                    style: TextStyle(fontSize: 15, height: 1.8),
                  ),
                ),
                const SizedBox(height: 32),
                _buildFeatureRow(
                    '🤖', 'AI 자동화', 'Gemini 1.5 Flash가 매일 아침 새로운 축제 글을 작성합니다.'),
                _buildFeatureRow(
                    '🗂️', '공식 데이터', '한국관광공사 TourAPI 4.0으로 정확한 정보를 수집합니다.'),
                _buildFeatureRow(
                    '🔗', '여행 예약', '마이리얼트립 파트너 링크로 최적가 숙소와 투어를 연결합니다.'),
                _buildFeatureRow(
                    '📱', '최적화', 'Flutter Web으로 모바일·데스크톱 모두 완벽 지원합니다.'),
              ],
            ),
          ),
        ),
      ),
    );
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
