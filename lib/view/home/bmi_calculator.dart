import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiState {
  final double bmi;
  final String category;

  BmiState({required this.bmi, required this.category});
}

class BmiNotifier extends StateNotifier<BmiState> {
  BmiNotifier() : super(BmiState(bmi: 0, category: "Enter Details"));

  void calculateBMI(double weight, double height, String gender) {
    if (height <= 0 || weight <= 0) return;

    double bmi = weight / ((height / 100) * (height / 100));

    state = BmiState(
      bmi: bmi,
      category: _getCategory(bmi),
    );
  }

  String _getCategory(double bmi) {
    if (bmi < 18.5) {
      return "Underweight";
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return "Normal";
    } else if (bmi >= 25 && bmi < 29.9) {
      return "Overweight";
    } else {
      return "Obesity";
    }
  }
}

final bmiProvider = StateNotifierProvider<BmiNotifier, BmiState>((ref) {
  return BmiNotifier();
});
final selectedGenderProvider = StateProvider<String?>((ref) => null);

class BmiTrackerPage extends ConsumerStatefulWidget {
  const BmiTrackerPage({super.key});

  @override
  _BmiTrackerPageState createState() => _BmiTrackerPageState();
}

class _BmiTrackerPageState extends ConsumerState<BmiTrackerPage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bmiState = ref.watch(bmiProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.invalidate(bmiProvider);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: Text(
            "Kealthy BMI Calculator",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600,fontSize: 20),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Age (Years)", ageController, Icons.person),
                _buildTextField(
                  "Weight (kg)",
                  weightController,
                  Icons.accessibility_new,
                ),
                _buildTextField("Height (cm)", heightController, Icons.height),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Consumer(builder: (context, ref, child) {
                      final selectedGender = ref.watch(selectedGenderProvider);

                      return Row(
                        children: [
                          Radio<String>(
                            activeColor: const Color(0xFF273847),
                            value: 'male',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              ref.read(selectedGenderProvider.notifier).state =
                                  value;
                            },
                          ),
                          Text('Male', style: GoogleFonts.poppins()),
                          Radio<String>(
                            activeColor: const Color(0xFF273847),
                            value: 'female',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              ref.read(selectedGenderProvider.notifier).state =
                                  value;
                            },
                          ),
                          Text('Female', style: GoogleFonts.poppins()),
                        ],
                      );
                    }),
                  ],
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      double weight =
                          double.tryParse(weightController.text) ?? 0;
                      double height =
                          double.tryParse(heightController.text) ?? 0;

                      if (weight > 0 && height > 0) {
                        final gender =
                            ref.read(selectedGenderProvider) ?? 'male';
                        ref
                            .read(bmiProvider.notifier)
                            .calculateBMI(weight, height, gender);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF273847),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Calculate BMI",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.play_arrow,
                            size: 24, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: AnimatedRadialGauge(
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      radius: 120,
                      value: bmiState.bmi,
                      axis: GaugeAxis(
                        min: 10,
                        max: 40,
                        degrees: 180,
                        style: const GaugeAxisStyle(
                          thickness: 20,
                          background: Color(0xFFDFE2EC),
                          segmentSpacing: 2,
                        ),
                        pointer: const GaugePointer.needle(
                          width: 16,
                          height: 100,
                          color: Color(0xFF273847),
                        ),
                        progressBar: GaugeProgressBar.rounded(
                          color: _getCategoryColor(bmiState.category),
                        ),
                        segments: [
                          GaugeSegment(
                              from: 10,
                              to: 18.5,
                              color: Colors.orange.shade100),
                          const GaugeSegment(
                              from: 18.5, to: 24.9, color: Colors.green),
                          const GaugeSegment(
                              border: GaugeBorder(color: Colors.grey),
                              from: 25,
                              to: 29.9,
                              color: Colors.orange),
                          const GaugeSegment(from: 30, to: 40, color: Colors.red),
                        ],
                      ),
                      builder: (context, child, value) => const SizedBox.shrink()),
                ),
                const SizedBox(height: 10),
                if (bmiState.bmi > 0)
                  Center(
                    child: Text(
                      "BMI = ${bmiState.bmi.toStringAsFixed(1)}",
                      style: GoogleFonts.montserrat(
                          fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
                Center(
                  child: Text(
                    bmiState.category,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: getCategoryColor(bmiState.bmi),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color getCategoryColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.orange.shade100; // Light Blue for Underweight
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return Colors.green; // Green for Normal
    } else if (bmi >= 25 && bmi < 29.9) {
      return Colors.orange; // Orange for Overweight
    } else {
      return Colors.red; // Red for Obesity
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    String hintText = "";
    String suffixText = "";

    if (label.contains("Age")) {
      hintText = "Enter your age";
      suffixText = "Age (Years)";
    } else if (label.contains("Weight")) {
      hintText = "Enter your weight";
      suffixText = "Weight (Kg)";
    } else if (label.contains("Height")) {
      hintText = "Enter your height";
      suffixText = "Height (cm)";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        cursorColor: Colors.black,
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixText: suffixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Underweight":
        return Colors.transparent;
      case "Normal":
        return Colors.transparent;
      case "Overweight":
        return Colors.transparent;
      case "Obesity":
        return Colors.transparent;
      default:
        return Colors.transparent;
    }
  }
}