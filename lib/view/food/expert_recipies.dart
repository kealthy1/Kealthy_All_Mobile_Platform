// New file: expert_recipes_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/food/food_subcategory.dart';

class ExpertRecipesPage extends ConsumerStatefulWidget {
  const ExpertRecipesPage({super.key});

  @override
  ConsumerState<ExpertRecipesPage> createState() => _ExpertRecipesPageState();
}

class _ExpertRecipesPageState extends ConsumerState<ExpertRecipesPage> {
  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expert Recipes',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<_ExpertType>>(
        future: _fetchExpertTypes(firestore),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No expert recipes available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final types = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: types.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final item = types[index];
                return _buildExpertItem(item);
              },
            ),
          );
        },
      ),
    );
  }

  /// Fetch distinct `Type` values under Category 'Expert Recipies'
  /// and attach the first non-empty `BrandImageUrl` seen for that Type.
  Future<List<_ExpertType>> _fetchExpertTypes(
      FirebaseFirestore firestore) async {
    final snapshot = await firestore
        .collection('Products')
        .where('Category', isEqualTo: 'Expert Recipies')
        .get();

    // Map<Type, BrandImageUrl?>
    final Map<String, String?> map = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = (data['Type']?.toString() ?? '').trim();
      if (type.isEmpty) continue;

      // If we already have an image for this type, keep it.
      if (map.containsKey(type) && (map[type]?.isNotEmpty ?? false)) continue;

      final url = (data['BrandImageUrl']?.toString() ?? '').trim();
      if (url.isNotEmpty) {
        map[type] = url;
      } else {
        // Ensure the type is present even without an image yet.
        map.putIfAbsent(type, () => null);
      }
    }

    // Sort by type name for stable UI
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return entries
        .map((e) => _ExpertType(type: e.key, imageUrl: e.value))
        .toList();
  }

  Widget _buildExpertItem(_ExpertType item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => FoodSubCategoryPage(categoryName: item.type),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _BrandImage(url: item.imageUrl),
                ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Text(
                item.type,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertType {
  final String type;
  final String? imageUrl;
  const _ExpertType({required this.type, required this.imageUrl});
}

class _BrandImage extends StatelessWidget {
  final String? url;
  const _BrandImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.image_not_supported,
            size: 40, color: Colors.grey.shade400),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.fitWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(child: CupertinoActivityIndicator()),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: Colors.grey.shade100,
          child:
              Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
        );
      },
    );
  }
}
