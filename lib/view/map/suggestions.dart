import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/map/place%20suggestion_provider.dart';

class PlaceSuggestionPage extends ConsumerStatefulWidget {
  const PlaceSuggestionPage({super.key});

  @override
  ConsumerState<PlaceSuggestionPage> createState() =>
      _PlaceSuggestionPageState();
}

class _PlaceSuggestionPageState extends ConsumerState<PlaceSuggestionPage> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(placeSuggestionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Search Location', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  hintText: 'Search for location',
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.black38, fontSize: 15),
                  border: InputBorder.none,
                  suffixIcon: const Icon(CupertinoIcons.search),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    ref
                        .read(placeSuggestionsProvider.notifier)
                        .fetchPlaceSuggestions(value);
                  } else {
                    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                    ref.read(placeSuggestionsProvider.notifier).state = [];
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    suggestion['description'],
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context, suggestion);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
