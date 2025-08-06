import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/support/chat.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Provider for recent tickets
final recentTicketsProvider = StreamProvider.autoDispose((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber') ?? '';

  yield* FirebaseFirestore.instance
      .collection('Help')
      .where('status', isEqualTo: 'notsolved')
      .where('phoneNumber', isEqualTo: phoneNumber)
      .snapshots();
});

class OngoingTicketsPage extends ConsumerWidget {
  const OngoingTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsyncValue = ref.watch(recentTicketsProvider);

    return ticketsAsyncValue.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const Center(
            child: Text(
              "No active tickets found.",
              style: TextStyle(fontFamily: "poppins"),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.docs[index];
            final data = doc.data();

            final timestamp = data['timestamp'] as Timestamp?;
            final dateTime = timestamp?.toDate();

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    boxShadow: const [],
                    color: const Color.fromARGB(255, 65, 88, 108),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(dateTime ?? DateTime.now()),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        DateFormat('MMM').format(dateTime ?? DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ticket ID ${data['ticketId'] ?? 'No ID'}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: "poppins"),
                    ),
                    const Text(
                      "Active",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontFamily: "poppins"),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['description'] ?? "No Description",
                      style: const TextStyle(fontFamily: "poppins"),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => TicketChatPage(
                                      ticketId: data['ticketId'],
                                    )));
                      },
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_text,
                            size: 25,
                            color: Color(0xFF273847),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Chat with Support",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontFamily: "poppins",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CupertinoActivityIndicator(
        color: Color(0xFF273847),
      )),
      error: (error, stack) => Center(
        child: Text("Error: $error"),
      ),
    );
  }
}

class AlertLog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;

  const AlertLog({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: Colors.green[400],
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: "poppins",
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: "poppins",
          fontSize: 12,
        ),
      ),
      actions: actions.isNotEmpty
          ? actions
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
    );
  }
}

void showAlertLog({
  required BuildContext context,
  required String title,
  required String message,
  List<Widget>? actions,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertLog(
      title: title,
      message: message,
      actions: actions ?? [],
    ),
  );
}
