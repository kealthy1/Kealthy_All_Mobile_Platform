import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectionNotifier extends StateNotifier<bool> {
  SelectionNotifier() : super(false);

  void toggleSelection() {
    state = !state;
  }
}

final selectionProvider =
    StateNotifierProvider.family<SelectionNotifier, bool, int>(
  (ref, id) => SelectionNotifier(),
);

class InstructionContainer extends ConsumerWidget {
  final IconData icon;
  final String label;
  final int id;

  const InstructionContainer({
    super.key,
    required this.icon,
    required this.label,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectionProvider(id));
    final selectionNotifier = ref.read(selectionProvider(id).notifier);

    return GestureDetector(
      onTap: selectionNotifier.toggleSelection,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.3,
        decoration: BoxDecoration(
          color: isSelected ?   const Color(0xFFF4F4F5) : Colors.white,// Background always white
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 65, 88, 108) // Selected border color
                : Colors.grey.shade300, // Default border color
            width: 2, // Border width
          ),
          borderRadius: BorderRadius.circular(10),
         
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.black,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}