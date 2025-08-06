import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class HiTextNotifier extends StateNotifier<bool> {
  HiTextNotifier() : super(false) {
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      state = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        state = false; 
      });
    });
  }
}
final hiTextProvider = StateNotifierProvider<HiTextNotifier, bool>((ref) {
  return HiTextNotifier();
});

class ReusableFloatingActionButton extends ConsumerWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String label;

  const ReusableFloatingActionButton({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.label = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHi = ref.watch(hiTextProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.02;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          FloatingActionButton(
            onPressed: onTap,
            backgroundColor: Colors.grey.shade200,
            elevation: 0,
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightElevation: 0,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(flex: 3, child: Image.asset(imageUrl)),
                if (label.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Visibility(
            visible: showHi,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hi',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}