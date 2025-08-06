import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/product/subcategories.dart';
import 'package:shimmer/shimmer.dart';

class HomeCategory extends ConsumerStatefulWidget {
  const HomeCategory({super.key});

  @override
  ConsumerState<HomeCategory> createState() => _HomeCategoryState();
}

class _HomeCategoryState extends ConsumerState<HomeCategory>
    with AutomaticKeepAliveClientMixin {
  void preloadCategoryImages(List<Map<String, dynamic>> categories) {
    for (var category in categories) {
      final url = category['image'] as String;
      final provider =
          CachedNetworkImageProvider(url, cacheKey: category['Categories']);
      provider.resolve(const ImageConfiguration());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    double tileWidth;
    double tileHeight;

    if (screenWidth < 600) {
      tileWidth = screenWidth * 0.3;
      tileHeight = screenWidth * 0.3;
    } else if (screenWidth < 900) {
      tileWidth = screenWidth * 0.3;
      tileHeight = 280;
    } else {
      tileWidth = screenWidth * 0.3;
      tileHeight = 300;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: firestore.collection('categories').orderBy('Categories').get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final categories = snapshot.data?.docs.map((doc) {
              return {
                'Categories': doc.data()['Categories'],
                'image': doc.data()['imageurl'],
              };
            }).toList();

            if (categories != null) {
              preloadCategoryImages(categories);
            }

            return Column(
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: categories?.map((category) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => SubCategoryPage(
                                  categoryName: category['Categories'],
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 48) / 3,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4F4F5),
                                    ),
                                    // Set your desired background color here
                                    child: CachedNetworkImage(
                                      imageUrl: category['image'] as String,
                                      width: tileWidth,
                                      height: tileHeight,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category['Categories'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList() ??
                      [],
                ),
                // const SizedBox(height: 10),
                // const CenteredTitleWidget(title: "Subscribe & Save"),
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: GestureDetector(
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const SubscriptionDetailsPage(),
                //         ),
                //       );
                //     },
                //     child: ClipRRect(
                //       borderRadius: BorderRadius.circular(10.0),
                //       child: Container(
                //         color: const Color(0xFFF4F4F5),
                //         child: Image.asset(
                //           'lib/assets/images/Never Run Out of Milk Again-5.png',
                //           height: 80,
                //           width: double.infinity,
                //           fit: BoxFit.cover,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const CenteredTitleWidget(
                //     title: "Hot Deals & Exclusive Offers"),
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: LayoutBuilder(
                //     builder: (context, constraints) {
                //       final isTablet = MediaQuery.of(context).size.width >= 600;
                //       final imageHeight = isTablet ? 150.0 : 100.0;
                //       return Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           GestureDetector(
                //             onTap: () {
                //               Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                     builder: (context) =>
                //                         const DealOfTheDayPage()),
                //               );
                //             },
                //             child: SizedBox(
                //               width:
                //                   (MediaQuery.of(context).size.width - 48) / 2,
                //               child: Column(
                //                 children: [
                //                   ClipRRect(
                //                     borderRadius: BorderRadius.circular(8.0),
                //                     child: Container(
                //                       color: const Color(0xFFF4F4F5),
                //                       child: Image.asset(
                //                         'lib/assets/images/deal day.png',
                //                         height: imageHeight,
                //                         width: double.infinity,
                //                         fit: BoxFit.cover,
                //                       ),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //           GestureDetector(
                //             onTap: () {
                //               Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                     builder: (context) =>
                //                         const DealOfTheWeekPage()),
                //               );
                //             },
                //             child: SizedBox(
                //               width:
                //                   (MediaQuery.of(context).size.width - 48) / 2,
                //               child: Column(
                //                 children: [
                //                   ClipRRect(
                //                     borderRadius: BorderRadius.circular(8.0),
                //                     child: Container(
                //                       color: const Color(0xFFF4F4F5),
                //                       child: Image.asset(
                //                         'lib/assets/images/deal week.png',
                //                         height: imageHeight,
                //                         width: double.infinity,
                //                         fit: BoxFit.cover,
                //                       ),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ],
                //       );
                //     },
                //   ),
                // ),
                // const CenteredTitleWidget(title: "Kealthy blogs"),
                // const SizedBox(height: 10),
                // // --- Begin: Blog Pagination Section ---
                // Consumer(
                //   builder: (context, ref, _) {
                //     final blogPagination = ref.watch(blogPaginationProvider);
                //     // Show only 6 recent blogs
                //     final limitedBlogs = blogPagination.take(6).toList();
                //     final screenWidth = MediaQuery.of(context).size.width;
                //     final tileWidth = screenWidth < 600
                //         ? screenWidth * 0.4
                //         : screenWidth * 0.25;
                //     final tileHeight = screenWidth < 600 ? 210.0 : 300.0;
                //     return Column(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         SizedBox(
                //           height: tileHeight,
                //           child: SingleChildScrollView(
                //             scrollDirection: Axis.horizontal,
                //             padding: const EdgeInsets.symmetric(horizontal: 10),
                //             child: Row(
                //               children: [
                //                 ...limitedBlogs.map((blog) => SizedBox(
                //                       width: tileWidth,
                //                       child: BlogListTile(
                //                         blog: blog,
                //                         onTap: () {
                //                           Navigator.push(
                //                             context,
                //                             CupertinoPageRoute(
                //                               builder: (context) =>
                //                                   BlogDetailsPage(blog: blog),
                //                             ),
                //                           );
                //                         },
                //                       ),
                //                     )),
                //                 // "See More" tile
                //                 SizedBox(
                //                   width: tileWidth,
                //                   child: Container(
                //                     height:
                //                         tileHeight, // match BlogListTile height
                //                     decoration: BoxDecoration(
                //                       borderRadius: BorderRadius.circular(10),
                //                     ),
                //                     child: GestureDetector(
                //                       onTap: () {
                //                         Navigator.push(
                //                           context,
                //                           MaterialPageRoute(
                //                             builder: (context) =>
                //                                 const BlogVerticalListPage(),
                //                           ),
                //                         );
                //                       },
                //                       child: Center(
                //                         child: Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.center,
                //                           mainAxisSize: MainAxisSize.min,
                //                           children: [
                //                             Text(
                //                               "See More",
                //                               style: TextStyle(
                //                                 color: Theme.of(context)
                //                                     .primaryColor,
                //                                 fontSize: 14,
                //                               ),
                //                             ),
                //                             Icon(Icons.arrow_forward_ios,
                //                                 size: 15,
                //                                 color: Theme.of(context)
                //                                     .primaryColor),
                //                           ],
                //                         ),
                //                       ),
                //                     ),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ),
                //         if (phoneNumber.isNotEmpty &&
                //             profile.name.isEmpty &&
                //             profile.email.isEmpty)
                //           Padding(
                //             padding: const EdgeInsets.symmetric(
                //                 horizontal: 16.0, vertical: 10),
                //             child: Center(
                //               child: Row(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: [
                //                   const Text(
                //                     "Subscribe to our newsletter",
                //                     style: TextStyle(
                //                       fontSize: 14,
                //                       color: Color.fromRGBO(0, 0, 0, 0.4),
                //                     ),
                //                   ),
                //                   const SizedBox(width: 5),
                //                   GestureDetector(
                //                     onTap: () async {
                //                       final result = await Navigator.push(
                //                         context,
                //                         MaterialPageRoute(
                //                           builder: (context) => EditProfilePage(
                //                               name: profile.name,
                //                               email: profile.email),
                //                         ),
                //                       );
                //                       if (result == true) {
                //                         ref
                //                             .read(newsletterSubscribedProvider
                //                                 .notifier)
                //                             .state = true;
                //                       }
                //                     },
                //                     child: Text(
                //                       'click here',
                //                       style: TextStyle(
                //                         fontSize: 14,
                //                         color: Colors.blue.shade400,
                //                       ),
                //                     ),
                //                   )
                //                 ],
                //               ),
                //             ),
                //           ),
                //       ],
                //     );
                //   },
                // ),
                // const CenteredTitleWidget(title: "Connect with us"),
                // Padding(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       GestureDetector(
                //         onTap: () async {
                //           final url = Uri.parse(
                //               'https://www.facebook.com/profile.php?id=61571096468965&mibextid=ZbWKwL');
                //           if (await canLaunchUrl(url)) {
                //             await launchUrl(url,
                //                 mode: LaunchMode.externalApplication);
                //           }
                //         },
                //         // ignore: prefer_const_constructors
                //         child:
                //             Icon(Icons.facebook, size: 40, color: Colors.black),
                //       ),
                //       const SizedBox(width: 20),
                //       GestureDetector(
                //         onTap: () async {
                //           final url = Uri.parse(
                //               'https://www.instagram.com/kealthy.life?igsh=MXVqa2hicG4ydzB5cQ==');
                //           if (await canLaunchUrl(url)) {
                //             await launchUrl(url,
                //                 mode: LaunchMode.externalApplication);
                //           }
                //         },
                //         child: Image.asset('lib/assets/images/instagram.png',
                //             height: 40),
                //       ),
                //       const SizedBox(width: 20),
                //       GestureDetector(
                //         onTap: () async {
                //           final url = Uri.parse('https://x.com/Kealthy_life/');
                //           if (await canLaunchUrl(url)) {
                //             await launchUrl(url,
                //                 mode: LaunchMode.externalApplication);
                //           }
                //         },
                //         child: Image.asset('lib/assets/images/twitter.png',
                //             height: 35),
                //       ),
                //       const SizedBox(width: 20),
                //       GestureDetector(
                //         onTap: () async {
                //           final url = Uri.parse(
                //               'https://chat.whatsapp.com/BxNSEDXO6jfKmUl0EuZ6qt');
                //           if (await canLaunchUrl(url)) {
                //             await launchUrl(url,
                //                 mode: LaunchMode.externalApplication);
                //           }
                //         },
                //         child: Image.asset('lib/assets/images/whatsapp.png',
                //             height: 35),
                //       ),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 50),
                // const KealthyPage(),
                // const SizedBox(height: 100),
              ],
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 3,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: tileWidth,
                              height: tileHeight,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 60,
                            height: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          }
        },
      );
    });
  }
}
