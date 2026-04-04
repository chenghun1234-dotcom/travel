import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_blog/models/blog_post.dart';
import 'package:travel_blog/services/blog_service.dart';
import 'package:travel_blog/theme/app_theme.dart';

class RegionsScreen extends StatefulWidget {
  const RegionsScreen({super.key});

  @override
  State<RegionsScreen> createState() => _RegionsScreenState();
}

class _RegionsScreenState extends State<RegionsScreen> {
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
      appBar: AppBar(title: const Text('지역별 축제')),
      body: FutureBuilder<List<BlogPost>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('축제 데이터가 없습니다.'));
          }

          final grouped = <String, List<BlogPost>>{};
          for (final p in posts) {
            grouped.putIfAbsent(p.region, () => []).add(p);
          }

          final regions = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final region = regions[index];
              final regionPosts = grouped[region]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    region,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${regionPosts.length}개 축제'),
                  children: regionPosts.map((post) {
                    return ListTile(
                      title: Text(post.festivalName),
                      subtitle: Text(post.title),
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
