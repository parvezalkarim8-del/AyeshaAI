import 'package:flutter/material.dart';

void main() {
  runApp(const AyeshaApp());
}

class AyeshaApp extends StatelessWidget {
  const AyeshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ayesha AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10111B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB78CFF),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[];

  void sendMessage() {
    final message = controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      messages.add({'role': 'You', 'text': message});
      messages.add({
        'role': 'Ayesha',
        'text': 'Hello! Main Ayesha hoon. ❤️ AI connection jald taiyar hoga.',
      });
    });

    controller.clear();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF191A29),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFB78CFF),
              child: Icon(Icons.auto_awesome, color: Colors.white),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ayesha AI', style: TextStyle(fontSize: 19)),
                Text('Your AI Assistant',
                    style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 65, color: Color(0xFFB78CFF)),
                        SizedBox(height: 15),
                        Text('Hello! Main Ayesha hoon ❤️',
                            style: TextStyle(fontSize: 21)),
                        SizedBox(height: 8),
                        Text('Aaj main aapki kya madad karun?'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[index];
                      final isUser = item['role'] == 'You';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 7),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(maxWidth: 290),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF6846A5)
                                : const Color(0xFF252638),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(item['text']!),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ayesha se kuch puchho...',
                        filled: true,
                        fillColor: const Color(0xFF252638),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF9B70E8),
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
