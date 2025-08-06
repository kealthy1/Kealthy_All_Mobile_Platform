import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

final messagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, ticketId) {
  return FirebaseFirestore.instance
      .collection('Help')
      .where('ticketId', isEqualTo: ticketId)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return [];
    final doc = snapshot.docs.first;
    final messages = doc['messages'] as List<dynamic>? ?? [];
    return messages.map((message) {
      return {
        'text': message['text'] ?? '',
        'isUser': message['isUser'] ?? false,
        'timestamp': (message['timestamp'] as Timestamp?)?.toDate(),
      };
    }).toList();
  });
});

final sendMessageProvider = Provider((ref) => SendMessageService());

class SendMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String ticketId, String text) async {
    try {
      final collection = _firestore.collection('Help');
      final timestamp = DateTime.now();

      // Check if the ticket exists
      final querySnapshot =
          await collection.where('ticketId', isEqualTo: ticketId).get();

      if (querySnapshot.docs.isEmpty) {
        // Create a new ticket with the message
        await collection.add({
          'ticketId': ticketId,
          'messages': [
            {
              'text': text,
              'isUser': true,
              'timestamp': timestamp,
            }
          ],
        });
      } else {
        // Append the message to the existing ticket
        final docId = querySnapshot.docs.first.id;
        await collection.doc(docId).update({
          'messages': FieldValue.arrayUnion([
            {
              'text': text,
              'isUser': true,
              'timestamp': timestamp,
            }
          ]),
        });
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}


class TicketChatPage extends ConsumerWidget {
  final String ticketId;

  const TicketChatPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesStream = ref.watch(messagesProvider(ticketId));
    final sendMessageService = ref.read(sendMessageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF273847),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chat Support',
          style: TextStyle(color: Colors.white, fontFamily: "poppins"),
        ),
      ),
      body: messagesStream.when(
        data: (messages) {
          final chatMessages = messages.map((message) {
            final isUserMessage = message['isUser'] ?? false;
            return types.TextMessage(
              id: const Uuid().v4(),
              author: types.User(
                id: isUserMessage ? 'user' : 'support',
                firstName: isUserMessage ? 'You' : 'Support',
              ),
              text: message['text'] ?? '',
              createdAt:
                  (message['timestamp'] as DateTime?)?.millisecondsSinceEpoch,
            );
          }).toList();

          return Chat(
  messages: chatMessages,
  onSendPressed: (partialMessage) async {
    final text = partialMessage.text.trim();
    if (text.isNotEmpty) {
      try {
        await sendMessageService.sendMessage(ticketId, text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    }
  },
  user: const types.User(id: 'user', firstName: 'You'),
  theme: DefaultChatTheme(
    sendButtonIcon: Image.asset(color: Colors.white,
      'lib/assets/images/icon-send.png', // Your custom asset path
      height: 24,
      width: 24,
    ),
    bubbleMargin: const EdgeInsets.all(10),
    inputBackgroundColor: const Color(0xFF273847),
    primaryColor: const Color(0xFF273847),
    inputTextColor: Colors.white,
    inputTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
    inputTextCursorColor: Colors.white,
    sentMessageBodyTextStyle: const TextStyle(
      color: Colors.white,
    ),
    receivedMessageBodyTextStyle: const TextStyle(
      color: Colors.white,
    ),
  ),
);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}