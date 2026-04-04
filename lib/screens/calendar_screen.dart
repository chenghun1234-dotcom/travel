import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_blog/models/blog_post.dart';
import 'package:travel_blog/services/blog_service.dart';
import 'package:travel_blog/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<BlogPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = BlogService.instance.getAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('축제 캘린더')),
      body: FutureBuilder<List<BlogPost>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = [...snapshot.data!]
            ..sort((a, b) => a.festivalStart.compareTo(b.festivalStart));
          if (posts.isEmpty) {
            return const Center(child: Text('축제 데이터가 없습니다.'));
          }

          final grouped = <String, List<BlogPost>>{};
          for (final p in posts) {
            final key = DateFormat('yyyy년 MM월').format(p.festivalStart);
            grouped.putIfAbsent(key, () => []).add(p);
          }

          final keys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final month = keys[index];
              final monthPosts = grouped[month]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  title: Text(
                    month,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${monthPosts.length}개 축제'),
                  children: monthPosts.map((post) {
                    return ListTile(
                      title: Text(post.festivalName),
                      subtitle: Text(
                        '${post.region} · '
                        '${DateFormat('MM.dd').format(post.festivalStart)} ~ ${DateFormat('MM.dd').format(post.festivalEnd)}',
                      ),
                      trailing: post.isOngoing
                          ? const Text('진행중', style: TextStyle(color: Colors.green))
                          : (post.daysUntilFestival >= 0
                              ? Text('D-${post.daysUntilFestival}')
                              : const SizedBox.shrink()),
                      onTap: () => context.go('/post/${post.slug}'),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
