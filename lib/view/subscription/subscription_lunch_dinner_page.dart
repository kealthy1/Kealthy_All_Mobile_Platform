import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final addressProvider = Provider<Map<String, dynamic>>((ref) => {
      'userId': 'user123',
      'addressLine1': '123 Main St',
      'addressLine2': 'Apt 4B',
      'city': 'Mumbai',
      'state': 'Maharashtra',
      'zipCode': '400001',
    });

final userSubscriptionsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final fs = ref.watch(firestoreProvider);
  final userId = ref.watch(addressProvider)['userId'] as String?;

  // If no user yet, emit an empty list (still a Stream).
  if (userId == null || userId.isEmpty) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final query =
      fs.collection('meal_subscriptions').where('userId', isEqualTo: userId);
  // Optional (uncomment if you have this field):
  // .orderBy('createdAt', descending: true);

  return query.snapshots().map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      // Include doc ID for convenience.
      return {'id': doc.id, ...data};
    }).toList();
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
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
        child: subscriptionsAsync.when(
          data: (subscriptions) {
            final filteredSubscriptions = subscriptions
                .where((sub) => sub['mealType'] == mealType.name)
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

  Future<void> _toggleAvailability(BuildContext context, WidgetRef ref,
      Map<String, dynamic> subscription, bool available) async {
    final fs = ref.read(firestoreProvider);
    final subRef = fs.collection('meal_subscriptions').doc(subscription['id']);
    final today = DateTime.now();
    final todayStripped = DateTime(today.year, today.month, today.day);
    final skipDates =
        List<String>.from(subscription['skipDates'] as List<dynamic>? ?? []);
    final startDate = DateTime.parse(subscription['startDate'] as String);
    final planDays = subscription['planDays'] as int;
    final deliveryHour = mealType == MealType.lunch ? 12 : 18;

    // Early exit if today is not a valid delivery day
    if (todayStripped.weekday == DateTime.sunday ||
        startDate.isAfter(todayStripped)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today is not a valid delivery day!')),
      );
      return;
    }

    // Update skipDates based on availability
    final todayIso = todayStripped.toIso8601String();
    final isTodaySkipped = skipDates.contains(todayIso);
    if (available && isTodaySkipped) {
      skipDates.remove(todayIso);
    } else if (!available && !isTodaySkipped) {
      skipDates.add(todayIso);
    } else {
      return; // No change needed
    }

    // Adjust planDays: increase if skipping, decrease if making available
    final newPlanDays = available ? planDays - 1 : planDays + 1;

    // Ensure planDays doesn't go below 1
    if (newPlanDays < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot reduce plan days below 1!')),
      );
      return;
    }

    // Recalculate deliveries, excluding skipped dates
    final dates = <DateTime>[];
    var cursor = startDate;
    while (dates.length < newPlanDays) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (day.weekday != DateTime.sunday &&
          !skipDates.contains(day.toIso8601String())) {
        dates.add(day);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    // Log the new last delivery date for clarity
    final newLastDeliveryDate = dates.isNotEmpty ? dates.last : startDate;
    print('Toggle availability: today=$todayStripped, available=$available, '
        'newPlanDays=$newPlanDays, newLastDeliveryDate=$newLastDeliveryDate');

    // Create deliveriesDetailed, preserving existing diet preferences
    final deliveriesDetailed = dates
        .map((d) => {
              'date': DateTime(d.year, d.month, d.day, deliveryHour)
                  .toIso8601String(),
              'diet':
                  (subscription['deliveriesDetailed'] as List<dynamic>? ?? [])
                      .firstWhere(
                (entry) => DateTime.parse(entry['date']).isAtSameMomentAs(
                    DateTime(d.year, d.month, d.day, deliveryHour)),
                orElse: () => {'diet': 'nonVeg'},
              )['diet'] as String,
            })
        .where((entry) => !skipDates.contains(
            DateTime.parse(entry['date'] as String)
                .toIso8601String()
                .substring(0, 10))) // Exclude skipped dates
        .toList();

    final deliveriesIso =
        deliveriesDetailed.map((entry) => entry['date'] as String).toList();

    // Update subscription in Firestore
    final payload = {
      'skipDates': skipDates,
      'planDays': newPlanDays,
      'deliveries': deliveriesIso,
      'deliveriesDetailed': deliveriesDetailed,
    };

    await subRef.update(payload);

    // Update kitchen buckets and routes
    final batch = fs.batch();
    // Clear existing buckets and routes for this subscription
    final existingDeliveries =
        List<String>.from(subscription['deliveries'] as List<dynamic>? ?? []);
    for (final delivery in existingDeliveries) {
      final dt = DateTime.parse(delivery);
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final dietStr =
          (subscription['deliveriesDetailed'] as List<dynamic>? ?? [])
              .firstWhere(
        (entry) => DateTime.parse(entry['date']).isAtSameMomentAs(dt),
        orElse: () => {'diet': 'nonVeg'},
      )['diet'] as String;
      final bucketId = '${mealType.name}-$dietStr';

      final bucketRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('buckets')
          .doc(bucketId);
      final routeRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('routes')
          .doc(subscription['id']);

      batch.set(
        bucketRef,
        {
          'count': FieldValue.increment(-1),
          'allergiesRollup': FieldValue.arrayRemove(
              subscription['allergies'] as List<dynamic>? ?? []),
        },
        SetOptions(merge: true),
      );
      batch.delete(routeRef);
    }

    // Add new buckets and routes
    for (final entry in deliveriesDetailed) {
      final dt = DateTime.parse(entry['date'] as String);
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final dietStr = entry['diet'] as String;
      final bucketId = '${mealType.name}-$dietStr';

      final bucketRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('buckets')
          .doc(bucketId);

      batch.set(
        bucketRef,
        {
          'date': dayKey,
          'mealType': mealType.name,
          'diet': dietStr,
          'count': FieldValue.increment(1),
          'allergiesRollup': FieldValue.arrayUnion(
              subscription['allergies'] as List<dynamic>? ?? []),
        },
        SetOptions(merge: true),
      );

      final routeRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('routes')
          .doc(subscription['id']);

      batch.set(
        routeRef,
        {
          'subscriptionId': subscription['id'],
          'mealType': mealType.name,
          'diet': dietStr,
          'deliveryAt': dt.toIso8601String(),
          'allergies': subscription['allergies'] as List<dynamic>? ?? [],
          'address': subscription['address'],
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    // Show confirmation with new last delivery date
    final formattedNewDate = DateFormat('d/M/y').format(newLastDeliveryDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          available
              ? 'Today added to subscription, ends on $formattedNewDate'
              : 'Today skipped, subscription extended to $formattedNewDate',
        ),
      ),
    );

    ref.refresh(userSubscriptionsProvider); // Refresh subscriptions
  }
}

Color _mealColor(MealType t, BuildContext ctx) {
  final p = Theme.of(ctx).colorScheme.primary;
  switch (t) {
    case MealType.lunch:
      return Colors.teal.shade700;
    case MealType.dinner:
      return Colors.indigo.shade600;
  }
}

IconData _mealIcon(MealType t) {
  switch (t) {
    case MealType.lunch:
      return Icons.restaurant_menu_rounded;
    case MealType.dinner:
      return Icons.nightlight_round_rounded;
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const _Pill(this.text, {this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}

class SubscriptionCard extends ConsumerWidget {
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

  DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);

  Set<DateTime> _skipSet(List<String> isoList) => {
        for (final s in isoList)
          () {
            final dt = DateTime.parse(s);
            return DateTime(dt.year, dt.month, dt.day);
          }(),
      };

  List<DateTime> _buildSchedule({
    required DateTime start,
    required int planDays,
    required Set<DateTime> skipDates,
  }) {
    final out = <DateTime>[];
    var cursor = _d(start);
    while (out.length < planDays) {
      final day = _d(cursor);
      final isSunday = day.weekday == DateTime.sunday;
      final isSkipped = skipDates.contains(day);
      if (!isSunday && !isSkipped) out.add(day);
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = DateTime.parse(subscription['deliveries'][0] as String);
    final planDays = subscription['planDays'] as int;
    final mealTypeStr = subscription['mealType'] as String;

    final today = _d(DateTime.now());
    final todayIso = today.toIso8601String();

    final skipRaw =
        List<String>.from(subscription['skipDates'] as List<dynamic>? ?? []);
    final skipSet = _skipSet(skipRaw);

    final schedule = planDays > 0
        ? _buildSchedule(
            start: startDate, planDays: planDays, skipDates: skipSet)
        : <DateTime>[];

    final endDate = schedule.isNotEmpty ? schedule.last : _d(startDate);
    final nextDelivery = schedule.firstWhere(
      (d) => !d.isBefore(today),
      orElse: () => DateTime(0),
    );
    final hasNext = nextDelivery.year > 1;
    final remaining = schedule.where((d) => !d.isBefore(today)).length;

    final hasAllergies =
        ((subscription['allergies'] as List<dynamic>?)?.isNotEmpty ?? false);
    final hasSkips = skipRaw.isNotEmpty;

    final isTodayValid =
        startDate.isBefore(today.add(const Duration(days: 1))) &&
            today.weekday != DateTime.sunday;
    final isTodayAvailable = !skipRaw.contains(todayIso);

    final mealC = _mealColor(mealType, context);

    String dt(DateTime d) => DateFormat('d/M/y').format(d);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mealC.withOpacity(.10), mealC.withOpacity(.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: mealC.withAlpha(15),
                  foregroundColor: mealC,
                  child: Icon(_mealIcon(mealType)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mealTypeStr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 7,
                        children: [
                          _Pill('Period: ${dt(startDate)}  to  ${dt(endDate)}',
                              icon: Icons.calendar_month_rounded, color: mealC),
                          _Pill('$planDays days',
                              icon: Icons.event_note_rounded, color: mealC),
                          if (hasNext)
                            _Pill('Next: ${dt(nextDelivery)}',
                                icon: Icons.schedule_rounded, color: mealC),
                          if (hasNext)
                            _Pill('$remaining left',
                                icon: Icons.timelapse_rounded, color: mealC),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit subscription',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasAllergies) ...[
                  const _SectionTitle(
                      Icons.health_and_safety_rounded, 'Allergies'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (subscription['allergies'] as List<dynamic>)
                        .cast<String>()
                        .map((a) => _Pill(a, icon: Icons.tag_faces_rounded))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (hasSkips) ...[
                  const _SectionTitle(Icons.event_busy_rounded, 'Skip Dates'),
                  const SizedBox(height: 8),
                  Text(
                    skipRaw.map((s) => dt(DateTime.parse(s))).join(', '),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isTodayValid)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.black.withOpacity(.03),
                      border: Border.all(
                        color: (isTodayAvailable ? mealC : Colors.redAccent)
                            .withOpacity(.35),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      title: const Text("I'm available today"),
                      subtitle: Text(
                        isTodayAvailable
                            ? 'You will receive today’s meal.'
                            : 'You will skip today’s meal.',
                      ),
                      activeColor: mealC,
                      value: isTodayAvailable,
                      onChanged: (value) => onToggleAvailability(value),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
  late Set<String> allergies;
  late Set<DateTime> skipDates;
  late DateTime startDate;
  late int planDays;
  late Map<DateTime, DietType?> dietOverrides;

  DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);
  List<DateTime> _schedule(DateTime start, int days, Set<DateTime> skip) {
    final out = <DateTime>[];
    var cur = _d(start);
    while (out.length < days) {
      final day = _d(cur);
      if (day.weekday != DateTime.sunday && !skip.contains(day)) out.add(day);
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }

  DateTime get _endDate =>
      planDays > 0 ? _schedule(startDate, planDays, skipDates).last : startDate;

  @override
  void initState() {
    super.initState();
    allergies = Set<String>.from(
        widget.subscription['allergies'] as List<dynamic>? ?? []);
    skipDates = (widget.subscription['skipDates'] as List<dynamic>?)?.map((d) {
          final dt = DateTime.parse(d as String);
          return DateTime(dt.year, dt.month, dt.day);
        }).toSet() ??
        {};
    startDate = DateTime.parse(widget.subscription['startDate'] as String);
    planDays = widget.subscription['planDays'] as int;
    dietOverrides = (widget.subscription['deliveriesDetailed']
                as List<dynamic>?)
            ?.asMap()
            .map((_, entry) {
          final date = DateTime.parse(entry['date'] as String);
          final diet = entry['diet'] == 'veg' ? DietType.veg : DietType.nonVeg;
          return MapEntry(DateTime(date.year, date.month, date.day), diet);
        }) ??
        {};
  }

  @override
  Widget build(BuildContext context) {
    final ingrAsync =
        ref.watch(ingredientsProvider(widget.mealType as MealType));
    final mealC = _mealColor(widget.mealType, context);
    String dt(DateTime d) => DateFormat('d/M/y').format(d);

    final hasAllergies = allergies.isNotEmpty;
    final endDate = _endDate;
    final allDays = <DateTime>[];
    var cursor = startDate;
    while (!cursor.isAfter(endDate)) {
      allDays.add(DateTime(cursor.year, cursor.month, cursor.day));
      cursor = cursor.add(const Duration(days: 1));
    }
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mealC.withAlpha(14), mealC.withAlpha(02)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: mealC.withOpacity(.15),
              foregroundColor: mealC,
              child: Icon(_mealIcon(widget.mealType)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Edit ${StringExtension(widget.mealType.name).capitalize()} Subscription',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(Icons.event_note_rounded, 'Plan Duration'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {planDays},
              onSelectionChanged: (s) => setState(() => planDays = s.first),
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.teal; // Selected text color
                  }
                  return Colors.black87; // Default text color
                }),
                backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.teal.withOpacity(0.15); // Selected background
                  }
                  return Colors.white; // Default background
                }),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(Icons.calendar_today_rounded, 'Start Date'),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black.withOpacity(.03),
              title: Text(dt(startDate)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
                );
                if (picked != null) setState(() => startDate = picked);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Ends on: ${dt(_endDate)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
                Icons.tune_rounded, 'Skip Dates & Diet Overrides'),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Available date', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Skipped date', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Veg', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 15),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Non-Veg', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: allDays.map((day) {
                final isSkipped = skipDates.contains(day);
                final isSun = day.weekday == DateTime.sunday;
                final overrideDiet = dietOverrides[day];
                final isVeg = overrideDiet == DietType.veg;
                final dotColor = isVeg ? Colors.green : Colors.red;
                final bg = isSun
                    ? Colors.grey.withOpacity(.18)
                    : isSkipped
                        ? Colors.red.withOpacity(.18)
                        : Colors.green.withOpacity(.18);
                final br = isSkipped
                    ? Colors.redAccent
                    : isSun
                        ? Colors.grey
                        : Colors.transparent;

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _DayEditSheet(
                        day: day,
                        isAvailable: !isSkipped,
                        isAvailableSecondary: false,
                        currentOverride: dietOverrides[day],
                        isTwoMeals: false,
                        primaryMealType: widget.mealType,
                        isPrimaryMeal: true,
                        onSave: (available, _, override) {
                          setState(() {
                            available
                                ? skipDates.remove(day)
                                : skipDates.add(day);
                            override == null
                                ? dietOverrides.remove(day)
                                : dietOverrides[day] = override;
                          });
                        },
                      ),
                    ).then((_) => setState(() {}));
                  },
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
                                isSkipped ? FontWeight.w800 : FontWeight.w600,
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
                            color: overrideDiet != null
                                ? dotColor
                                : Colors.transparent,
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
    final fs = ref.read(firestoreProvider);
    final subRef =
        fs.collection('meal_subscriptions').doc(widget.subscription['id']);
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

    final payload = {
      'diet': 'nonVeg',
      'allergies': allergies.toList(),
      'startDate': startDate.toIso8601String(),
      'skipDates': skipDates.map((d) => d.toIso8601String()).toList(),
      'planDays': planDays,
      'deliveries': deliveriesIso,
      'deliveriesDetailed': deliveriesDetailed,
    };

    await subRef.update(payload);

    final batch = fs.batch();
    final existingDeliveries = List<String>.from(
        widget.subscription['deliveries'] as List<dynamic>? ?? []);
    for (final delivery in existingDeliveries) {
      final dt = DateTime.parse(delivery);
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final dietStr =
          (widget.subscription['deliveriesDetailed'] as List<dynamic>)
              .firstWhere(
        (entry) => DateTime.parse(entry['date']).isAtSameMomentAs(dt),
        orElse: () => {'diet': 'nonVeg'},
      )['diet'] as String;
      final bucketId = '${widget.mealType.name}-$dietStr';

      final bucketRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('buckets')
          .doc(bucketId);
      final routeRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('routes')
          .doc(widget.subscription['id']);

      batch.set(
        bucketRef,
        {
          'count': FieldValue.increment(-1),
          'allergiesRollup': FieldValue.arrayRemove(allergies.toList()),
        },
        SetOptions(merge: true),
      );
      batch.delete(routeRef);
    }

    for (final entry in deliveriesDetailed) {
      final dt = DateTime.parse(entry['date'] as String);
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final dietStr = entry['diet'] as String;
      final bucketId = '${widget.mealType.name}-$dietStr';

      final bucketRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('buckets')
          .doc(bucketId);

      batch.set(
        bucketRef,
        {
          'date': dayKey,
          'mealType': widget.mealType.name,
          'diet': dietStr,
          'count': FieldValue.increment(1),
          'allergiesRollup': FieldValue.arrayUnion(allergies.toList()),
        },
        SetOptions(merge: true),
      );

      final routeRef = fs
          .collection('kitchens')
          .doc(dayKey)
          .collection('routes')
          .doc(widget.subscription['id']);

      batch.set(
        routeRef,
        {
          'subscriptionId': widget.subscription['id'],
          'mealType': widget.mealType.name,
          'diet': dietStr,
          'deliveryAt': dt.toIso8601String(),
          'allergies': allergies.toList(),
          'address': widget.subscription['address'],
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    ref.refresh(userSubscriptionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription updated!')),
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
                  title: Text(
                      "I'm available for ${StringExtension(primaryMealType.name).capitalize()}"),
                  value: available,
                  onChanged: day.weekday == DateTime.sunday
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
