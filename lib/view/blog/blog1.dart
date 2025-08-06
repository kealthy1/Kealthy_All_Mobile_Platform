import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final blogProvider = FutureProvider<List<Blog>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('blogs').get();

  return snapshot.docs.map((doc) {
    return Blog.fromFirestore(doc);
  }).toList();
});

class Blog {
  final String id;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
  });

  factory Blog.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Blog(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class BlogPage extends ConsumerWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogState = ref.watch(blogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Blogs For You',
          style: GoogleFonts.poppins(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF273847),
      ),
      body: blogState.when(
        data: (blogs) {
          final today = DateTime.now();
          final todayBlogs = blogs
              .where((blog) =>
                  blog.createdAt.year == today.year &&
                  blog.createdAt.month == today.month &&
                  blog.createdAt.day == today.day)
              .toList();
          final otherBlogs = blogs
              .where((blog) => !todayBlogs.contains(blog))
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayBlogs.isNotEmpty)
                  _buildSection("Today's Blogs", todayBlogs),
                if (otherBlogs.isNotEmpty) ..._buildOtherSections(otherBlogs),
              ],
            ),
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

  Widget _buildSection(String title, List<Blog> blogs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: blogs.map((blog) => BlogCard(blog: blog)).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOtherSections(List<Blog> blogs) {
    final groupedBlogs = <String, List<Blog>>{};
    final dateFormatter = DateFormat('EEEE, MMM d');

    for (var blog in blogs) {
      final formattedDate = dateFormatter.format(blog.createdAt);
      groupedBlogs.putIfAbsent(formattedDate, () => []).add(blog);
    }

    return groupedBlogs.entries.map((entry) {
      return _buildSection(entry.key, entry.value);
    }).toList();
  }
}

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.imageUrls.isNotEmpty)
              Hero(
                tag: blog.id,
                child: ClipRRect(
                  child: CachedNetworkImage(
                    cacheManager: DefaultCacheManager(),
                    imageUrl: blog.imageUrls[0],
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 0.56,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      height: 200,
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  blog.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 800),
                child: Text(
                  blog.content,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.7,
                    // letterSpacing: 0.3,
                    // fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Text(
                "By Kealthy",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
