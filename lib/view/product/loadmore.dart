import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paginatedProductsProvider = StateNotifierProvider.family<
    PaginatedProductsNotifier, List<DocumentSnapshot<Map<String, dynamic>>>, String>((ref, subcategory) {
  return PaginatedProductsNotifier(subcategory);
});

class PaginatedProductsNotifier
    extends StateNotifier<List<QueryDocumentSnapshot<Map<String, dynamic>>>> {
  final String subcategory;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  final int _limit = 10;
  bool _isLoading = false;

  PaginatedProductsNotifier(this.subcategory) : super([]) {
    fetchNextBatch(); // Load first 10 on init
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  /// 🔥 This is the method your error was about – make sure this is here:
  Future<void> fetchNextBatch() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    Query query = FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: subcategory)
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      state = [...state, ...snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>()];

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }
    } else {
      _hasMore = false;
    }

    _isLoading = false;
  }
}
