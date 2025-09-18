import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/lunch_sub_confirmation.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Mock address provider (replace with actual implementation)
final addressProvider = Provider<Map<String, dynamic>>((ref) => {
      'userId': 'user123',
      'addressLine1': '123 Main St',
      'addressLine2': 'Apt 4B',
      'city': 'Mumbai',
      'state': 'Maharashtra',
      'zipCode': '400001',
    });

final ingredientsProvider =
    StreamProvider.family<List<String>, MealType>((ref, mealType) {
  final fs = ref.watch(firestoreProvider);

  final query = fs
      .collection('Products')
      .where('Type', isEqualTo: mealType == MealType.lunch ? 'Lunch' : 'Dinner')
      .limit(500);

  return query.snapshots().map((snap) {
    final set = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final list = (data['Ingredients'] as List?)?.cast<dynamic>() ?? const [];
      for (final item in list) {
        final s = (item ?? '').toString().trim();
        if (s.isNotEmpty) set.add(s);
      }
    }

    // Add some defaults
    set.addAll({'Soya', 'Paneer', 'Beef'});

    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  });
});

class LunchDinnerState {
  final int totalDays; // 15 or 30
  final Set<DateTime> skipDates; // for primary meal
  final Set<DateTime> skipDatesSecondary; // for secondary meal if two meals
  final DateTime startDate; // first delivery date
  final Set<String> allergies; // string labels
  final bool isAllergySelectionEnabled; // Toggle for allergies menu
  final Map<DateTime, DietType?> dietOverrides;
  final bool isTwoMeals;

  LunchDinnerState({
    required this.totalDays,
    required this.skipDates,
    required this.skipDatesSecondary,
    required this.startDate,
    required this.allergies,
    this.isAllergySelectionEnabled = false,
    this.dietOverrides = const {},
    this.isTwoMeals = false,
  });

  LunchDinnerState copyWith({
    int? totalDays,
    Set<DateTime>? skipDates,
    Set<DateTime>? skipDatesSecondary,
    DateTime? startDate,
    Set<String>? allergies,
    bool? isAllergySelectionEnabled,
    Map<DateTime, DietType?>? dietOverrides,
    bool? isTwoMeals,
  }) {
    return LunchDinnerState(
      totalDays: totalDays ?? this.totalDays,
      skipDates: skipDates ?? this.skipDates,
      skipDatesSecondary: skipDatesSecondary ?? this.skipDatesSecondary,
      startDate: startDate ?? this.startDate,
      allergies: allergies ?? this.allergies,
      isAllergySelectionEnabled:
          isAllergySelectionEnabled ?? this.isAllergySelectionEnabled,
      dietOverrides: dietOverrides ?? this.dietOverrides,
      isTwoMeals: isTwoMeals ?? this.isTwoMeals,
    );
  }
}

class LunchDinnerNotifier extends StateNotifier<LunchDinnerState> {
  LunchDinnerNotifier()
      : super(
          LunchDinnerState(
            totalDays: 15,
            skipDates: {},
            skipDatesSecondary: {},
            startDate: _stripTime(DateTime.now().add(const Duration(days: 1))),
            allergies: {},
            isAllergySelectionEnabled: false,
            isTwoMeals: false,
          ),
        );

