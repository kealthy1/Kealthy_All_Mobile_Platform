import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/custom_alert_dialogue.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/blog/blog.dart';
import 'package:kealthy/view/blog/blog1.dart';
import 'package:kealthy/view/blog/blogs_tile.dart';

final blogFilterProvider = StateProvider<String>((ref) => 'All');

class BlogVerticalListPage extends ConsumerWidget {
  const BlogVerticalListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogState = ref.watch(blogProvider);
    final selectedFilter = ref.watch(blogFilterProvider);

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
        actions: [
          DropdownButton<String>(
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list, color: Color(0xFF273847)),
            items: <String>['All', 'This Month', 'This Week']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(color: const Color(0xFF273847)),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                ref.read(blogFilterProvider.notifier).state = newValue;
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: blogState.when(
        data: (blogs) {
          List filteredBlogs = List.from(blogs);
          filteredBlogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final now = DateTime.now();
          if (selectedFilter == 'This Month') {
            filteredBlogs = filteredBlogs.where((blog) {
              final createdAt = blog.createdAt;
              return createdAt.year == now.year && createdAt.month == now.month;
            }).toList();
          } else if (selectedFilter == 'This Week') {
            filteredBlogs = filteredBlogs.where((blog) {
              final createdAt = blog.createdAt;
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 7));
              return createdAt.isAfter(
                      startOfWeek.subtract(const Duration(seconds: 1))) &&
                  createdAt.isBefore(endOfWeek);
            }).toList();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: filteredBlogs.length,
            itemBuilder: (context, index) {
              final blog = filteredBlogs[index];
              final likesState = ref.watch(blogLikesProvider(blog.id));
              final blogNotifier =
                  ref.read(blogLikesProvider(blog.id).notifier);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => BlogDetailsPage(blog: blog),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (blog.imageUrls.isNotEmpty)
                        Hero(
                          tag: blog.id,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  cacheManager: DefaultCacheManager(),
                                  imageUrl: blog.imageUrls[0],
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 80,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    width: 100,
                                    height: 80,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      DateFormat('d MMMM')
                                          .format(blog.createdAt),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.title,
                              maxLines: 2,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await blogNotifier.toggleLikeAsync();
                                    } catch (e) {
                                      if (e.toString().contains(
                                          "User phone number not found")) {
                                        CustomAlertDialog.show(
                                          context: context,
                                          title: "Login Required",
                                          message:
                                              "You need to log in to like this blog and save your preferences.",
                                          confirmText: "Login",
                                          onConfirm: () {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginFields()),
                                              (route) => false,
                                            );
                                          },
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('An error occurred: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    likesState.isLiked
                                        ? CupertinoIcons.hand_thumbsup_fill
                                        : CupertinoIcons.hand_thumbsup,
                                    color: likesState.isLiked
                                        ? const Color(0xFF273847)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                if (likesState.likesCount > 0)
                                  Text(
                                    blogNotifier.formatLikesCount(
                                        likesState.likesCount),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: likesState.isLiked
                                          ? const Color(0xFF273847)
                                          : Colors.grey,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(
            color: Color(0xFF273847),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
