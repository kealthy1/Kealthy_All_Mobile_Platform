import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/search/page_route.dart';
import 'package:kealthy/view/search/search_page.dart';

final productNamesFromFirebaseProvider =
    FutureProvider<List<String>>((ref) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection('Products');
    final querySnapshot = await collectionRef.get();

    if (querySnapshot.docs.isEmpty) {
      print("Firestore: No products found.");
    }

    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          if (data.containsKey('Name') && data['Name'] is String) {
            return data['Name'] as String;
          } else {
            print(
                "Firestore: Missing or invalid 'Name' field in document ${doc.id}");
            return null;
          }
        })
        .whereType<String>() // Remove null values
        .toList();
  } catch (e) {
    print("Firestore Error: $e");
    return []; // Return an empty list if an error occurs
  }
});

final currentProductIndexProvider = StateProvider<int>((ref) => 0);

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  Timer? _timer;
  final _focusNode = FocusNode();

  void _navigateToSearchPage() {
    Navigator.push(
      context,
      SlideUpRoute(page: const SearchPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _navigateToSearchPage();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final productNamesAsyncValue = ref.read(productNamesFromFirebaseProvider);
      productNamesAsyncValue.whenData((productNames) {
        if (productNames.isNotEmpty) {
          int currentIndex = ref.read(currentProductIndexProvider);
          int newIndex = (currentIndex + 1) % productNames.length;
          ref.read(currentProductIndexProvider.notifier).state = newIndex;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productNamesAsync = ref.watch(productNamesFromFirebaseProvider);
    final currentIndex = ref.watch(currentProductIndexProvider);

    return productNamesAsync.when(
      data: (productNames) {
        if (productNames.isEmpty) {
          return _buildSearchField('No products available');
        }

        final currentProductName = productNames[currentIndex];
        return _buildSearchFieldWithAnimation("Search for $currentProductName");
      },
      loading: () => _buildSearchField('Loading products...'),
      error: (error, stack) => _buildSearchField('Error loading products'),
    );
  }

  Widget _buildSearchFieldWithAnimation(String hintText) {
    return GestureDetector(
      onTap: _navigateToSearchPage,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5), // Start below
                  end: Offset.zero, // End at original position
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: TextField(
            key: ValueKey<String>(hintText), // Ensure a unique key
            enabled: false,
            focusNode: _focusNode,
            cursorHeight: 15,
            decoration: InputDecoration(
              constraints: const BoxConstraints(maxHeight: 40.0),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              prefixIcon:
                  const Icon(CupertinoIcons.search, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(String hintText) {
    return GestureDetector(
      onTap: _navigateToSearchPage,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300)),
          child: TextField(
            enabled: false,
            focusNode: _focusNode,
            cursorHeight: 15,
            decoration: InputDecoration(
              constraints: const BoxConstraints(maxHeight: 40.0),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              prefixIcon:
                  const Icon(CupertinoIcons.search, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
