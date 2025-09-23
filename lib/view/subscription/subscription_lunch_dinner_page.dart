import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart';
import 'package:intl/intl.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _exactPlanDays(Map<String, dynamic> subscription, MealType mealType) {
  final mealKey = mealType.name.toLowerCase();

  // Window
  final ranges =
      Map<String, dynamic>.from(subscription['mealDateRanges'] ?? {});
  final range = Map<String, dynamic>.from(ranges[mealKey] ?? {});
  final start = DateTime.tryParse((range['startDate'] ?? '').toString());
  final end = DateTime.tryParse((range['endDate'] ?? '').toString());
  if (start == null || end == null) return 0;

  final startD = _dOnly(start);
  final endD = _dOnly(end);

  // Prefer deliveriesDetailed (most accurate)
  final detailed =
      normalizeDeliveriesDetailed(subscription['deliveriesDetailed']);
  final targetHour = mealType == MealType.lunch ? 12 : 18;

  final byDetailed = detailed.where((e) {
    final dt = DateTime.tryParse(e['date'].toString());
    if (dt == null || dt.hour != targetHour) return false;
    final d = _dOnly(dt);
    return !d.isBefore(startD) && !d.isAfter(endD);
  }).length;

  if (byDetailed > 0) return byDetailed;

  // Fallback: rebuild from range + per-meal skipDates + Sunday rule
  final skipStrs = readMealDateStrings(
      subscription['skipDates'], mealType); // Set<String> yyyy-MM-dd
  final skip = skipStrs.map(parseYmdLocal).toSet();

  int count = 0;
  for (var d = startD; !d.isAfter(endD); d = d.add(const Duration(days: 1))) {
    if (d.weekday == DateTime.sunday) continue;
    if (skip.contains(d)) continue;
    count++;
  }
  return count;
}

/// Build actual delivery schedule (excludes Sundays & skips) for `planDays`.
List<DateTime> _buildSchedule(
    DateTime start, int planDays, Set<DateTime> skip) {
  final out = <DateTime>[];
  var cur = _dOnly(start);
  while (out.length < planDays) {
    final day = _dOnly(cur);
    if (day.weekday != DateTime.sunday && !skip.contains(day)) {
      out.add(day);
    }
    cur = cur.add(const Duration(days: 1));
  }
  return out;
}

/// Build a continuous window [start … lastDelivery] inclusive, so Sundays and skipped
/// days are visible in the grid, too.
List<DateTime> _buildWindowFromSchedule(
    DateTime start, List<DateTime> schedule) {
  final last = schedule.isNotEmpty ? schedule.last : _dOnly(start);
  final window = <DateTime>[];
  var cur = _dOnly(start);
  while (!cur.isAfter(last)) {
    window.add(cur);
    cur = cur.add(const Duration(days: 1));
  }
  return window;
}

DateTime parseYmdLocal(String ymd) {
  final d = DateFormat('yyyy-MM-dd').parseStrict(ymd);
  return DateTime(d.year, d.month, d.day);
}

String dfmt(DateTime d) =>
    DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

/// Read a per-meal dates field (supports new shape and legacy shapes).
/// Returns a Set<yyyy-MM-dd> for the requested meal.
Set<String> readMealDateStrings(dynamic field, MealType mealType) {
  final meal = mealType.name.toLowerCase(); // 'lunch' | 'dinner'
  if (field == null) return {};

  // New shape: { "lunch": [ "2025-09-22", ... ], "dinner": [ ... ] }
  if (field is Map &&
      (field.containsKey('lunch') || field.containsKey('dinner'))) {
    final v = field[meal];
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toSet();
    } else if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    } else if (v is Map) {
      // legacy: map of {date:true}
      return v.entries
          .where((e) =>
              e.value == true || e.value == 1 || e.value?.toString() == 'true')
          .map((e) => e.key.toString())
          .toSet();
    }
    return {};
  }

  // Legacy whole-field shapes (no per-meal keys):
  if (field is List) {
    return field.map((e) => e.toString()).where((s) => s.isNotEmpty).toSet();
  }
  if (field is String) {
    return field
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }
  if (field is Map) {
    return field.entries
        .where((e) =>
            e.value == true || e.value == 1 || e.value?.toString() == 'true')
        .map((e) => e.key.toString())
        .toSet();
  }
  return {};
}

