import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final solvedTicketsProvider = StreamProvider.autoDispose((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber') ?? '';

  yield* FirebaseFirestore.instance
      .collection('Help')
      .where('status', isEqualTo: 'solved')
      .where('phoneNumber', isEqualTo: phoneNumber)
      .snapshots();
});

class SolvedTicketsPage extends ConsumerWidget {
  const SolvedTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsyncValue = ref.watch(solvedTicketsProvider);

    return ticketsAsyncValue.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const Center(
            child: Text(
              "No solved tickets found",
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
                    color: const Color.fromARGB(255, 65, 88, 108),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(dateTime ?? DateTime.now()),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                      Text(
                        DateFormat('MMM').format(dateTime ?? DateTime.now()),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
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
                          fontWeight: FontWeight.bold, fontFamily: "Poppins"),
                    ),
                    const Text(
                      "Solved",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins"),
                    ),
                  ],
                ),
                subtitle: Text(
                  data['subCategory'] ?? "No Description",
                  style: const TextStyle(fontFamily: "Poppins"),
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
        child: Text(
          "Error: $error",
          style: const TextStyle(fontFamily: "Poppins", color: Colors.red),
        ),
      ),
    );
  }
}
