import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: unused_element
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<dynamic> names;
  final Color backgroundColor;
  final VoidCallback onMorePressed;

  const InfoCard({super.key, 
    required this.icon,
    required this.label,
    required this.names,
    required this.backgroundColor,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMorePressed,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: 25,
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            // First line of items
            Text(
              names.join(', '),
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              "More",
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}