/// Build a <meal, List<yyyy-MM-dd>> payload from a set provider for each meal.
Map<String, List<String>> toPerMealListPayload({
  required Iterable<String> meals, // e.g. selectedMeals = ['lunch','dinner']
  required Set<String> Function(String meal) get, // returns set of date strings
}) {
  final out = <String, List<String>>{};
  for (final meal in meals) {
    final list = get(meal).toList()..sort();
    out[meal] = list;
  }
  return out;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// --- VEG DATES HELPERS ---
// Read veg dates for a meal as a Set<yyyy-MM-dd>.
// Supports BOTH legacy map {date: true} and new string "d1,d2,d3".
Set<String> readVegDatesForMeal(dynamic vegDatesField, MealType mealType) {
  final key = mealType.name.toLowerCase(); // 'lunch' | 'dinner'
  if (vegDatesField == null) return {};

  // If vegDates is a map
  if (vegDatesField is Map) {
    final v = vegDatesField[key];
    if (v == null) return {};
    if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    if (v is Map) {
      return v.entries
          .where((e) =>
              e.value == true || e.value == 1 || e.value?.toString() == 'true')
          .map((e) => e.key.toString())
          .toSet();
    }
  }

  // If vegDates itself is the string for lunch (degenerate case)
  if (vegDatesField is String && key == 'lunch') {
    return vegDatesField
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  return {};
}

// Serialize Set<yyyy-MM-dd> into a sorted comma string
String vegDatesStringForMeal(Set<String> set) {
  final sorted = set.toList()..sort();
  return sorted.join(',');
}

Set<DateTime> readSkipDatesAsDateSet(dynamic raw) {
  DateTime parseDate(String s) {
    final p = DateTime.tryParse(s) ?? DateFormat('yyyy-MM-dd').parse(s);
    return dateOnly(p);
  }

  if (raw == null) return {};
  if (raw is List) return raw.map((e) => parseDate(e.toString())).toSet();
  if (raw is Map) {
    // { "yyyy-MM-dd": true }
    return raw.entries
        .where((e) =>
            e.value == true || e.value == 1 || e.value?.toString() == 'true')
        .map((e) => parseDate(e.key.toString()))
        .toSet();
  }
  return {};
}

Map<String, dynamic> skipDatesToMap(Set<DateTime> set) =>
    {for (final d in set) dfmt(d): true};

List<Map<String, dynamic>> normalizeDeliveriesDetailed(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
  if (raw is Map) {
    return raw.values
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
  return [];
}

int toInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final databaseProvider = Provider<DatabaseReference>((ref) {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref();
});

String normalizePhone(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

final userSubscriptionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, MealType>(
        (ref, mealType) {
  final db = ref.watch(databaseProvider);
  final rawPhone = ref.watch(phoneNumberProvider);
  final number = normalizePhone(rawPhone);

  final query = db
      .child('food_subscription')
      .orderByChild('delivery/phone')
      .equalTo(number);

  return query.onValue.map((event) {
    final map = (event.snapshot.value as Map?) ?? {};
    final want = mealType == MealType.lunch ? 'lunch' : 'dinner';

    final list = map.entries
        .map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          final mt = (m['mealType'] ?? '').toString().toLowerCase();
          final selectedMeals = (m['selectedMeals'] as List?)
                  ?.map((x) => x.toString().toLowerCase())
                  .toSet() ??
              const <String>{};

          if (mt != want && !selectedMeals.contains(want)) return null;
          return {'id': e.key.toString(), ...m};
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    // Optional: sort by customer.name
    list.sort((a, b) => (a['customer']?['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['customer']?['name'] ?? '').toString().toLowerCase()));
    return list;
  });
});

// ===== Page ===================================================================

class LunchDinnerPlanPage extends ConsumerWidget {
  final MealType mealType;
  const LunchDinnerPlanPage({super.key, required this.mealType});

  String get _title => mealType == MealType.lunch
      ? 'Lunch Subscriptions'
      : 'Dinner Subscriptions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider(mealType));

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: subscriptionsAsync.when(
          data: (subscriptions) {
            final filteredSubscriptions = subscriptions
                .where((sub) =>
                    (sub['selectedMeals'] as List?)
                        ?.contains(mealType.name.toLowerCase()) ??
                    false)
                .toList();
            if (filteredSubscriptions.isEmpty) {
              return const Center(
                child: Text(
                  textAlign: TextAlign.center,
                  "Hungry for a plan?\nCreate a new subscription to get started.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredSubscriptions.length,
              itemBuilder: (context, index) {
                final sub = filteredSubscriptions[index];
                return SubscriptionCard(
                  subscription: sub,
                  mealType: mealType,
                  onEdit: () => _showEditDialog(context, ref, sub),
                  onToggleAvailability: (available) =>
                      _toggleAvailability(context, ref, sub, available),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('Error loading subscriptions: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.invalidate(lunchDinnerProvider);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewSubscriptionPage(mealType: mealType),
            ),
          );
        },
        tooltip: 'New Subscription',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => SubscriptionEditDialog(
        subscription: subscription,
        mealType: mealType,
      ),
    );
  }

  Future<void> _toggleAvailability(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> subscription,
    bool enableToday, // true => deliver today (unskip), false => skip today
  ) async {
    try {
      final db = ref.read(databaseProvider);
      final subRef = db.child('food_subscription').child(subscription['id']);

      final mealKey = mealType.name.toLowerCase(); // "lunch" | "dinner"
      final now = DateTime.now();
      final today = dateOnly(now);
      final todayIso = dfmt(today); // "yyyy-MM-dd"
      final deliveryHour = mealType == MealType.lunch ? 12 : 18;

      // ---- safe reads ----
      final mealDateRanges = Map<String, dynamic>.from(
        (subscription['mealDateRanges'] as Map?) ?? const {},
      );
      final mealRange = Map<String, dynamic>.from(
        (mealDateRanges[mealKey] as Map?) ?? const {},
      );

      // start date (fallback to today)
      DateTime startDate;
      final startStr = (mealRange['startDate'] as String?) ?? todayIso;
      try {
        startDate = DateTime.parse(startStr);
      } catch (_) {
        startDate = today;
      }

      // Purchased plan size (do NOT change this)
      final int planDays = toInt(subscription['planDays'], fallback: 0);

      // Read current per-meal skip set (supports old map or new arrays)
      Set<String> _readStringsForMeal(String m) => readMealDateStrings(
          subscription['skipDates'],
          m == 'lunch' ? MealType.lunch : MealType.dinner);

      // Active meal skip set as DateTimes
      final Set<DateTime> skipSet = _readStringsForMeal(mealKey)
          .map((s) => parseYmdLocal(s)) // "yyyy-MM-dd" -> local date
          .toSet();

      // Existing detailed schedule for diet lookup
      final List<Map<String, dynamic>> baseDetailed =
          normalizeDeliveriesDetailed(subscription['deliveriesDetailed']);

      // Guards
      if (today.weekday == DateTime.sunday || startDate.isAfter(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today is not a valid delivery day!')),
        );
        return;
      }

      // Toggle today in the active meal's set (no change to planDays)
      final bool isSkipped = skipSet.contains(today);
      if (enableToday && isSkipped) {
        skipSet.remove(today); // make today deliverable
      } else if (!enableToday && !isSkipped) {
        skipSet.add(today); // skip today
      } else {
        return; // no-op
      }

      // Rebuild exactly `planDays` delivery dates from startDate (skip Sundays & active-meal skips)
      final dates = <DateTime>[];
      var cursor = startDate;
      while (dates.length < planDays) {
        final d = dateOnly(cursor);
        if (d.weekday != DateTime.sunday && !skipSet.contains(d)) {
          dates.add(d);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      final DateTime newLast = dates.isNotEmpty ? dates.last : startDate;

      // Keep previous diet per day if known
      String dietFor(DateTime day) {
        final target = DateTime(day.year, day.month, day.day, deliveryHour);
        final hit = baseDetailed.firstWhere(
          (e) => DateTime.parse(e['date'].toString()).isAtSameMomentAs(target),
          orElse: () => const {'diet': 'nonVeg'},
        );
        return (hit['diet']?.toString() ?? 'nonVeg');
      }

      final deliveriesDetailed = dates
          .map((d) => {
                'date': DateTime(d.year, d.month, d.day, deliveryHour)
                    .toIso8601String(),
                'diet': dietFor(d),
              })
          .toList();

      // Update date range for the active meal
      mealDateRanges[mealKey] = {
        'startDate': dfmt(startDate),
        'endDate': dfmt(newLast),
      };

      final meals = (subscription['selectedMeals'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [mealKey];

      final Map<String, dynamic> skipDatesPayload = {};
      for (final m in meals) {
        if (m == mealKey) {
          // Active meal: updated list
          skipDatesPayload[m] = skipSet.map(dfmt).toList()..sort();
        } else {
          // Other meal: keep whatever exists
          skipDatesPayload[m] = _readStringsForMeal(m).toList()..sort();
        }
      }

      // ---- Keep vegDates as arrays per meal (unchanged) ----
      final Map<String, dynamic> vegDates =
          Map<String, dynamic>.from((subscription['vegDates'] as Map?) ?? {});
      final Set<String> vegSet = baseDetailed
          .where(
              (e) => (e['diet']?.toString().toLowerCase() ?? 'nonveg') == 'veg')
          .map((e) => dfmt(DateTime.parse(e['date'].toString())))
          .toSet();
      vegDates[mealKey] = vegDatesStringForMeal(vegSet);

      final payload = {
        'mealDateRanges': mealDateRanges,
      };
      if (vegDates.values.any((v) => v.toString().isNotEmpty)) {
        payload['vegDates'] = vegDates;
      }
      if (skipDatesPayload.values.any((v) => v.toString().isNotEmpty)) {
        payload['skipDates'] = skipDatesPayload;
      }
      await subRef.update(payload);

      final formattedNewDate = DateFormat('d/M/y').format(newLast);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enableToday
                ? 'Today enabled. Plan stays $planDays days, ends on $formattedNewDate'
                : 'Today skipped. Plan stays $planDays days, extended to $formattedNewDate',
          ),
        ),
      );

      ref.refresh(userSubscriptionsProvider(mealType));
    } catch (e, st) {
      debugPrint('[_toggleAvailability] Error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: $e')),
        );
      }
    }
  }
}

class SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final MealType mealType;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleAvailability;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.mealType,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    // Dates & status
    final startDate = DateTime.parse(
      subscription['mealDateRanges'][mealType.name.toLowerCase()]['startDate'],
    );
    final endDate = DateTime.parse(
      subscription['mealDateRanges'][mealType.name.toLowerCase()]['endDate'],
    );
    final now = DateTime.now();
    final isActive = now.isBefore(endDate);
    final daysLeft =
        endDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    final selectedMeals = (subscription['selectedMeals'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const <String>[];
    final hasLunch = selectedMeals.contains('lunch');
    final hasDinner = selectedMeals.contains('dinner');
    final planLabel = '${mealType.name.capitalize()} Plan';

    // Per-meal sets (arrays of yyyy-MM-dd strings)
    final vegSetAll = readMealDateStrings(subscription['vegDates'], mealType);
    final skipSetAll = readMealDateStrings(subscription['skipDates'], mealType);

    // Count only dates within the plan window
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    int _countInRange(Set<String> set) {
      int c = 0;
      for (final s in set) {
        final d = parseYmdLocal(s);
        if (!d.isBefore(startOnly) && !d.isAfter(endOnly)) c++;
      }
      return c;
    }

    final vegCount = _countInRange(vegSetAll);
    final skipCount = _countInRange(skipSetAll);
    final todaySkipped = skipSetAll.contains(dfmt(now));
    final planDays = (subscription['planDays'] as num?)?.toInt() ?? 0;
    final exactDays = _exactPlanDays(subscription, mealType);

    // Colors & icons by meal (for header gradient + action button)
    final isLunchView = mealType == MealType.lunch;
    final mealColor =
        isLunchView ? const Color(0xFFFFB74D) : const Color(0xFF90A4AE);
    final mealDark =
        isLunchView ? const Color(0xFFF57C00) : const Color(0xFF455A64);
    final mealIcon =
        isLunchView ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded;

    // Diet (Veg/Non-Veg) label (from your payload field)
    final dietLabel = (subscription['mealType'] ?? '').toString();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final inWindow =
        !todayOnly.isBefore(startOnly) && !todayOnly.isAfter(endOnly);
    final todayIsSunday = todayOnly.weekday == DateTime.sunday;

    bool isEditableToday(MealType mealType) {
      final now = DateTime.now();
      final cutoffHour = mealType == MealType.lunch ? 11 : 17; // 11 AM, 5 PM
      final cutoff = DateTime(now.year, now.month, now.day, cutoffHour);
      return now.isBefore(cutoff);
    }

    final isDeliverableDayToday = inWindow && !todayIsSunday;
    final isToday = DateTime(now.year, now.month, now.day).isAtSameMomentAs(
        DateTime.now().copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
    final canEditToday = isEditableToday(mealType);
    final skipActionEnabled = !isToday || (isToday && canEditToday);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mealColor, mealColor.withOpacity(.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(mealIcon, color: mealDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan label (Lunch/Dinner/2-Meal) as the main title
                          Text(
                            planLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Ends in / expired
                          Text(
                            isActive
                                ? 'Ends in ${daysLeft.clamp(0, 9999)} day${daysLeft.abs() == 1 ? '' : 's'}'
                                : 'Expired ${daysLeft.abs()} day${daysLeft.abs() == 1 ? '' : 's'} ago',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.95),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(isActive),
                  ],
                ),

                const SizedBox(height: 10),

                // Plan chips: Lunch / Dinner indicators + Veg/Non-Veg chip
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (hasLunch) _planBadge(Icons.wb_sunny_rounded, 'Lunch'),
                    if (hasDinner)
                      _planBadge(Icons.nightlight_round_rounded, 'Dinner'),
                    _dietBadge(dietLabel), // Veg / Non Veg
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconText(Icons.play_arrow_rounded, 'Start',
                        DateFormat('d/M/y').format(startDate)),
                    const SizedBox(width: 12),
                    _iconText(Icons.flag_rounded, 'End',
                        DateFormat('d/M/y').format(endDate)),
                  ],
                ),
                const SizedBox(height: 10),

                // Counts (within range)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(
                        Icons.calendar_month_rounded, 'Plan Days', '$planDays'),
                    _pill(Icons.eco_rounded, 'Veg Days', '$vegCount'),
                    _pill(
                        Icons.do_not_disturb_on_rounded, 'Skips', '$skipCount'),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  height: 1,
                  color: Colors.grey.withOpacity(.15),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                ),

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: skipActionEnabled
                          ? (todaySkipped
                              ? 'Enable delivery for today'
                              : 'Skip delivery for today')
                          : (mealType == MealType.lunch
                              ? 'Lunch for today is locked after 11:00 AM'
                              : 'Dinner for today is locked after 5:00 PM'),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: mealDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: skipActionEnabled
                            ? () => onToggleAvailability(todaySkipped)
                            : null,
                        icon: Icon(
                          todaySkipped
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_filled_rounded,
                          size: 18,
                        ),
                        label:
                            Text(todaySkipped ? 'Enable Today' : 'Skip Today'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        mealType == MealType.lunch
                            ? 'Heads up: Today’s lunch is editable until 11:00 AM.'
                            : 'Heads up: Today’s dinner is editable until 5:00 PM.',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- small UI helpers ---

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? const Color(0xFF66BB6A) : const Color(0xFFE57373),
          width: 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.error_rounded,
          size: 16,
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Active' : 'Expired',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
      ]),
    );
  }

  Widget _planBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _dietBadge(String dietLabel) {
    final isVeg = dietLabel.toLowerCase().contains('veg') &&
        !dietLabel.toLowerCase().contains('non');
    final c = isVeg ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    final bg = isVeg ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
            size: 14, color: c),
        const SizedBox(width: 6),
        Text(
          isVeg ? 'Veg' : 'Non-Veg',
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ]),
    );
  }

  Widget _pill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: Colors.black.withOpacity(.65)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.black.withOpacity(.62),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _iconText(IconData icon, String label, String value) {
    return Expanded(
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.black.withOpacity(.6)),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.black.withOpacity(.85),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: '$label  ',
                  style: TextStyle(
                    color: Colors.black.withOpacity(.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _SkipDaysGrid extends ConsumerWidget {
  final DateTime start;
  final int horizonDays;
  final bool Function(DateTime) isSkipped;
  final MealType mealType;
  final bool isPrimaryMeal;
  final void Function(DateTime, DietType?) onDayTap;

  final DietType? Function(DateTime day) dietOf;

  const _SkipDaysGrid({
    required this.start,
    required this.horizonDays,
    required this.isSkipped,
    required this.mealType,
    required this.isPrimaryMeal,
    required this.onDayTap,
    required this.dietOf,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = List.generate(
      horizonDays,
      (i) => dateOnly(start.add(Duration(days: i))),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final isSun = d.weekday == DateTime.sunday;
        final skipped = isSkipped(d);
        final diet = dietOf(d); // DietType? for that day (date-only)

        final bg = skipped
            ? Colors.red.withAlpha(14)
            : isSun
                ? Colors.grey.withAlpha(14)
                : Colors.green.withAlpha(14);
        final br = skipped
            ? Colors.red
            : isSun
                ? Colors.black
                : Colors.green;

        // Show dot ONLY for veg (green); otherwise transparent
        final dotVisible = diet == DietType.veg;
        final dotColor = Colors.green;

        return GestureDetector(
          onTap: () => onDayTap(d, diet),
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: br),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${d.day}',
                  style: TextStyle(
                    fontWeight: skipped ? FontWeight.w800 : FontWeight.w600,
                    color: isSun ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                left: 30,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotVisible ? dotColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isSun)
                const Positioned(
                  top: 28,
                  left: 2,
                  right: 2,
                  child: Text(
                    'SUNDAY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (isSkipped(d) && !isSun)
                Positioned(
                    bottom: 2,
                    right: 3,
                    child: Text('SKIPPED',
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SubscriptionEditDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> subscription;
  final MealType mealType;

  const SubscriptionEditDialog({
    super.key,
    required this.subscription,
    required this.mealType,
  });

  @override
  ConsumerState<SubscriptionEditDialog> createState() =>
      _SubscriptionEditDialogState();
}

class _SubscriptionEditDialogState
    extends ConsumerState<SubscriptionEditDialog> {
  late DateTime startDate;
  late int planDays;

  // Keep separate state for each meal so we can show Lunch + Dinner sections.
  late Set<DateTime> skipDatesPrimary;
  late Map<DateTime, DietType> dietOverridesPrimary;
  late Set<String> vegSetPrimary;

  late Set<DateTime> skipDatesSecondary;
  late Map<DateTime, DietType> dietOverridesSecondary;

  late Set<String> allergies;

  MealType get _primary => widget.mealType;
  MealType get _secondary =>
      widget.mealType == MealType.lunch ? MealType.dinner : MealType.lunch;

  bool get _isTwoMeals {
    final meals = (widget.subscription['selectedMeals'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];
    return meals.length > 1;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime parseYmdLocal(String ymd) {
    final d = DateFormat('yyyy-MM-dd').parseStrict(ymd);
    return DateTime(d.year, d.month, d.day);
  }

  /// Build the actual scheduled delivery dates for a meal: non-Sunday, not in skip set, until `planDays` dates.
  List<DateTime> _buildSchedule(DateTime start, int days, Set<DateTime> skip) {
    final out = <DateTime>[];
    var cur = _dateOnly(start);
    while (out.length < days) {
      final day = _dateOnly(cur);
      if (day.weekday != DateTime.sunday && !skip.contains(day)) {
        out.add(day);
      }
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }

  Set<DateTime> _readSkipDatesFor(MealType meal) {
    final ss = readMealDateStrings(widget.subscription['skipDates'], meal);
    return ss.map(parseYmdLocal).toSet();
  }

  Map<DateTime, DietType> _readVegOverridesFor(MealType meal) {
    final veg = readMealDateStrings(widget.subscription['vegDates'], meal);
    return {
      for (final s in veg) parseYmdLocal(s): DietType.veg,
    };
  }

  @override
  void initState() {
    super.initState();

    startDate = DateTime.parse(
      widget.subscription['mealDateRanges'][widget.mealType.name.toLowerCase()]
          ['startDate'],
    );
    planDays = (widget.subscription['planDays'] as num?)?.toInt() ?? 0;

    // Primary meal state
    skipDatesPrimary = _readSkipDatesFor(_primary);
    dietOverridesPrimary = _readVegOverridesFor(_primary);

    // Secondary meal state (if any); otherwise keep empty sets.
    if (_isTwoMeals) {
      skipDatesSecondary = _readSkipDatesFor(_secondary);
      dietOverridesSecondary = _readVegOverridesFor(_secondary);
    } else {
      skipDatesSecondary = <DateTime>{};
      dietOverridesSecondary = <DateTime, DietType>{};
    }

    allergies = (widget.subscription['allergies'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    vegSetPrimary =
        readMealDateStrings(widget.subscription['vegDates'], _primary);
  }

  @override
  Widget build(BuildContext context) {
    final ingrAsync = ref.watch(ingredientsProvider(widget.mealType));

    final schedulePrimary =
        _buildSchedule(startDate, planDays, skipDatesPrimary);
    final windowPrimary = _buildWindowFromSchedule(startDate, schedulePrimary);
    final scheduleSetP = schedulePrimary.map(_dOnly).toSet();
    return AlertDialog(
      title: Text('Edit ${widget.mealType.name} Subscription'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(Icons.calendar_today, 'Start Date'),
            const SizedBox(height: 8),
            _DatePickerTile(
              date: startDate,
              onPick: (d) => setState(() => startDate = _dateOnly(d)),
            ),
            const SizedBox(height: 16),
            _SectionTitle(
              widget.mealType == MealType.lunch
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round_rounded,
              '${_primary.name.capitalize()} Dates',
            ),
            const SizedBox(height: 8),
            _CalendarGridWindow(
              window: windowPrimary,
              isDelivery: (day) => scheduleSetP.contains(_dOnly(day)),
              isSkipped: (day) => skipDatesPrimary.contains(_dOnly(day)),
              dietOf: (d) => vegSetPrimary.contains(dfmt(d))
                  ? DietType.veg
                  : DietType.nonVeg,
              isLocked: (day) {
                final now = DateTime.now();
                final dOnly = _dateOnly(day);
                final todayOnly = _dateOnly(now);
                final isToday = dOnly.isAtSameMomentAs(todayOnly);
                if (!isToday) return false;

                // Lock exactly at 11:00 / 17:00
                final cutoffHour = _primary == MealType.lunch ? 11 : 17;
                final cutoff = DateTime(
                    todayOnly.year, todayOnly.month, todayOnly.day, cutoffHour);
                return !now.isBefore(cutoff); // >= cutoff → locked
              },
              onDayTap: (day) {
                final now = DateTime.now();
                print('Tapped day: $day, now: $now');
                final dOnly = _dateOnly(day);
                final todayOnly = _dateOnly(now);
                final isToday = dOnly.isAtSameMomentAs(todayOnly);
                final cutoffHour = _primary == MealType.lunch ? 11 : 17;
                final cutoff = DateTime(
                    todayOnly.year, todayOnly.month, todayOnly.day, cutoffHour);
                if (isToday) {
                  // Lock today if past cutoff
                  if (now.isBefore(cutoff)) {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_clock_rounded,
                                  size: 32,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_primary.name.capitalize()} Locked',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You can no longer edit today’s ${_primary.name.toLowerCase()}.\n'
                                'Changes are allowed only before '
                                '${_primary == MealType.lunch ? '11:00 AM' : '5:00 PM'}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.black.withOpacity(.65),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18),
                                label: const Text('Got it'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                }

                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => _DayEditSheet(
                    day: day,
                    isAvailable: !skipDatesPrimary.contains(day),
                    isAvailableSecondary: false,
                    currentOverride: dietOverridesPrimary[day],
                    isTwoMeals: _isTwoMeals,
                    primaryMealType: _primary,
                    isPrimaryMeal: true,
                    onSave: (available, _, override) {
                      setState(() {
                        if (available) {
                          skipDatesPrimary.remove(day);
                        } else {
                          skipDatesPrimary.add(day);
                        }
                        if (override != null) {
                          if (override == DietType.veg) {
                            vegSetPrimary.add(dfmt(day));
                          } else {
                            vegSetPrimary.remove(dfmt(day));
                          }
                          dietOverridesPrimary[day] = override;
                          setState(() {});
                        } else {
                          vegSetPrimary.remove(dfmt(day));

                          dietOverridesPrimary.remove(day);
                          setState(() {});
                        }
                      });
                    },
                  ),
                );
              },
            ),
            // if (_isTwoMeals) ...[
            //   const SizedBox(height: 16),
            //   _SectionTitle(
            //     widget.mealType == MealType.lunch
            //         ? Icons.wb_sunny_rounded
            //         : Icons.nightlight_round_rounded,
            //     '${_secondary.name.capitalize()} Dates',
            //   ),
            //   const SizedBox(height: 8),
            //   _CalendarGridWindow(
            //     window: windowSecondary,
            //     isDelivery: (day) => scheduleSetS.contains(_dOnly(day)),
            //     isSkipped: (day) => skipDatesSecondary.contains(_dOnly(day)),
            //     dietOf: (d) => vegSetSecondary.contains(dfmt(d))
            //         ? DietType.veg
            //         : DietType.nonVeg,
            //     onDayTap: (day) {
            //       showModalBottomSheet(
            //         context: context,
            //         showDragHandle: true,
            //         builder: (_) => _DayEditSheet(
            //           day: day,
            //           isAvailable: !skipDatesSecondary.contains(day),
            //           isAvailableSecondary: false,
            //           currentOverride: dietOverridesSecondary[day],
            //           isTwoMeals: _isTwoMeals,
            //           primaryMealType: _secondary,
            //           isPrimaryMeal: false,
            //           onSave: (available, _, override) {
            //             setState(() {
            //               if (available) {
            //                 skipDatesSecondary.remove(day);
            //               } else {
            //                 skipDatesSecondary.add(day);
            //               }
            //               if (override != null) {
            //                 dietOverridesSecondary[day] = override;
            //               } else {
            //                 dietOverridesSecondary.remove(day);
            //               }
            //             });
            //           },
            //         ),
            //       );
            //     },
            //   ),
            // ],
            const SizedBox(height: 18),
            if (ingrAsync.hasValue &&
                (ingrAsync.value?.isNotEmpty ?? false)) ...[
              const _SectionTitle(Icons.health_and_safety_rounded, 'Allergies'),
              const SizedBox(height: 8),
              ingrAsync.when(
                data: (items) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map((label) => FilterChip(
                            label: Text(label),
                            selected: allergies.contains(label),
                            onSelected: (_) => setState(() {
                              allergies.contains(label)
                                  ? allergies.remove(label)
                                  : allergies.add(label);
                            }),
                          ))
                      .toList(),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load ingredients: $e'),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await _updateSubscription(context, ref);
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }

  Future<void> _updateSubscription(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final subRef =
        db.child('food_subscription').child(widget.subscription['id']);

    final meals = (widget.subscription['selectedMeals'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [widget.mealType.name.toLowerCase()];

    // Build schedules from current UI state for each meal we show
    final isTwo = _isTwoMeals;
    final primaryKey = _primary.name.toLowerCase();
    final secondaryKey = _secondary.name.toLowerCase();

    final scheduleP = _buildSchedule(startDate, planDays, skipDatesPrimary);
    final scheduleS = isTwo
        ? _buildSchedule(startDate, planDays, skipDatesSecondary)
        : const <DateTime>[];

    // deliveriesDetailed for BOTH meals (so UI changes reflect)
    final deliveriesDetailed = <Map<String, dynamic>>[];

    final mealDateRanges =
        Map<String, dynamic>.from(widget.subscription['mealDateRanges'] ?? {});
    mealDateRanges[primaryKey] = {
      'startDate': dfmt(startDate),
      'endDate': dfmt(scheduleP.isNotEmpty ? scheduleP.last : startDate),
    };
    if (isTwo) {
      mealDateRanges[secondaryKey] = {
        'startDate': dfmt(startDate),
        'endDate': dfmt(scheduleS.isNotEmpty ? scheduleS.last : startDate),
      };
    }

    // Per-meal veg/skip arrays (yyyy-MM-dd)
    final vegDatesPayload = <String, List<String>>{
      primaryKey: (scheduleP
          .where((d) => dietOverridesPrimary[d] == DietType.veg)
          .map(dfmt)
          .toList()
        ..sort()),
      if (isTwo)
        secondaryKey: (scheduleS
            .where((d) => dietOverridesSecondary[d] == DietType.veg)
            .map(dfmt)
            .toList()
          ..sort()),
    };

    final skipDatesPayload = <String, List<String>>{
      primaryKey: (skipDatesPrimary.map(dfmt).toList()..sort()),
      if (isTwo) secondaryKey: (skipDatesSecondary.map(dfmt).toList()..sort()),
    };

    final payload = {
      'startDate': startDate.toIso8601String(),
      'planDays': planDays,
      'mealDateRanges': mealDateRanges,
      'vegDates': vegDatesPayload,
      'skipDates': skipDatesPayload,
      'allergies': allergies.toList(),
      'diet':
          deliveriesDetailed.any((e) => e['diet'] == 'veg') ? 'veg' : 'nonVeg',
      'pricing': widget.subscription['pricing'],
      'selectedMeals': widget.subscription['selectedMeals'],
      'selectedMealCount': widget.subscription['selectedMealCount'],
    };

    await subRef.update(payload);

    ref.refresh(userSubscriptionsProvider(widget.mealType));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription updated!')),
      );
      Navigator.pop(context);
    }
  }
}

/// Calendar window grid that shows every day in a window:
/// - green dot = veg, red dot = non-veg (only on delivery days)
/// - SKIPPED DAY badge (top-right)
/// - SUNDAY badge (top-right)
/// Delivery tiles get green background; skipped = red; sunday = grey.
class _CalendarGridWindow extends StatefulWidget {
  final List<DateTime> window; // all days in the window (date-only)
  final bool Function(DateTime)
      isDelivery; // true only for actual delivery dates
  final bool Function(DateTime) isSkipped; // per-meal skip set
  final DietType? Function(DateTime)
      dietOf; // return diet for delivery day; null for non-delivery
  final void Function(DateTime) onDayTap;
  final bool showLegend;
  final bool Function(DateTime day)? isLocked;

  const _CalendarGridWindow(
      {super.key,
      required this.window,
      required this.isDelivery,
      required this.isSkipped,
      required this.dietOf,
      required this.onDayTap,
      this.showLegend = true,
      this.isLocked});

  @override
  State<_CalendarGridWindow> createState() => _CalendarGridWindowState();
}

class _CalendarGridWindowState extends State<_CalendarGridWindow> {
  @override
  Widget build(BuildContext context) {
    final todayOnly = dateOnly(DateTime.now()); // your existing helper

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLegend) _legendRow(),
        if (widget.showLegend) const SizedBox(height: 8),
        if (widget.window.isEmpty)
          const Text('No dates in range.')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.window.map((day) {
              final sunday = day.weekday == DateTime.sunday;
              final skipped = widget.isSkipped(day);
              final delivery = widget.isDelivery(day);
              final isPast = day.isBefore(todayOnly);

              // Background + border priority: SUNDAY > SKIPPED > DELIVERY > OTHER
              late Color bg, br, numColor;
              if (sunday) {
                bg = Colors.grey.withAlpha(14);
                br = Colors.black45;
                numColor = Colors.grey.shade700;
              } else if (skipped) {
                bg = Colors.red.withAlpha(14);
                br = Colors.red;
                numColor = Colors.black87;
              } else if (delivery) {
                bg = Colors.green.withAlpha(14);
                br = Colors.green;
                numColor = Colors.black87;
              } else {
                bg = Colors.grey.withAlpha(8);
                br = Colors.grey.withOpacity(.35);
                numColor = Colors.black54;
              }

              // Dimming past days visually (not editable)
              final double opacity = isPast ? 0.45 : 1.0;

              // Decide which overlay icon to show:
              // - Sunday icon if Sunday
              // - Skipped icon if skipped
              // - Diet icon (veg/non-veg) only for delivery days that are NOT skipped
              IconData? overlayIcon;
              Color? overlayColor;

              if (sunday) {
                overlayIcon = Icons.event_busy_rounded;
                overlayColor = Colors.orange.shade700;
              } else if (skipped) {
                overlayIcon = Icons.block_rounded;
                overlayColor = Colors.red.shade700;
              } else if (delivery) {
                final DietType? diet = widget.dietOf(day);
                if (diet != null) {
                  if (diet == DietType.veg) {
                    overlayIcon = Icons.eco_rounded;
                    overlayColor = Colors.green.shade700;
                  } else {
                    overlayIcon = Icons.restaurant_rounded;
                    overlayColor = Colors.red.shade700;
                  }
                }
              }

              return GestureDetector(
                onTap: () {
                  if (!isPast && (delivery || skipped)) {
                    widget.onDayTap(day);
                  }
                },
                child: Opacity(
                  opacity: opacity,
                  child: Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: br),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight:
                                skipped ? FontWeight.w800 : FontWeight.w600,
                            color: numColor,
                          ),
                        ),
                      ),
                      if (overlayIcon != null && overlayColor != null)
                        Positioned(
                          right: 3,
                          bottom: 3,
                          child: Icon(
                            overlayIcon,
                            size: 14,
                            color: overlayColor,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _legendRow() {
    Widget chip(Color c, String text, {IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withOpacity(.28)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: c.withOpacity(.9)),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: c.withOpacity(.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Colors.green, 'Veg', icon: Icons.eco_rounded),
        chip(Colors.red, 'Non-Veg', icon: Icons.restaurant_rounded),
        chip(Colors.red, 'Skipped Day', icon: Icons.block_rounded),
        chip(Colors.orange, 'Sunday', icon: Icons.event_busy_rounded),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle(this.icon, this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
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

class _DayEditSheet extends StatefulWidget {
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
  State<_DayEditSheet> createState() => _DayEditSheetState();
}

class _DayEditSheetState extends State<_DayEditSheet> {
  IconData _mealIcon(MealType mealType) =>
      mealType == MealType.lunch ? Icons.wb_sunny : Icons.nightlight_round;

  Color _mealColor(MealType mealType, BuildContext context) =>
      mealType == MealType.lunch ? Colors.orange : Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    bool available = widget.isAvailable;
    bool availableSecondary = widget.isAvailableSecondary;
    DietType? override = widget.currentOverride;

    final mealC = _mealColor(widget.primaryMealType, context);

    return StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_mealIcon(widget.primaryMealType), color: mealC),
                  const SizedBox(width: 8),
                  Text(
                      'Customize ${widget.day.day}/${widget.day.month}/${widget.day.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(.03),
                ),
                child: SwitchListTile(
                  title:
                      Text("I'm available for ${widget.primaryMealType.name}"),
                  value: available,
                  onChanged: widget.day.weekday == DateTime.sunday
                      ? null
                      : (v) => setState(() => available = v),
                ),
              ),
              const SizedBox(height: 12),
              const _SectionTitle(Icons.ramen_dining_rounded, 'Diet override'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Non-Veg')),
                  ButtonSegment(value: 1, label: Text('Veg')),
                ],
                selected: {override == DietType.veg ? 1 : 0},
                onSelectionChanged: (s) {
                  final v = s.first;
                  setState(() => override = (v == 1) ? DietType.veg : null);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  widget.onSave(available, availableSecondary, override);
                  Navigator.pop(context);
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
