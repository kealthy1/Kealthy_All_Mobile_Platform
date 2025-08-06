import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/blog/blog1.dart';
import 'package:kealthy/view/blog/blogs_tile.dart';

class BlogListPage extends ConsumerWidget {
  const BlogListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogState = ref.watch(blogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        titleSpacing: 12,
        toolbarHeight: 75,
        title: Text(
          'Kealthy Blogs',
          style: GoogleFonts.poppins(
            color: const Color(0xFF273847),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: blogState.when(
        data: (blogs) {
          blogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return BlogListTile(
                blog: blog,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => BlogDetailsPage(blog: blog),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
            child: CupertinoActivityIndicator(
          color: Color(0xFF273847),
        )),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class BlogDetailsPage extends StatelessWidget {
  final Blog blog;

  const BlogDetailsPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          titleSpacing: 18,
          surfaceTintColor: Colors.white,
          title: Text(
            'Blogs For You',
            style: GoogleFonts.poppins(
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white),
      body: BlogCard(blog: blog),
    );
  }
}
