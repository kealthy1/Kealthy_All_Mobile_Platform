import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAddressButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddAddressButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
        child: Row(
          children: [
            const Icon(Icons.add, color: Color.fromARGB(255, 65, 88, 108)),
            const SizedBox(width: 12.0),
            Text('Add address',
                style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 65, 88, 108),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}