  static DateTime _stripTime(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  bool isAvailable(DateTime day) => !state.skipDates.contains(_stripTime(day));

  bool isAvailableSecondary(DateTime day) =>
      !state.skipDatesSecondary.contains(_stripTime(day));

  void setAvailability(DateTime day, bool available) {
    final d = _stripTime(day);
    final s = {...state.skipDates};
    if (available) {
      s.remove(d);
    } else {
      s.add(d);
    }
    print('setAvailability: day=$d, available=$available, skipDates=$s');
    state = state.copyWith(skipDates: s);
  }

  void setAvailabilitySecondary(DateTime day, bool available) {
    final d = _stripTime(day);
    final s = {...state.skipDatesSecondary};
    if (available) {
      s.remove(d);
    } else {
      s.add(d);
    }
    print(
        'setAvailabilitySecondary: day=$d, available=$available, skipDatesSecondary=$s');
    state = state.copyWith(skipDatesSecondary: s);
  }

  void setDietOverride(DateTime day, DietType? override) {
    final d = _stripTime(day);
    final map = {...state.dietOverrides};
    if (override == null) {
      map.remove(d);
    } else {
      map[d] = override;
    }
    state = state.copyWith(dietOverrides: map);
  }

  DietType dietForDate(DateTime day) {
    final d = _stripTime(day);
    return state.dietOverrides[d] ?? DietType.nonVeg;
  }

  void setTotalDays(int days) => state = state.copyWith(totalDays: days);

  void toggleSkip(DateTime day) {
    final d = _stripTime(day);
    final s = {...state.skipDates};
    if (s.contains(d)) {
      s.remove(d);
    } else {
      s.add(d);
    }
    print('toggleSkip: day=$d, skipDates=$s');
    state = state.copyWith(skipDates: s);
  }

  void toggleSkipSecondary(DateTime day) {
    final d = _stripTime(day);
    final s = {...state.skipDatesSecondary};
    if (s.contains(d)) {
      s.remove(d);
    } else {
      s.add(d);
    }
    print('toggleSkipSecondary: day=$d, skipDatesSecondary=$s');
    state = state.copyWith(skipDatesSecondary: s);
  }

  void setStartDate(DateTime day) =>
      state = state.copyWith(startDate: _stripTime(day));

  void toggleAllergy(String label) {
    final s = {...state.allergies};
    if (s.contains(label)) {
      s.remove(label);
    } else {
      s.add(label);
    }
    state = state.copyWith(allergies: s);
  }

  void toggleAllergySelection(bool enabled) {
    state = state.copyWith(
      isAllergySelectionEnabled: enabled,
      allergies: enabled ? state.allergies : {},
    );
  }

  void setTwoMeals(bool enabled) {
    state = state.copyWith(isTwoMeals: enabled);
  }

  List<DateTime> generateDeliveryDates() {
    final result = <DateTime>[];
    var cursor = state.startDate;
    while (result.length < state.totalDays) {
      final day = _stripTime(cursor);
      final isSunday = day.weekday == DateTime.sunday;
      final isSkipped = state.skipDates.contains(day);
      if (!isSunday && !isSkipped) result.add(day);
      cursor = day.add(const Duration(days: 1));
    }
    return result;
  }

  List<DateTime> generateDeliveryDatesSecondary() {
    final result = <DateTime>[];
    var cursor = state.startDate;
    while (result.length < state.totalDays) {
      final day = _stripTime(cursor);
      final isSunday = day.weekday == DateTime.sunday;
      final isSkipped = state.skipDatesSecondary.contains(day);
      if (!isSunday && !isSkipped) result.add(day);
      cursor = day.add(const Duration(days: 1));
    }
    return result;
  }
}

final lunchDinnerProvider =
    StateNotifierProvider<LunchDinnerNotifier, LunchDinnerState>(
        (ref) => LunchDinnerNotifier());

class NewSubscriptionPage extends ConsumerWidget {
  final MealType mealType;
  const NewSubscriptionPage({super.key, required this.mealType});

  String get _title => mealType == MealType.lunch
      ? 'New Lunch Subscription'
      : 'New Dinner Subscription';

