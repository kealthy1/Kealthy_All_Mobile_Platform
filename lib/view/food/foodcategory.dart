import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:shimmer/shimmer.dart';

class FoodCategory extends ConsumerStatefulWidget {
  const FoodCategory({super.key});

  @override
  ConsumerState<FoodCategory> createState() => _HomeCategoryState();
}

class _HomeCategoryState extends ConsumerState<FoodCategory>
    with AutomaticKeepAliveClientMixin {
  void preloadCategoryImages(List<Map<String, dynamic>> categories) {
    for (var category in categories) {
      final url = category['image'] as String;
      final provider =
          CachedNetworkImageProvider(url, cacheKey: category['foodCategory']);
      provider.resolve(const ImageConfiguration());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future:
          firestore.collection('foodSubcategory').orderBy('Categories').get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final customOrder = ['Breakfast', 'Lunch', '4 PM', 'Dinner'];
          final categories = snapshot.data?.docs.map((doc) {
            return {
              'Categories': doc.data()['Categories'],
              'image': doc.data()['imageurl'],
            };
          }).toList();
          categories?.sort((a, b) {
            final indexA = customOrder.indexOf(a['Categories']);
            final indexB = customOrder.indexOf(b['Categories']);
            return indexA.compareTo(indexB);
          });

          if (categories != null) {
            preloadCategoryImages(categories);
          }

          return Center(
            child: Column(
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
                                builder: (context) => FoodSubCategoryPage(
                                  categoryName:
                                      category['Categories'] as String,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 40),
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
                                      width: double.infinity,
                                      height: 100,
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
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
