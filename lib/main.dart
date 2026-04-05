import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_blog/screens/home_screen.dart';
import 'package:travel_blog/screens/post_detail_screen.dart';
import 'package:travel_blog/screens/calendar_screen.dart';
import 'package:travel_blog/screens/regions_screen.dart';
import 'package:travel_blog/theme/app_theme.dart';

void main() {
  runApp(const TravelBlogApp());
}

/// GoRouter 설정 - SEO를 위해 path 기반 URL 사용
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/post/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return PostDetailScreen(slug: slug);
      },
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/regions',
      builder: (context, state) => const RegionsScreen(),
    ),
  ],
  // SEO: 404 fallback
  errorBuilder: (context, state) => const HomeScreen(),
);

class TravelBlogApp extends StatelessWidget {
  const TravelBlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '한국 축제 여행 블로그 | KoreaFestivalTrip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
