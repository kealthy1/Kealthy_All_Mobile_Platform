import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// **Provider to fetch the Kealthy Score and "Scored Based On" from Firestore**
final kealthyScoreProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, productIdOrName) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot? productDoc;

    // 🔹 Try fetching by Product ID
    productDoc = await firestore.collection('Products').doc(productIdOrName).get();

    // 🔹 If not found by ID, search by Name
    if (!productDoc.exists) {
      QuerySnapshot query = await firestore
          .collection('Products')
          .where('productName', isEqualTo: productIdOrName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        productDoc = query.docs.first;
      }
    }

    if (productDoc.exists) {
      final data = productDoc.data() as Map<String, dynamic>;
      
      return {
        'score': data['Kealthy Score'] ?? 0,
        'scoredBasedOn': List<String>.from(data['Scored  Based On'] ?? []), 
      };
    }

    print("Product not found in Firestore.");
    return {'score': 0, 'scoredBasedOn': []};
  } catch (e) {
    print("Error fetching product score: $e");
    return {'score': 0, 'scoredBasedOn': []};
  }
});

class KealthyScoreSection extends ConsumerWidget {
  final String productIdOrName;

  const KealthyScoreSection({super.key, required this.productIdOrName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(kealthyScoreProvider(productIdOrName));

    return scoreAsync.when(
      data: (data) {
        final score = data["score"] as int;
        final List<String> scoredBasedOn = List<String>.from(data["scoredBasedOn"]);
        return _buildScoreWidget(context, score, scoredBasedOn);
      },
      loading: () => CircularPercentIndicator(radius: 28, lineWidth: 8.0, fillColor: Colors.white, backgroundColor: Colors.white),
      error: (error, stack) => Text("Error loading score", style: GoogleFonts.poppins(color: Colors.red)),
    );
  }

  /// **Builds UI once the score is fetched**
  Widget _buildScoreWidget(BuildContext context, int score, List<String> scoredBasedOn) {
    final progressColor = _progressColor(score);
    final grade = _calculateGrade(score);

    return GestureDetector(
      onTap: () {
        showKealthyScoreDialog(context,scoredBasedOn);
      },
      child: Column(
        children: [
          const SizedBox(height: 5),
          CircularPercentIndicator(
            radius: 28.0,
            lineWidth: 8.0,
            percent: (score / 100).clamp(0.0, 1.0), // Prevents values above 100%
            center: Text(
              "$score",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
            ),
            progressColor: progressColor,
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 5),
          Text(
            grade,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }


void showKealthyScoreDialog(BuildContext context, List<String> scoredBasedOn) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Kealthy Logo + Title --
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        "lib/assets/images/PHOTO-2025-01-22-11-55-26.jpg", // Your brand image
                        height: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "CONSUMABLE PRODUCTS\nSCORE STRUCTURE",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- "TOTAL: 100 POINTS" + "SCORING CRITERIA" --
                Center(
                  child: Column(
                    children: [
                      Text(
                        "TOTAL: 100 POINTS",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        "SCORING CRITERIA",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -- Scrollable Container --
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: scoredBasedOn.length,
                    itemBuilder: (context, index) {
                      final text = scoredBasedOn[index].trim();
                      if (text.isEmpty) return const SizedBox.shrink();

                      // Decide style based on whether it's roman or letter heading
                      final textStyle = _getTextStyleForLine(text);

                      return Container(
                        margin: const EdgeInsets.only(
                          top: 8,
                          left: 12,
                          right: 12,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(text, style: textStyle),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // -- Close Button --
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// We check for Roman numerals first -> black heading. 
/// Otherwise, check for A./B./C. -> green heading.
/// Else normal text.
TextStyle _getTextStyleForLine(String text) {
  // Pattern for subheading: "I. ", "II. ", "III. ", etc. (Roman numerals)
  final subHeadingPattern = RegExp(r'^(I{1,3}|IV|V?I{0,3})\.\s');
  
  // Pattern for main heading: "A. ", "B. ", "C. ", etc. 
  // EXCLUDES "I." so we won't conflict with Roman numerals
  final mainHeadingPattern = RegExp(r'^[A-HJ-Z]\.\s');

  if (subHeadingPattern.hasMatch(text)) {
    // "I.", "II.", "III." => black bold
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  } else if (mainHeadingPattern.hasMatch(text)) {
    // "A.", "B.", "C." => green bold
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.green[800],
    );
  } else {
    // normal text
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
    );
  }
}

  String _calculateGrade(int score) {
    if (score >= 90) return "Excellent Choice";
    if (score >= 75) return "Good Choice";
    if (score >= 60) return "Moderate";
    if (score >= 40) return "Needs Improvement";
    return "Unhealthy";
  }

  static Color _progressColor(int score) {
    if (score >= 90) return const Color.fromARGB(255, 77, 255, 83);
    if (score >= 75) return const Color.fromARGB(255, 128, 202, 131);
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}