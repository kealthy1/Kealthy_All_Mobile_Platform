// sub_view_page.dart (enhanced UI)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/subscription/sub_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

import 'package:intl/intl.dart'; // at top if not already

enum SubscriptionStatus { active, future, inactive }

int statusRank(SubscriptionStatus s) {
  switch (s) {
    case SubscriptionStatus.active:
      return 0; // FIRST
    case SubscriptionStatus.future:
      return 1; // MIDDLE
    case SubscriptionStatus.inactive:
      return 2; // LAST
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _toDate(dynamic raw) {
  try {
    if (raw == null) return null;
    if (raw is DateTime) return _dateOnly(raw);
    if (raw is int) return _dateOnly(DateTime.fromMillisecondsSinceEpoch(raw));
    if (raw is double)
      return _dateOnly(DateTime.fromMillisecondsSinceEpoch(raw.toInt()));
    // Firestore Timestamp
    try {
      if (raw is dynamic && raw.seconds is int) {
        return _dateOnly(
            DateTime.fromMillisecondsSinceEpoch(raw.seconds * 1000));
      }
    } catch (_) {}
    if (raw is String && raw.isNotEmpty) {
      // Try “dd MMMM yyyy” e.g., “24 September 2025”
      try {
        return _dateOnly(DateFormat('dd MMMM yyyy', 'en_US').parse(raw));
      } catch (_) {
        return _dateOnly(DateTime.parse(raw));
      }
    }
  } catch (_) {}
  return null;
}

SubscriptionStatus statusOfDates(DateTime? start, DateTime? end) {
  final today = _dateOnly(DateTime.now());
  final startsInFuture = start != null && start.isAfter(today);
  final ended = end != null && end.isBefore(today);
  if (startsInFuture) return SubscriptionStatus.future;
  if (ended) return SubscriptionStatus.inactive;
  return SubscriptionStatus.active;
}

// Build an indexed, enriched list (keeps original index for total stability)

String _shortDate(DateTime d) => DateFormat("d MMM").format(d); // e.g., 5 Oct
DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const kBlue = Color.fromARGB(255, 4, 131, 199); // primary blue
const kBlueDark = Color(0xFF0369A1); // darker blue for emphasis
const kBlueSurface = Color(0xFFF0F9FF); // soft blue background
const kBlueSurface2 = Color.fromARGB(255, 241, 247, 250);
const kSlate = Color(0xFF334155); // dark grey-blue for text/icons

// --- DATA (unchanged) --------------------------------------------------------
final subscriptionOrderProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');
  if (phoneNumber == null) return [];

  final dbRef = FirebaseDatabase.instanceFor(
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
    app: Firebase.app(),
  ).ref("subscriptions");
  final snapshot =
      await dbRef.orderByChild("phoneNumber").equalTo(phoneNumber).get();

  if (snapshot.exists) {
    return snapshot.children
        .map((doc) => Map<String, dynamic>.from(doc.value as Map))
        .toList();
  }
  return [];
});
const _milkBg = kBlueSurface; // page background (milky white)
const _milkBlue = kBlue; // primary dairy blue
const _milkBlueLight = kBlueSurface2;
const _cream = kBlueSurface; // subtle cream accent
const _goodGreen = kBlue;
const _danger = Color(0xFFEF4444);

class SubscriptionOrderDetailsPage extends ConsumerWidget {
  const SubscriptionOrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(subscriptionOrderProvider);

