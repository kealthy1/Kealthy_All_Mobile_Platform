import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart';
import 'package:kealthy/view/subscription/lunch_sub_confirmation.dart';
import 'package:intl/intl.dart';

// yyyy-MM-dd for RTDB keys
String dfmt(DateTime d) =>
    DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

String normalizePhone(String? s) => (s ?? '')
    .replaceAll(RegExp(r'\D'), ''); // keep consistent with stored value

Set<String> readSkipDates(dynamic raw) {
  if (raw == null) return {};
  if (raw is List) return raw.map((e) => e.toString()).toSet();
  if (raw is Map) {
    // { "yyyy-MM-dd": true }
    return raw.entries
        .where((e) =>
            e.value == true || e.value == 1 || e.value?.toString() == 'true')
        .map((e) => e.key.toString())
        .toSet();
  }
  return {};
}

Map<String, dynamic> skipDatesToMap(Set<String> set) =>
    {for (final s in set) s: true};

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

final userSubscriptionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, MealType>(
        (ref, mealType) {
  final db = ref.watch(databaseProvider);
  final rawPhone = ref.watch(phoneNumberProvider); // watch, not read
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

    // Optional: sort by customer.name (case-insensitive)
    list.sort((a, b) => (a['customer']?['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['customer']?['name'] ?? '').toString().toLowerCase()));

    return list;
  });
});

class LunchDinnerPlanPage extends ConsumerWidget {
  final MealType mealType;
  const LunchDinnerPlanPage({super.key, required this.mealType});

  String get _title => mealType == MealType.lunch
      ? 'Lunch Subscriptions'
      : 'Dinner Subscriptions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider(mealType));
    final selectedAddress = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
        child: subscriptionsAsync.when(
          data: (subscriptions) {
            final filteredSubscriptions = subscriptions
                .where((sub) =>
                    sub['selectedMeals'].contains(mealType.name.toLowerCase()))
                .toList();
            if (filteredSubscriptions.isEmpty) {
              return const Center(
                child: Text(
                  'No subscriptions found for this meal type. Create a new one!',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
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
    bool available, // true = deliver today, false = skip today
  ) async {
    final db = ref.read(databaseProvider);
    final subRef = db.child('food_subscription').child(subscription['id']);

    final mealKey = mealType.name.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIso = dfmt(today);
    final deliveryHour = mealType == MealType.lunch ? 12 : 18;

    final mealDateRanges =
        Map<String, dynamic>.from(subscription['mealDateRanges'] ?? {});
    final mealRange = Map<String, dynamic>.from(mealDateRanges[mealKey] ?? {});
    final startDate =
        DateTime.parse((mealRange['startDate'] ?? todayIso) as String);

    final planDays = toInt(subscription['planDays'], fallback: 0);
    final skipSet = readSkipDates(subscription['skipDates']);
    final baseDetailed =
        normalizeDeliveriesDetailed(subscription['deliveriesDetailed']);

    if (today.weekday == DateTime.sunday || startDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today is not a valid delivery day!')),
      );
      return;
    }

    final isSkipped = skipSet.contains(todayIso);
    if (available && isSkipped) {
      skipSet.remove(todayIso);
    } else if (!available && !isSkipped) {
      skipSet.add(todayIso);
    } else {
      return; // no change
    }

    final newPlanDays = available ? (planDays - 1) : (planDays + 1);
    if (newPlanDays < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot reduce plan days below 1!')),
      );
      return;
    }

    // Rebuild schedule
    final dates = <DateTime>[];
    var cursor = startDate;
    while (dates.length < newPlanDays) {
      final d = DateTime(cursor.year, cursor.month, cursor.day);
      if (d.weekday != DateTime.sunday && !skipSet.contains(dfmt(d))) {
        dates.add(d);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    final newLast = dates.isNotEmpty ? dates.last : startDate;

    String dietFor(DateTime day) {
      final target = DateTime(day.year, day.month, day.day, deliveryHour);
      final hit = baseDetailed.firstWhere(
        (e) => DateTime.parse(e['date'].toString()).isAtSameMomentAs(target),
        orElse: () => const {'diet': 'nonVeg'},
      );
      return hit['diet']?.toString() ?? 'nonVeg';
    }

    final deliveriesDetailed = dates
        .map((d) => {
              'date': DateTime(d.year, d.month, d.day, deliveryHour)
                  .toIso8601String(),
              'diet': dietFor(d),
            })
        .toList();

    final deliveriesIso =
        deliveriesDetailed.map((e) => e['date'] as String).toList();

    mealDateRanges[mealKey] = {
      'startDate': dfmt(startDate),
      'endDate': dfmt(newLast),
    };

    final payload = {
      // ✅ store as map in RTDB to avoid array issues
      'skipDates': skipDatesToMap(skipSet),
      // If other parts of your app still expect a list, swap the line above for:
      // 'skipDates': skipSet.toList(),
      'planDays': newPlanDays,
      'deliveries': deliveriesIso,
      'deliveriesDetailed': deliveriesDetailed,
      'mealDateRanges': mealDateRanges,
    };

    await subRef.update(payload);

    final formattedNewDate = DateFormat('d/M/y').format(newLast);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          available
              ? 'Today added to subscription, ends on $formattedNewDate'
              : 'Today skipped, subscription extended to $formattedNewDate',
        ),
      ),
    );

    ref.refresh(userSubscriptionsProvider(mealType));
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
    final startDate = DateTime.parse(subscription['mealDateRanges']
        [mealType.name.toLowerCase()]['startDate']);
    final endDate = DateTime.parse(
        subscription['mealDateRanges'][mealType.name.toLowerCase()]['endDate']);
    final isActive = DateTime.now().isBefore(endDate);
    Set<String> getSkipDates(dynamic raw) {
      if (raw == null) return {};
      if (raw is List) return raw.map((e) => e.toString()).toSet();
      if (raw is Map) {
        // if you store { "2025-09-18": true, ... }
        return raw.entries
            .where((e) => e.value == true || e.value == 1)
            .map((e) => e.key.toString())
            .toSet();
      }
      return {};
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final skipDates = getSkipDates(subscription['skipDates']);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subscription['mealType']} Subscription',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Plan Days: ${subscription['planDays']}'),
            Text('Start: ${DateFormat('d/M/y').format(startDate)}'),
            Text('End: ${DateFormat('d/M/y').format(endDate)}'),
            Text('Status: ${isActive ? 'Active' : 'Expired'}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () =>
                      onToggleAvailability(!skipDates.contains(today)),
                  child: Text(skipDates.contains(today)
                      ? 'Enable Today'
                      : 'Skip Today'),
                )
              ],
            ),
          ],
        ),
      ),
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
  late Set<DateTime> skipDates;
  late Set<String> allergies;
  late Map<DateTime, DietType> dietOverrides;

  @override
  void initState() {
    super.initState();
    startDate = DateTime.parse(widget.subscription['mealDateRanges']
        [widget.mealType.name.toLowerCase()]['startDate']);
    planDays = widget.subscription['planDays'] as int;
    skipDates = (widget.subscription['skipDates'] as List<dynamic>? ?? [])
        .map((e) => DateTime.parse(e as String))
        .toSet();
    allergies = (widget.subscription['allergies'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    dietOverrides =
        (widget.subscription['deliveriesDetailed'] as List<dynamic>? ?? [])
            .asMap()
            .map((_, entry) => MapEntry(
                  DateTime.parse(entry['date'] as String),
                  entry['diet'] == 'veg' ? DietType.veg : DietType.nonVeg,
                ));
  }

  @override
  Widget build(BuildContext context) {
    final ingrAsync = ref.watch(ingredientsProvider(widget.mealType));

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
              onPick: (d) => setState(() => startDate = d),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(Icons.event_available, 'Delivery Days'),
            const SizedBox(height: 8),
            _SkipDaysGrid(
              start: startDate,
              horizonDays: planDays + skipDates.length + 7,
              isSkipped: (d) =>
                  skipDates.contains(d) || d.weekday == DateTime.sunday,
              mealType: widget.mealType,
              isPrimaryMeal: true,
              ref: ref,
              onDayTap: (day, override) {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => _DayEditSheet(
                    day: day,
                    isAvailable: !skipDates.contains(day),
                    isAvailableSecondary: false,
                    currentOverride: dietOverrides[day],
                    isTwoMeals: widget.subscription['selectedMealCount'] == 2,
                    primaryMealType: widget.mealType,
                    isPrimaryMeal: true,
                    onSave: (available, _, override) {
                      setState(() {
                        if (available) {
                          skipDates.remove(day);
                        } else {
                          skipDates.add(day);
                        }
                        if (override != null) {
                          dietOverrides[day] = override;
                        } else {
                          dietOverrides.remove(day);
                        }
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (ingrAsync.hasValue && ingrAsync.value!.isNotEmpty) ...[
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
            if (context.mounted) Navigator.pop(context);
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
    final deliveryHour = widget.mealType == MealType.lunch ? 12 : 18;

    final dates = <DateTime>[];
    var cursor = startDate;
    while (dates.length < planDays) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (day.weekday != DateTime.sunday && !skipDates.contains(day)) {
        dates.add(day);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    final deliveriesDetailed = dates
        .map((d) => {
              'date': DateTime(d.year, d.month, d.day, deliveryHour)
                  .toIso8601String(),
              'diet': dietOverrides[d] == DietType.veg ? 'veg' : 'nonVeg',
            })
        .toList();

    final deliveriesIso = dates
        .map((d) =>
            DateTime(d.year, d.month, d.day, deliveryHour).toIso8601String())
        .toList();

    final mealDateRanges =
        Map<String, dynamic>.from(widget.subscription['mealDateRanges']);
    mealDateRanges[widget.mealType.name.toLowerCase()] = {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd')
          .format(dates.isNotEmpty ? dates.last : startDate),
    };

    final payload = {
      'diet':
          dietOverrides.values.any((d) => d == DietType.veg) ? 'veg' : 'nonVeg',
      'allergies': allergies.toList(),
      'startDate': startDate.toIso8601String(),
      'skipDates':
          skipDates.map((d) => d.toIso8601String().substring(0, 10)).toList(),
      'planDays': planDays,
      'deliveries': deliveriesIso,
      'deliveriesDetailed': deliveriesDetailed,
      'mealDateRanges': mealDateRanges,
      'pricing': widget.subscription['pricing'],
      'selectedMeals': widget.subscription['selectedMeals'],
      'selectedMealCount': widget.subscription['selectedMealCount'],
    };

    await subRef.update(payload);

    ref.refresh(userSubscriptionsProvider(widget.mealType));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription updated!')),
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

class _SkipDaysGrid extends ConsumerWidget {
  final DateTime start;
  final int horizonDays;
  final bool Function(DateTime) isSkipped;
  final MealType mealType;
  final bool isPrimaryMeal;
  final WidgetRef ref;
  final void Function(DateTime, DietType?) onDayTap;

  const _SkipDaysGrid({
    required this.start,
    required this.horizonDays,
    required this.isSkipped,
    required this.mealType,
    required this.isPrimaryMeal,
    required this.ref,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = List.generate(
        horizonDays,
        (i) => DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final isSun = d.weekday == DateTime.sunday;
        final isSkipped = this.isSkipped(d);
        final overrideDiet =
            ref.read(lunchDinnerProvider.notifier).dietForDate(d);
        final bg = isSkipped
            ? Colors.red.withAlpha(14)
            : isSun
                ? Colors.grey.withAlpha(14)
                : Colors.green.withAlpha(14);
        final br = isSkipped
            ? Colors.red
            : isSun
                ? Colors.black
                : Colors.green;
        final dotColor =
            overrideDiet == DietType.veg ? Colors.green : Colors.red;

        return GestureDetector(
          onTap: () => onDayTap(d, overrideDiet),
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
                    fontWeight: isSkipped ? FontWeight.w800 : FontWeight.w600,
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
                    color: overrideDiet != null ? dotColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isSun)
                Positioned(
                  top: 28,
                  left: 2,
                  right: 2,
                  child: Text(
                    'SUNDAY',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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

  IconData _mealIcon(MealType mealType) =>
      mealType == MealType.lunch ? Icons.wb_sunny : Icons.nightlight_round;

  Color _mealColor(MealType mealType, BuildContext context) =>
      mealType == MealType.lunch ? Colors.orange : Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    bool available = isAvailable;
    bool availableSecondary = isAvailableSecondary;
    DietType? override = currentOverride;

    final mealC = _mealColor(primaryMealType, context);

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
                  Icon(_mealIcon(primaryMealType), color: mealC),
                  const SizedBox(width: 8),
                  Text('Customize ${day.day}/${day.month}/${day.year}',
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
                  title: Text("I'm available for ${primaryMealType.name}"),
                  value: available,
                  onChanged: day.weekday == DateTime.sunday
                      ? null
                      : (v) => setState(() => available = v),
                ),
              ),
              if (isTwoMeals) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(.03),
                  ),
                  child: SwitchListTile(
                    title: Text(
                        "I'm available for ${(primaryMealType == MealType.lunch ? MealType.dinner : MealType.lunch).name}"),
                    value: availableSecondary,
                    onChanged: day.weekday == DateTime.sunday
                        ? null
                        : (v) => setState(() => availableSecondary = v),
                  ),
                ),
              ],
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
                  setState(() => override = v == 1 ? DietType.veg : null);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  onSave(available, availableSecondary, override);
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
