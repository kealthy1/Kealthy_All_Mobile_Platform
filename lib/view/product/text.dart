import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReusableText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;
  final FontWeight fontWeight;

  const ReusableText({
    super.key,
    required this.text,
   required this.fontSize,
    this.color = Colors.black,
    this.textAlign = TextAlign.start,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}