    return Scaffold(
      backgroundColor: _milkBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _milkBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_drink_rounded, color: _milkBlue),
            ),
            const SizedBox(width: 10),
            Text('Milk Subscriptions',
                style: GoogleFonts.poppins(
                  color: kSlate,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.blue.shade600),
        ),
      ),
      floatingActionButton: FadeInUp(
        child: FloatingActionButton(
          tooltip: 'Add New Subscription',
          backgroundColor: Colors.blue.shade600,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SubscriptionDetailsPage()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontSize: 14,
            ),
          ),
        ),
        data: (orders) {
          final enriched = <({
            Map<String, dynamic> m,
            SubscriptionStatus st,
            DateTime? start,
            DateTime? end,
            int idx,
          })>[];
          for (var i = 0; i < orders.length; i++) {
            final m = orders[i];
            final start = _toDate(m['startDate']);
            final end = _toDate(m['endDate']);
            final st = statusOfDates(start, end);
            enriched.add((m: m, st: st, start: start, end: end, idx: i));
          }

          enriched.sort((a, b) {
            final rankCmp = statusRank(a.st).compareTo(statusRank(b.st));
            if (rankCmp != 0) return rankCmp;

            // Within same group:
            switch (a.st) {
              case SubscriptionStatus.active:
                // Active: earlier end first (soon-to-expire higher)
                if (a.end != null && b.end != null) {
                  final c = a.end!.compareTo(b.end!);
                  if (c != 0) return c;
                } else if (a.end != null)
                  return -1;
                else if (b.end != null) return 1;
                break;

              case SubscriptionStatus.future:
                // Future: earlier start first
                if (a.start != null && b.start != null) {
                  final c = a.start!.compareTo(b.start!);
                  if (c != 0) return c;
                } else if (a.start != null)
                  return -1;
                else if (b.start != null) return 1;
                break;

              case SubscriptionStatus.inactive:
                // Inactive: most recently ended first (later end first)
                if (a.end != null && b.end != null) {
                  final c = b.end!.compareTo(a.end!);
                  if (c != 0) return c;
                } else if (a.end != null)
                  return -1;
                else if (b.end != null) return 1;
                break;
            }

            // Final deterministic fallback (stable): original index
            return a.idx.compareTo(b.idx);
          });

          final sorted = enriched.map((e) => e.m).toList();
          print('Sorted subscriptions2: $sorted');
          if (sorted.isEmpty) {
            return FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _EmptyState(
                title: 'No Subscriptions Found',
                subtitle:
                    'Tap + below to start a new health-focused subscription.',
              ),
            );
          }
          return RefreshIndicator(
            color: Colors.blue.shade600,
            backgroundColor: const Color(0xFFf8f5f0),
            onRefresh: () async => ref.refresh(subscriptionOrderProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) => FadeInUp(
                duration: Duration(milliseconds: 600 + (i * 100)),
                child: _SubscriptionTile(data: sorted[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionTile extends StatefulWidget {
  final Map<String, dynamic> data;
  const _SubscriptionTile({required this.data});

  @override
  State<_SubscriptionTile> createState() => _SubscriptionTileState();
}

class _SubscriptionTileState extends State<_SubscriptionTile> {
  bool _expanded = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isServiceDay(DateTime d) => d.weekday != DateTime.sunday;

  List<DateTime> _nextUpcoming({
    required DateTime from,
    required DateTime start,
    required DateTime end,
    required bool alternate,
    int count = 3,
  }) {
    final startOnly = _dateOnly(start);
    final endOnly = _dateOnly(end);
    DateTime cursor =
        _dateOnly(from).isBefore(startOnly) ? startOnly : _dateOnly(from);
    final out = <DateTime>[];

    while (out.length < count && !cursor.isAfter(endOnly)) {
      final okBase = _isServiceDay(cursor);
      final okAlt = !alternate ||
          ((_dateOnly(cursor).difference(startOnly).inDays % 2) == 0);
      if (okBase && okAlt) out.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  // Robust date parsing for Firestore
  DateTime? _toDate(dynamic raw) {
    try {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.isNotEmpty) {
        // Try parsing "DD MMMM YYYY" format (e.g., "28 September 2025")
        try {
          final formatter = DateFormat('dd MMMM yyyy');
          return formatter.parse(raw);
        } catch (_) {
          // Fallback to ISO 8601 or other formats
          return DateTime.parse(raw);
        }
      }
      return null;
    } catch (e) {
      print('Error parsing date: $raw, error: $e');
      return null;
    }
  }

  String _shortDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayOnly = _dateOnly(now);

    late final String statusText;
    late final IconData statusIcon;
    late final Color statusColor;
    final data = widget.data;
    final bool isAlternate = (data['alternateDay'] == true);
    final String frequencyLabel = isAlternate ? 'Alternate Day' : 'Daily';

    final planTitle = (data['planTitle'] ?? '').toString();
    final product = (data['productName'] ?? 'Milk').toString();
    final qty = (data['subscriptionQty'] ?? '').toString();
    final slot = (data['selectedSlot'] ?? '').toString();
    final start = (data['startDate'] ?? '').toString();
    final end = (data['endDate'] ?? '').toString();
    final orderId = (data['orderId'] ?? '').toString();
    final amount = (data['totalAmountToPay'] ?? '').toString();

    final milkType = (data['milkType'] ?? '').toString();
    final fat = (data['fatPercent'] ?? '').toString();
    final da = (data['DA'] ?? '').toString();
    final daMobile = (data['DAMOBILE'] ?? '').toString();
    final assignedTo = (data['assignedto'] ?? '').toString();
    final createdAt = (data['createdAt'] ?? '').toString();
    final distance = (data['distance'] ?? '').toString();
    final deliveryFee = (data['deliveryFee'] ?? '').toString();
    final payment = (data['paymentmethod'] ?? '').toString();
    final phone = (data['phoneNumber'] ?? '').toString();
    final landmark = (data['landmark'] ?? '').toString();
    final directions = (data['selectedDirections'] ?? '').toString();
    final ean = (data['item_ean'] ?? '').toString();
    final fcm = (data['fcm_token'] ?? '').toString();

    final dynamic startRaw = data['startDate'];
    final dynamic endRaw = data['endDate'];

    final DateTime? startDate = _toDate(startRaw);
    final DateTime? endDate = _toDate(endRaw);

    // Default to today for startDate if null, far future for endDate if null
    final effectiveStartDate = startDate ?? now;
    final effectiveEndDate =
        endDate ?? DateTime.now().add(Duration(days: 365 * 10));

    // Status logic
    final bool startsInFuture =
        _dateOnly(effectiveStartDate).isAfter(todayOnly);
    final bool ended =
        endDate != null && _dateOnly(endDate).isBefore(todayOnly);
    final bool activeNow = !startsInFuture && !ended;

    print(
        'Raw startDate: $startRaw, Parsed: $startDate, Effective: $effectiveStartDate');
    print(
        'Raw endDate: $endRaw, Parsed: $endDate, Effective: $effectiveEndDate');
    print(
        'startsInFuture: $startsInFuture, ended: $ended, activeNow: $activeNow');

    // Set status text, icon, and color
    if (startsInFuture) {
      print('Status: Starts ${_shortDate(effectiveStartDate)}');
      statusText = 'Starts ${_shortDate(effectiveStartDate)}';
      statusIcon = Icons.schedule_rounded;
      statusColor = _milkBlue;
    } else if (activeNow) {
      print('Status: Active');
      statusText = 'Active';
      statusIcon = Icons.check_circle_rounded;
      statusColor = Colors.green;
    } else {
      print('Status: Inactive');
      statusText = 'Inactive';
      statusIcon = Icons.remove_circle_rounded;
      statusColor = kSlate.withOpacity(.6);
    }

    // Correct isActive to reflect active subscriptions
    final bool isActive = activeNow;

    String _mask(String s, {int keepStart = 6, int keepEnd = 4}) {
      if (s.isEmpty) return '';
      if (s.length <= keepStart + keepEnd) return '•••';
      return s.substring(0, keepStart) +
          '••••••' +
          s.substring(s.length - keepEnd);
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6)),
            ],
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(
                  color: _milkBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _milkBlue.withOpacity(.20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _milkBlueLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _milkBlue.withOpacity(.20)),
                      ),
                      child: const Icon(Icons.local_drink_rounded,
                          color: _milkBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planTitle.isEmpty ? 'Milk Subscription' : planTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: isActive ? 1.0 : 0.55,
                      child: _MilkBadge(
                        icon: statusIcon,
                        text: statusText,
                        color: statusColor,
                      ),
                    )
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const _DividerThin(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  if (milkType.isNotEmpty)
                    const _ChipPill(icon: Icons.pets_rounded, text: 'Type')
                        .withValue(milkType),
                  if (fat.isNotEmpty)
                    const _ChipPill(icon: Icons.percent_rounded, text: 'Fat')
                        .withValue('$fat%'),
                  if (slot.isNotEmpty)
                    const _ChipPill(icon: Icons.schedule_rounded, text: 'Slot')
                        .withValue(slot),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ChipPill(
                          icon: Icons.repeat_rounded, text: frequencyLabel),
                      _MilkBadge(
                        icon: Icons.local_fire_department_rounded,
                        text: '${qty.isEmpty ? '--' : qty} L/day',
                        color: _goodGreen,
                      ),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              _InfoRow(label: 'Order ID', value: orderId, copyable: true),
              _InfoRow(label: 'Start', value: start),
              const SizedBox(height: 15),
              _InfoRow(label: 'End', value: end),
              const SizedBox(height: 10),
              Row(children: [
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(_expanded ? 'Less' : 'More'),
                  style: TextButton.styleFrom(
                    foregroundColor: kSlate.withOpacity(.75),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: _cream.withOpacity(.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlueSurface2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.currency_rupee_rounded,
                        size: 18, color: kBlueDark),
                    const SizedBox(width: 6),
                    Text('Total',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: kBlue,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('₹$amount',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                  ]),
                ),
              ]),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const _DividerThin(),
                    const SizedBox(height: 10),
                    Text('More Details',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    if (isAlternate) ...[
                      const SizedBox(height: 6),
                      Builder(builder: (_) {
                        final startDt = effectiveStartDate;
                        final endDt = effectiveEndDate;
                        final upcoming = _nextUpcoming(
                          from: DateTime.now(),
                          start: startDt,
                          end: endDt,
                          alternate: isAlternate,
                          count: 3,
                        );

                        String fmt(DateTime d) =>
                            '${d.day}/${d.month}/${d.year}';
                        final label = upcoming.isEmpty
                            ? 'No upcoming deliveries'
                            : upcoming.map(fmt).join(', ');

                        return _InfoRow(label: 'Upcoming', value: label);
                      }),
                    ],
                    const SizedBox(height: 15),
                    _InfoRow(label: 'Payment', value: payment),
                    _InfoRow(label: 'Phone', value: phone, copyable: true),
                    _InfoRow(label: 'Landmark', value: landmark),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Directions', value: directions),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Distance (km)', value: distance),
                    const SizedBox(height: 10),
                    _InfoRow(
                        label: 'Delivery Fee', value: deliveryFee.toString()),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Delivery By', value: da),
                    const SizedBox(height: 10),
                    _InfoRow(
                        label: 'DA Mobile', value: daMobile, copyable: true),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Assigned To', value: assignedTo),
                  ],
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeOutCubic,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MilkBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MilkBadge(
      {required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.poppins(
                color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _DividerThin extends StatelessWidget {
  const _DividerThin();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: kBlue);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _InfoRow(
      {required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    final v = value.isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                maxLines: 2,
                style: GoogleFonts.poppins(
                    height: 0.5,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: kBlueDark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              Expanded(
                child: SelectableText(
                  v,
                  style: GoogleFonts.poppins(
                      height: 0.3, fontSize: 12.5, color: kBlueDark),
                  maxLines: 2,
                ),
              ),
              if (copyable && value.isNotEmpty)
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied')),
                    );
                  },
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

extension _ChipExt on Widget {
  Widget withValue(String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      this,
      const SizedBox(width: 6),
      Text(value,
          style: GoogleFonts.poppins(
            color: _milkBlue,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          )),
    ]);
  }
}

class _ChipPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ChipPill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _milkBlueLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _milkBlue.withOpacity(.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _milkBlue),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.poppins(
              color: _milkBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _milkBlueLight,
                shape: BoxShape.circle,
                border: Border.all(color: _milkBlue.withOpacity(.35)),
              ),
              child: const Icon(Icons.local_drink_rounded,
                  size: 48, color: _milkBlue),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: kBlueSurface2)),
          ],
        ),
      ),
    );
  }
}
