import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/AI/floating_button.dart';

final draggableFabPositionProvider = StateProvider<Offset?>((ref) => null);

class DraggableFloatingActionButton extends ConsumerWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String label;

  const DraggableFloatingActionButton({
    super.key,
    required this.imageUrl,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final double initialX = screenSize.width - 80; // Button near bottom-right
    final double initialY = screenSize.height -
        kBottomNavigationBarHeight -
        200; // Raised 50px more

    // Get current position, default to bottom-right with slight elevation
    final position =
        ref.watch(draggableFabPositionProvider) ?? Offset(initialX, initialY);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final screenSize = MediaQuery.of(context).size;
          final appBarHeight = AppBar().preferredSize.height;
          final statusBarHeight = MediaQuery.of(context).padding.top;
          const bottomNavHeight = kBottomNavigationBarHeight;

          final newPosition = position + details.delta;

          // Keep button within screen bounds
          const double minX = 0;
          final double maxX = screenSize.width - 60; // Button width
          final double minY = appBarHeight + statusBarHeight;
          final double maxY = screenSize.height -
              bottomNavHeight -
              130; // Adjusted height limit

          ref.read(draggableFabPositionProvider.notifier).state = Offset(
            newPosition.dx.clamp(minX, maxX),
            newPosition.dy.clamp(minY, maxY),
          );
        },
        child: ReusableFloatingActionButton(
          imageUrl: imageUrl,
          onTap: onTap,
          label: label,
        ),
      ),
    );
  }
}
