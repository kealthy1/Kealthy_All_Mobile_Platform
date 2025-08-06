import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

final selectedSlotProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
final isExpandedProvider = StateProvider<bool>((ref) => true);

class SlotSelectionContainer extends ConsumerWidget {
  const SlotSelectionContainer({super.key});

  Future<List<dynamic>> fetchSlotsFromBackend() async {
    final response = await http.get(
      Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/slots'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      debugPrint('🟢 Backend Response: $decoded');

      if (decoded is Map && decoded.containsKey('slots')) {
        final slotsData = decoded['slots'];
        if (slotsData is Map && slotsData.containsKey('slots')) {
          return slotsData['slots'] as List<dynamic>;
        } else if (slotsData is List) {
          return slotsData;
        } else {
          throw Exception("Invalid nested slot structure: $slotsData");
        }
      } else {
        throw Exception("Invalid response format: ${response.body}");
      }
    } else {
      debugPrint('❌ Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to fetch slots');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSlot = ref.watch(selectedSlotProvider);
    final isExpanded = ref.watch(isExpandedProvider);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(isExpandedProvider.notifier).state = !isExpanded,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedSlot != null
                              ? 'Selected Slot : ${DateFormat('MMM d').format(selectedSlot["start"])}, ${DateFormat('h:mm a').format(selectedSlot["start"])} - ${DateFormat('h:mm a').format(selectedSlot["end"])}'
                              : 'Preferred Delivery Time',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(isExpanded
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            FutureBuilder<List<dynamic>>(
              future: fetchSlotsFromBackend(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CupertinoActivityIndicator(color: Colors.black));
                }

                if (snapshot.hasError) {
                  debugPrint("❌ Slot fetch error: ${snapshot.error}");
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("Failed to load slots"),
                  );
                }

                final availableSlots =
                    (snapshot.data ?? []).map<Map<String, dynamic>>((slot) {
                  return {
                    "start": slot["start"] is String
                        ? DateTime.parse(slot["start"]).toLocal()
                        : slot["start"],
                    "end": slot["end"] is String
                        ? DateTime.parse(slot["end"]).toLocal()
                        : slot["end"],
                    "label": slot["label"],
                  };
                }).toList();

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final tomorrow = today.add(const Duration(days: 1));

                final todaySlots = availableSlots.where((slot) {
                  final start = slot["start"] as DateTime;
                  final end = slot["end"] as DateTime;

                  return start.year == today.year &&
                      start.month == today.month &&
                      start.day == today.day &&
                      end.isAfter(now); // Only show if it hasn't ended
                }).toList();

                final tomorrowSlots = availableSlots.where((slot) {
                  final date = slot["start"];
                  return date.year == tomorrow.year &&
                      date.month == tomorrow.month &&
                      date.day == tomorrow.day;
                }).toList();

                Widget buildSlotButtons(List<Map<String, dynamic>> slots) {
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 10,
                      children: slots.map((slot) {
                        final formattedStartTime = DateFormat('h:mm a')
                            .format(slot["start"] as DateTime);
                        final formattedEndTime =
                            DateFormat('h:mm a').format(slot["end"]);

                        return GestureDetector(
                          onTap: () async {
                            final selectedSlotStartIso =
                                (slot["start"] as DateTime)
                                    .toUtc()
                                    .toIso8601String();

                            final slotLabel =
                                "${DateFormat('MMM d, hh:mm a').format(slot["start"])} - ${DateFormat('hh:mm a').format(slot["end"])}";
                            final isAvailable =
                                await isSlotAvailable(slotLabel);
                            if (!isAvailable) {
                              ToastHelper.showErrorToast(
                                  'Slot is fully booked. Please choose another slot');
                              return;
                            }

                            ref.read(selectedSlotProvider.notifier).state =
                                slot;
                            ref.read(isExpandedProvider.notifier).state = false;

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                                'selectedSlotStart', selectedSlotStartIso);
                            await prefs.setString('selectedSlot', slotLabel);
                          },
                          child: IntrinsicWidth(
                            stepWidth: 10,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.37,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 10),
                              decoration: BoxDecoration(
                                color: (selectedSlot != null &&
                                        selectedSlot["start"] ==
                                            slot["start"] &&
                                        selectedSlot["end"] == slot["end"])
                                    ? const Color.fromARGB(255, 223, 240, 224)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Center(
                                child: Text(
                                  '$formattedStartTime - $formattedEndTime',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (todaySlots.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Today’s Slots - ${DateFormat('MMM d, yyyy').format(today)}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 0, 124, 4),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "No slots for today. Book for tomorrow!",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    if (todaySlots.isNotEmpty) buildSlotButtons(todaySlots),
                    if (tomorrowSlots.isNotEmpty) const SizedBox(height: 10),
                    if (tomorrowSlots.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Tomorrow’s Slots - ${DateFormat('MMM d, yyyy').format(tomorrow)}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 0, 124, 4),
                          ),
                        ),
                      ),
                    if (tomorrowSlots.isNotEmpty)
                      buildSlotButtons(tomorrowSlots),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

Future<bool> isSlotAvailable(String selectedSlotLabel) async {
  final databaseRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref().child('orders');

  // ✅ Get the number of existing orders for the selected slot
  final snapshot = await databaseRef
      .orderByChild('selectedSlot')
      .equalTo(selectedSlotLabel)
      .get();

  final existingOrders = snapshot.children.length;

  final configDoc = await FirebaseFirestore.instance
      .collection('slot')
      .doc('slotLimits')
      .get();

  final maxOrdersPerSlot = configDoc.data()?['limit'] ?? 1;

  debugPrint(
      'Orders for $selectedSlotLabel: $existingOrders / $maxOrdersPerSlot');

  return existingOrders < maxOrdersPerSlot;
}
