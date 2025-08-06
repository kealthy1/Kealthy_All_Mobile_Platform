import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressTypeButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final StateProvider<String?> selectedProvider;
  final double width;

  const AddressTypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedProvider,
    this.width = 0.25, // default to 25% of screen width
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedProvider);
    final isSelected = selectedType == label;

    return InkWell(
      onTap: () => ref.read(selectedProvider.notifier).state = label,
      child: Container(
        width: MediaQuery.of(context).size.width * width,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 65, 88, 108)
              : Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.black45),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 65, 88, 108)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 65, 88, 108),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}