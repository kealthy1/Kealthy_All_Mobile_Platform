import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class KealthyScorePage extends StatelessWidget {
  const KealthyScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example score data
    const int score = 81; // Calculated Kealthy Score
    String grade;
    String description;

    // Determine grade and description based on score
    if (score >= 90) {
      grade = "Excellent";
      description =
          "Perfectly balanced, highly nutritious, and sustainable.";
    } else if (score >= 75) {
      grade = "Good";
      description =
          "Very healthy with minor room for improvement.";
    } else if (score >= 60) {
      grade = "Moderate";
      description =
          "Decent health benefits but could be better.";
    } else if (score >= 40) {
      grade = "Needs Improvement";
      description =
          "Lacks balance, not the healthiest choice.";
    } else {
      grade = "Unhealthy";
      description =
          "Low nutritional value or too many unhealthy elements.";
    }

    // Convert score to percentage (0.0 to 1.0)
    const double scorePercentage = score / 100;

    // Determine progress color based on score
    Color scoreColor;
    if (score >= 90) {
      scoreColor = Colors.green; // Excellent
    } else if (score >= 75) {
      scoreColor = Colors.blue; // Good
    } else if (score >= 60) {
      scoreColor = Colors.orange; // Moderate
    } else if (score >= 40) {
      scoreColor = Colors.redAccent; // Needs Improvement
    } else {
      scoreColor = Colors.red; // Unhealthy
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kealthy Score Meter"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 12.0,
              percent: scorePercentage,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$score",
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    "Kealthy Score",
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              progressColor: scoreColor,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 800,
            ),
            const SizedBox(height: 20.0),
            Text(
              grade,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30.0),
            // Example Breakdown
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Score Breakdown:",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    "Nutritional Value: 31/50\n"
                    "Naturalness: 30/30\n"
                    "Dietary Benefits: 15/15\n"
                    "Sustainability: 5/5",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}