  MealType get _secondaryMealType =>
      mealType == MealType.lunch ? MealType.dinner : MealType.lunch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(lunchDinnerProvider);
    final ingrAsync = ref.watch(ingredientsProvider(mealType));
    final scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Plan Duration',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {st.totalDays},
              onSelectionChanged: (s) =>
                  ref.read(lunchDinnerProvider.notifier).setTotalDays(s.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Add ${_secondaryMealType.name.capitalize()}?'),
              value: st.isTwoMeals,
              onChanged: (value) {
                ref.read(lunchDinnerProvider.notifier).setTwoMeals(value);
              },
            ),
            const SizedBox(height: 16),
            const Text('Allergies',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Are you allergic?'),
              value: st.isAllergySelectionEnabled,
              onChanged: (value) {
                ref
                    .read(lunchDinnerProvider.notifier)
                    .toggleAllergySelection(value);
              },
            ),
            if (st.isAllergySelectionEnabled) ...[
              const SizedBox(height: 8),
              ingrAsync.when(
                data: (items) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in items)
                      ChoiceChip(
                        label:
                            Text(label, style: const TextStyle(fontSize: 12)),
                        selected: st.allergies.contains(label),
                        onSelected: (_) => ref
                            .read(lunchDinnerProvider.notifier)
                            .toggleAllergy(label),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        labelPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load ingredients: $e'),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Start Date',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _DatePickerTile(
              date: st.startDate,
              onPick: (d) =>
                  ref.read(lunchDinnerProvider.notifier).setStartDate(d),
            ),
            const SizedBox(height: 16),
            const Text('Select Available Days',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.red),
                const SizedBox(width: 5),
                Text('Non-Veg Days'),
                const SizedBox(width: 10),
                Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 5),
                Text('Veg Days')
              ],
            ),
            const SizedBox(height: 8),
            Text(mealType == MealType.lunch ? 'Lunch Days' : 'Dinner Days '),
            const SizedBox(height: 8),
            _SkipDaysGrid(
              start: st.startDate,
              horizonDays: 30,
              isSkipped: (day) =>
                  st.skipDates.contains(LunchDinnerNotifier._stripTime(day)),
              mealType: mealType,
              isPrimaryMeal: true,
              ref: ref,
            ),
            if (st.isTwoMeals) ...[
              const SizedBox(height: 16),
              Text('${_secondaryMealType.name.capitalize()} Days '),
              const SizedBox(height: 6),
              _SkipDaysGrid(
                start: st.startDate,
                horizonDays: 30,
                isSkipped: (day) => st.skipDatesSecondary
                    .contains(LunchDinnerNotifier._stripTime(day)),
                mealType: _secondaryMealType,
                isPrimaryMeal: false,
                ref: ref,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MealsSubConfirmationPage(
                      title: st.isTwoMeals
                          ? 'Lunch and Dinner Subscription'
                          : _title,
                      description:
                          '${st.totalDays} Days Non-Veg Subscription${st.isTwoMeals ? ' (Two Meals)' : ''}',
                      baseRate: 500,
                      durationDays: st.totalDays,
                      productName: st.isTwoMeals
                          ? 'Lunch and Dinner'
                          : (mealType == MealType.lunch ? 'Lunch' : 'Dinner'),
                      dietType: DietType.nonVeg,
                      isTwoMeals: st.isTwoMeals,
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DatePickerTile({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xFFF6F6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(DateFormat('d/M/y').format(date)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          selectableDayPredicate: (DateTime day) {
            return day.weekday != DateTime.sunday;
          },
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

class _SkipDaysGrid extends ConsumerWidget {
  final DateTime start;
  final int horizonDays;
  final bool Function(DateTime) isSkipped;
  final MealType mealType;
  final bool isPrimaryMeal;
  final WidgetRef ref;

  const _SkipDaysGrid({
    required this.start,
    required this.horizonDays,
    required this.isSkipped,
    required this.mealType,
    required this.isPrimaryMeal,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(lunchDinnerProvider);
    final days = List.generate(
        horizonDays,
        (i) => DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
    print(
        'Building _SkipDaysGrid for ${mealType.name}, isPrimaryMeal=$isPrimaryMeal, skipDates=${st.skipDates}, skipDatesSecondary=${st.skipDatesSecondary}');
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final d in days)
          GestureDetector(
            onTap: () {
              print(
                  'Opening bottom sheet for day=${d.day}/${d.month}, mealType=${mealType.name}, isPrimaryMeal=$isPrimaryMeal');
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => _DayEditSheet(
                  day: d,
                  isAvailable:
                      !st.skipDates.contains(LunchDinnerNotifier._stripTime(d)),
                  isAvailableSecondary: !st.skipDatesSecondary
                      .contains(LunchDinnerNotifier._stripTime(d)),
                  currentOverride: ref
                      .read(lunchDinnerProvider)
                      .dietOverrides[DateTime(d.year, d.month, d.day)],
                  isTwoMeals: st.isTwoMeals,
                  primaryMealType: mealType,
                  isPrimaryMeal: isPrimaryMeal,
                  onSave: (available, availableSecondary, override) {
                    final notifier = ref.read(lunchDinnerProvider.notifier);
                    print(
                        'onSave called: day=${d.day}/${d.month}, isPrimaryMeal=$isPrimaryMeal, primaryAvailable=$available, secondaryAvailable=$availableSecondary');
                    if (isPrimaryMeal) {
                      notifier.setAvailability(d, available);
                    } else {
                      notifier.setAvailabilitySecondary(d, available);
                    }
                    if (st.isTwoMeals && isPrimaryMeal) {
                      notifier.setAvailabilitySecondary(d, availableSecondary);
                    } else if (st.isTwoMeals && !isPrimaryMeal) {
                      notifier.setAvailability(d, availableSecondary);
                    }
                    notifier.setDietOverride(d, override);
                    Navigator.pop(context);
                  },
                ),
              );
            },
            child: Tooltip(
              message: ref.read(lunchDinnerProvider.notifier).dietForDate(d) ==
                      DietType.veg
                  ? 'Veg Day'
                  : 'Non-Veg Day',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSkipped(d)
                      ? Colors.red.withAlpha(14)
                      : Colors.green.withAlpha(14),
                  border: Border.all(
                    color: isSkipped(d)
                        ? Colors.red
                        : d.weekday == DateTime.sunday
                            ? Colors.black
                            : Colors.green,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          color: d.weekday == DateTime.sunday
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                    ),
                    if (!isSkipped(d) && d.weekday != DateTime.sunday)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: ref
                                      .read(lunchDinnerProvider.notifier)
                                      .dietForDate(d) ==
                                  DietType.veg
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    if (d.weekday == DateTime.sunday)
                      Positioned(
                          bottom: 2,
                          right: 2,
                          child: Text('SUNDAY',
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ))),
                    if (isSkipped(d))
                      Positioned(
                          bottom: 2,
                          right: 2,
                          child: Text('SKIPPED',
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                              ))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayEditSheet extends StatelessWidget {
  final DateTime day;
  final bool isAvailable;
  final bool isAvailableSecondary;
  final DietType? currentOverride;
  final bool isTwoMeals;
  final MealType primaryMealType;
  final bool isPrimaryMeal;
  final void Function(
      bool available, bool availableSecondary, DietType? override) onSave;

  const _DayEditSheet({
    required this.day,
    required this.isAvailable,
    required this.isAvailableSecondary,
    required this.currentOverride,
    required this.isTwoMeals,
    required this.primaryMealType,
    required this.isPrimaryMeal,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    bool available = isAvailable;
    bool availableSecondary = isAvailableSecondary;
    DietType? override = currentOverride;
    return StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customize ${day.day}/${day.month}/${day.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                    "I'm available for ${primaryMealType.name.capitalize()} this day"),
                value: available,
                onChanged: (v) {
                  setState(() => available = v);
                  print(
                      'Primary meal availability changed: day=${day.day}/${day.month}, available=$v');
                },
              ),
              if (isTwoMeals) ...[
                SwitchListTile(
                  title: Text(
                      "I'm available for ${(primaryMealType == MealType.lunch ? MealType.dinner : MealType.lunch).name.capitalize()} this day"),
                  value: availableSecondary,
                  onChanged: (v) {
                    setState(() => availableSecondary = v);
                    print(
                        'Secondary meal availability changed: day=${day.day}/${day.month}, available=$v');
                  },
                ),
              ],
              const SizedBox(height: 8),
              const Text('Diet for this day',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('Non-Veg')),
                  const ButtonSegment(value: 1, label: Text('Veg')),
                ],
                selected: {override == DietType.veg ? 1 : 0},
                onSelectionChanged: (s) {
                  final v = s.first;
                  setState(() {
                    override = v == 1 ? DietType.veg : null;
                  });
                  print(
                      'Diet override changed: day=${day.day}/${day.month}, override=$override');
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  print(
                      'Saving: day=${day.day}/${day.month}, isPrimaryMeal=$isPrimaryMeal, primaryAvailable=$available, secondaryAvailable=$availableSecondary, override=$override');
                  onSave(available, availableSecondary, override);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
