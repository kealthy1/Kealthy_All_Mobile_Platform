import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavProvider = StateNotifierProvider<BottomNavNotifier, int>((ref) {
  return BottomNavNotifier();
});

class BottomNavNotifier extends StateNotifier<int> {
  BottomNavNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}
