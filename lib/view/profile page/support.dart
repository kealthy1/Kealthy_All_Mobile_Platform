import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/support/live_ticket.dart';
import 'package:kealthy/view/support/solved_tickets.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Providers for Riverpod
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedSubCategoryProvider = StateProvider<String?>((ref) => null);
final descriptionProvider = StateProvider<String?>((ref) => null);

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          foregroundColor: const Color(0xFF273847),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: true,
          title: Text(
            "Kealthy Support",
            style: GoogleFonts.poppins(
              color: const Color(0xFF273847),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => showOpenTicketBottomSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF273847),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(
                          "Open a Ticket",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            style: ElevatedButton.styleFrom(),
                            onPressed: () {
                              showAlertLog(
                                context: context,
                                title: "Contact Support",
                                message:
                                    "Would you like to contact a support executive? Our team is here to assist you",
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "Dismiss",
                                          style: GoogleFonts.poppins(
                                              color: Colors.black),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF273847),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                        ),
                                        onPressed: () {
                                          FlutterPhoneDirectCaller.callNumber(
                                              "8848673425");
                                        },
                                        child: Text(
                                          "Call Now",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                            icon: const Icon(Icons.call,
                                color: Color(0xFF273847), size: 30),
                          ),
                          Text(
                            "Contact Support",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF273847),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const TabBar(
                    labelColor: Color(0xFF273847),
                    unselectedLabelColor: Color(0xFF273847),
                    indicatorColor: Color(0xFF273847),
                    tabs: [
                      Tab(text: "Active", icon: Icon(Icons.pending_actions)),
                      Tab(text: "Solved", icon: Icon(Icons.check_circle)),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  OngoingTicketsPage(),
                  SolvedTicketsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheet Functionality
void showOpenTicketBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const OpenTicketBottomSheet(),
    ),
  );
}

// Open Ticket Bottom Sheet
class OpenTicketBottomSheet extends ConsumerWidget {
  const OpenTicketBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubCategory = ref.watch(selectedSubCategoryProvider);
    final description = ref.watch(descriptionProvider);

    final Map<String, List<String>> subCategories = {
      "Past Orders": ["Missing Items", "Late Delivery", "Wrong Order"],
      "Payments": ["Failed Payment", "Refund Issue"],
      "Report Bug": ["App Crashing", "UI Issue", "Slow Performance"],
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Open a Ticket 💬",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF273847),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: subCategories.keys.map((String category) {
                return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ));
              }).toList(),
              onChanged: (value) {
                ref.read(selectedCategoryProvider.notifier).state = value;
                ref.read(selectedSubCategoryProvider.notifier).state = null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              hint: Text(
                "Select Category",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              value: selectedCategory,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: (subCategories[selectedCategory] ?? [])
                  .map((String subCategory) {
                return DropdownMenuItem(
                    value: subCategory,
                    child: Text(
                      subCategory,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                      ),
                    ));
              }).toList(),
              onChanged: (value) {
                ref.read(selectedSubCategoryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              hint: Text(
                "Select Sub-Category",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              value: selectedSubCategory,
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              maxLength: 200,
              onChanged: (value) =>
                  ref.read(descriptionProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: "Enter Ticket Description",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedCategory == null ||
                      selectedSubCategory == null ||
                      description == null ||
                      description.isEmpty) {
                    ToastHelper.showErrorToast('Please complete all fields.');
                    return;
                  }

                  await saveTicketToFirestore(
                    category: selectedCategory,
                    subCategory: selectedSubCategory,
                    description: description,
                  );

                  Navigator.pop(context); // Close the bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF273847),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "Raise Ticket",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Firestore Save Method
Future<void> saveTicketToFirestore({
  required String category,
  required String subCategory,
  required String description,
}) async {
  try {
    String ticketId = _generateUniqueTicketId();
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';

    await FirebaseFirestore.instance.collection('Help').add({
      'ticketId': ticketId,
      'messages': [], // Initialize the messages field as an empty array
      'phoneNumber': phoneNumber,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'notsolved',
    });

    ToastHelper.showSuccessToast(
        'Ticket submitted successfully! Ticket ID: $ticketId');
  } catch (e) {
    ToastHelper.showErrorToast('Failed to submit ticket: $e');
  }
}

String _generateUniqueTicketId() {
  Random random = Random();
  return (random.nextInt(900000) + 100000).toString(); // Generate 6-digit ID
}
