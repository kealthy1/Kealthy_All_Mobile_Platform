import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailsDialog extends StatelessWidget {
  final String label;
  final String details;
  final Color backgroundColor;

  const DetailsDialog({
    super.key,
    required this.label,
    required this.details,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final lines = details.split('\n');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: backgroundColor,
      title: Text(
        label,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 20,
            color: Colors.green,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(
            color: Colors.grey,
            width: 1.0,
          ),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          children: label == "Ingredients"
              ? lines.asMap().entries.map((entry) {
                  final index = entry.key;
                  final line = entry.value.trim();
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${index + 1}.',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          line,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList()
              : lines.map((line) {
                  final parts = line.split(':');
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          parts.first.trim(),
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          parts.length > 1
                              ? parts.sublist(1).join(':').trim()
                              : '',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Close",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
