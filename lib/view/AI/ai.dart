import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy/view/AI/suggestion.dart';

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, this.isUser = false});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this.ref) : super([]);

  final Ref ref;
  final String apiUrl = 'https://api-jfnhkjk4nq-uc.a.run.app/generate-text';

  void addUserMessage(String message) {
    state = [...state, ChatMessage(message: message, isUser: true)];
    generateAIResponse(message);
    ref.read(promptProvider.notifier).clearPrompts();
  }

  Future<void> generateAIResponse(String prompt) async {
    state = [...state, ChatMessage(message: "Thinking...", isUser: false)];

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final aiMessage =
            responseData['generatedText'] ?? 'No response received.';
        state = [
          ...state.sublist(0, state.length - 1),
          ChatMessage(message: aiMessage, isUser: false),
        ];
      } else {
        state = [
          ...state,
          ChatMessage(message: "Failed to fetch response.", isUser: false)
        ];
      }
    } catch (e) {
      state = [...state, ChatMessage(message: "Error: $e", isUser: false)];
    }
  }

  Future<String> fetchHealthTip() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': 'Give me a short, interesting health tip in one sentence.'
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['generatedText'] ?? 'Stay hydrated and eat well!';
      } else {
        return 'Health tip currently unavailable.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(ref),
);

final healthTipProvider = FutureProvider<String>((ref) async {
  final notifier = ref.read(chatProvider.notifier);
  return await notifier.fetchHealthTip();
});

class PromptNotifier extends StateNotifier<List<String>> {
  PromptNotifier() : super(_generateRandomPrompts());

  static final List<String> _allPrompts = [
    "Do you have Muesli available in the Kealthy store, and what are the best options?",
    "Do you have groceries like organic grains, fresh produce, or pantry essentials in stock?",
    "Do you have bath essentials such as herbal soaps or organic skincare products in Kealthy?",
    "Can you recommend healthy snacks like multigrain chips or nutrient-rich trail mixes in Kealthy?",
    "What are the best cereals available in Kealthy for a healthy and balanced breakfast option?",
    "Can you suggest some immunity-boosting foods or supplements available in the Kealthy store?",
    "Do you have ready-to-eat meals that are healthy and convenient for quick and nutritious options?",
    "Can I find gluten-free or vegan-friendly products in the Kealthy app, and what are the choices?",
    "What healthy drinks or beverages do you offer in Kealthy that can help with hydration and energy?",
    "Can you tell me more about the herbal teas or detox drinks available in the Kealthy catalog?",
    "Can you provide some health tips for maintaining a balanced diet and staying fit every day?",
    "What are some effective ways to improve gut health and digestion with products from Kealthy?",
    "Can you share some tips on how to boost energy levels naturally with food and lifestyle choices?",
    "I need help with my order; can you guide me on how to track my delivery status in Kealthy?",
    "Where can I find my purchase history and manage my account settings in the Kealthy profile?",
    "How do I raise a support ticket for an issue, and what is the contact number for help in Kealthy?",
    "Can I get assistance with processing a return or exchange for a product bought on Kealthy?",
    "Are there any ongoing offers or discounts on healthy products in the Kealthy app currently?",
    "What are the best superfoods available in Kealthy to enhance overall wellness and vitality?",
    "Can you suggest some healthy cooking oils or spices that add flavor and nutrition to meals?",
  ];

  static List<String> _generateRandomPrompts() {
    _allPrompts.shuffle();
    return _allPrompts.take(1).toList();
  }

  void clearPrompts() => state = [];

  void resetPrompts() => state = _generateRandomPrompts();
}

final promptProvider = StateNotifierProvider<PromptNotifier, List<String>>(
  (ref) => PromptNotifier(),
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController chatController = TextEditingController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatProvider);
    final randomPrompts = ref.watch(promptProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: Text(
            'Ask Nutri',
            style: GoogleFonts.montserrat(color: Colors.black, fontSize: 20.0),
          ),
          backgroundColor: Colors.white,
        ),
        body: Column(children: [
          Consumer(
            builder: (context, ref, _) {
              final tipAsync = ref.watch(healthTipProvider);
              return tipAsync.when(
                data: (tip) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 Did You Know?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(tip),
                      ],
                    ),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return ChatBubble(
                  message: message.message,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          if (randomPrompts.isNotEmpty)
            SizedBox(
              height: 280, // Adjust this value as needed
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                children: [
                  const HelpCenterPage(),
                  const SizedBox(height: 25),
                  Text(
                    "What can I help with?",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: randomPrompts.map((prompt) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            chatController.text = prompt;
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF273847),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              prompt,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    minLines: 1,
                    maxLines: null,
                    cursorColor: Colors.black,
                    controller: chatController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF273847),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF273847),
                        ),
                      ),
                      hintText: 'Ask Anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF273847),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    size: 30,
                    color: Color(0xFF273847),
                  ),
                  onPressed: () {
                    if (chatController.text.isNotEmpty) {
                      ref
                          .read(chatProvider.notifier)
                          .addUserMessage(chatController.text);
                      chatController.clear();
                      _scrollToBottom();
                    }
                  },
                ),
              ],
            ),
          ),
        ]));
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? Colors.grey.shade200 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          textAlign: TextAlign.start,
          message,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.grey : Colors.black,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
