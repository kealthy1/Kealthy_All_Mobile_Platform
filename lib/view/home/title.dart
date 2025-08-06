import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CenteredTitleWidget extends StatelessWidget {
  final String title;

  const CenteredTitleWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.black38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
