import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';

class CalorieState {
  final double weight;
  final double height;
  final int age;
  final String gender;
  double? maintenanceCalories;
  double? calorieLoss;
  double? calorieGain;

  CalorieState({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    this.maintenanceCalories,
    this.calorieLoss,
    this.calorieGain,
  });

  double calculateBMR() {
    if (gender == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  double calculateCalories(double activityLevel) {
    return calculateBMR() * activityLevel;
  }
}

final calorieProvider =
    StateNotifierProvider<CalorieNotifier, CalorieState>((ref) {
  return CalorieNotifier();
});

class CalorieNotifier extends StateNotifier<CalorieState> {
  CalorieNotifier()
      : super(CalorieState(weight: 0, height: 0, age: 0, gender: 'male'));

  void updateWeight(double weight) {
    state = CalorieState(
      weight: weight,
      height: state.height,
      age: state.age,
      gender: state.gender,
      maintenanceCalories: state.maintenanceCalories,
      calorieLoss: state.calorieLoss,
      calorieGain: state.calorieGain,
    );
  }

  void updateHeight(double height) {
    state = CalorieState(
      weight: state.weight,
      height: height,
      age: state.age,
      gender: state.gender,
      maintenanceCalories: state.maintenanceCalories,
      calorieLoss: state.calorieLoss,
      calorieGain: state.calorieGain,
    );
  }

  void updateAge(int age) {
    state = CalorieState(
      weight: state.weight,
      height: state.height,
      age: age,
      gender: state.gender,
      maintenanceCalories: state.maintenanceCalories,
      calorieLoss: state.calorieLoss,
      calorieGain: state.calorieGain,
    );
  }

  void updateGender(String gender) {
    state = CalorieState(
      weight: state.weight,
      height: state.height,
      age: state.age,
      gender: gender,
      maintenanceCalories: state.maintenanceCalories,
      calorieLoss: state.calorieLoss,
      calorieGain: state.calorieGain,
    );
  }

  void calculateCalories(double activityLevel) {
    final maintenanceCalories = state.calculateCalories(activityLevel);
    final calorieLoss = maintenanceCalories - 500;
    final calorieGain = maintenanceCalories + 500;

    state = CalorieState(
      weight: state.weight,
      height: state.height,
      age: state.age,
      gender: state.gender,
      maintenanceCalories: maintenanceCalories,
      calorieLoss: calorieLoss,
      calorieGain: calorieGain,
    );
  }
}

final selectedActivityProvider =
    StateProvider<String>((ref) => "Sedentary (Little or no exercise)");

class CalorieIntakePage extends ConsumerStatefulWidget {
  const CalorieIntakePage({super.key});

  @override
  ConsumerState<CalorieIntakePage> createState() => _CalorieIntakePageState();
}

class _CalorieIntakePageState extends ConsumerState<CalorieIntakePage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final activityLevels = [
    "Sedentary (Little or no exercise)",
    "Light (1-2 times/week)",
    "Moderate (2-3 times/week)",
    "Active (4+ times/week)"
  ];

  @override
  Widget build(BuildContext context) {
    final calorieState = ref.watch(calorieProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.invalidate(calorieProvider);
        ref.invalidate(selectedActivityProvider);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            "Kealthy Calorie Calculator",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                hintText: 'Weight (kg)',
                icon: Icons.accessibility_new,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  ref
                      .read(calorieProvider.notifier)
                      .updateWeight(double.tryParse(value) ?? 0);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Height (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  ref
                      .read(calorieProvider.notifier)
                      .updateHeight(double.tryParse(value) ?? 0);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Age (Years)',
                icon: Icons.person,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  int? age = int.tryParse(value);
                  if (age == null || age < 2 || age > 100) {
                    ToastHelper.showErrorToast(
                        'Please enter a valid age between 2 and 100.');
                  } else {
                    ref.read(calorieProvider.notifier).updateAge(age);
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: Text("Activity Level",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(
                height: 20,
              ),
              Consumer(
                builder: (context, ref, child) {
                  final selectedActivity = ref.watch(selectedActivityProvider);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButton2<String>(
                      value: selectedActivity,
                      isExpanded: true,
                      hint: Text("Select Activity Level",
                          style: GoogleFonts.poppins(color: Colors.white)),
                      buttonStyleData: ButtonStyleData(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                      ),
                      dropdownStyleData: const DropdownStyleData(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                      items: activityLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        ref.read(selectedActivityProvider.notifier).state =
                            newValue!;
                      },
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Radio<String>(
                    activeColor: const Color(0xFF273847),
                    value: 'male',
                    groupValue: calorieState.gender,
                    onChanged: (value) {
                      if (value != null) {
                        FocusScope.of(context).unfocus();
                        ref.read(calorieProvider.notifier).updateGender(value);
                      }
                    },
                  ),
                  Text('Male', style: GoogleFonts.poppins()),
                  Radio<String>(
                    activeColor: const Color(0xFF273847),
                    value: 'female',
                    groupValue: calorieState.gender,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(calorieProvider.notifier).updateGender(value);
                      }
                    },
                  ),
                  Text('Female', style: GoogleFonts.poppins()),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (calorieState.weight > 0 &&
                        calorieState.height > 0 &&
                        calorieState.age > 0 &&
                        calorieState.gender.isNotEmpty) {
                      final selectedActivity =
                          ref.read(selectedActivityProvider);
                      double activityMultiplier = 1.2; // Default Sedentary

                      switch (selectedActivity) {
                        case "Light (1-2 times/week)":
                          activityMultiplier = 1.375;
                          break;
                        case "Moderate (2-3 times/week)":
                          activityMultiplier = 1.55;
                          break;
                        case "Active (4+ times/week)":
                          activityMultiplier = 1.725;
                          break;
                      }

                      ref
                          .read(calorieProvider.notifier)
                          .calculateCalories(activityMultiplier);

                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    } else {
                      ToastHelper.showErrorToast('Please fill all fields.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    backgroundColor: const Color(0xFF273847),
                  ),
                  child: Text(
                    'Calculate',
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Consumer(
                builder: (context, ref, child) {
                  final maintenanceCalories =
                      ref.watch(calorieProvider).maintenanceCalories;
                  final calorieLoss = ref.watch(calorieProvider).calorieLoss;
                  final calorieGain = ref.watch(calorieProvider).calorieGain;

                  if (maintenanceCalories != null) {
                    return Column(
                      children: [
                        _calorieInfoCard(
                          title: 'Lose weight',
                          calories:
                              '${calorieLoss!.toStringAsFixed(0)} - ${(calorieLoss + 100).toStringAsFixed(0)} cal',
                          description:
                              'This range of daily calories will enable you to lose 1-2 lb per week in a healthy and sustainable way.',
                          color: Colors.red[100],
                          iconColor: Colors.red,
                          icon: Icons.arrow_downward,
                        ),
                        const SizedBox(height: 16),
                        _calorieInfoCard(
                          title: 'Maintain weight',
                          calories:
                              '${maintenanceCalories.toStringAsFixed(0)} - ${(maintenanceCalories + 100).toStringAsFixed(0)} cal',
                          description:
                              'This range of daily calories will enable you to maintain your current weight.',
                          color: Colors.green[100],
                          iconColor: Colors.green,
                          icon: Icons.arrow_forward,
                        ),
                        const SizedBox(height: 16),
                        _calorieInfoCard(
                          title: 'Gain weight',
                          calories:
                              '${calorieGain!.toStringAsFixed(0)} - ${(calorieGain + 100).toStringAsFixed(0)} cal',
                          description:
                              'This range of daily calories will enable you to gain 1-2 lb per week.',
                          color: Colors.blue[100],
                          iconColor: Colors.blue,
                          icon: Icons.arrow_upward,
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _calorieInfoCard({
  required String title,
  required String calories,
  required String description,
  required Color? color,
  required Color? iconColor,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 5),
        Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          'Calorie intake per day',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          calories,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: GoogleFonts.poppins(fontSize: 10),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
      ],
    ),
  );
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade500,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF273847),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                suffixText: hintText,
                suffixStyle: GoogleFonts.poppins(),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
