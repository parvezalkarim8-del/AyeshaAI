import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: const ColorScheme.dark(primary: Color(0xFFB78CFF)),
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
  static const String apiUrl = 'http://127.0.0.1:4173/api/chat';

  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <Map<String, String>>[];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ayesha_chat_history');
    if (saved == null) return;

    try {
      final decoded = jsonDecode(saved) as List;
      if (!mounted) return;
      setState(() {
        messages
          ..clear()
          ..addAll(decoded.map((e) => Map<String, String>.from(e)));
      });
      scrollToBottom();
    } catch (_) {}
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ayesha_chat_history', jsonEncode(messages));
  }

  List<Map<String, String>> get historyForApi {
    return messages
        .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
        .toList()
        .take(messages.length > 12 ? 12 : messages.length)
        .map((m) => {
              'role': m['role'] == 'You' ? 'user' : 'assistant',
              'content': m['text'] ?? '',
            })
        .toList();
  }

  Future<void> sendMessage() async {
    final message = controller.text.trim();
    if (message.isEmpty || loading) return;

    controller.clear();

    final oldHistory = historyForApi;

    setState(() {
      messages.add({'role': 'You', 'text': message});
      loading = true;
    });
    scrollToBottom();
    await saveHistory();

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'message': message,
              'history': oldHistory,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data is Map && data['reply'] != null) {
        final reply = data['reply'].toString();
        if (!mounted) return;
        setState(() {
          messages.add({'role': 'Ayesha', 'text': reply});
        });
      } else {
        final error = data is Map
            ? (data['error'] ?? 'Server se reply nahi mila.')
            : 'Server ka response samajh nahi aaya.';
        if (!mounted) return;
        setState(() {
          messages.add({'role': 'Ayesha', 'text': '⚠️ $error'});
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'Ayesha',
          'text':
              '⚠️ Termux backend se connection nahi ho paya. Termux mein Ayesha server chalu hai ya nahi check karo.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
        await saveHistory();
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> clearChat() async {
    setState(() => messages.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ayesha_chat_history');
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
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
                Text('Local AI connection',
                    style: TextStyle(
                        fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: loading ? null : clearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
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
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (loading && index == messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Ayesha soch rahi hai...'),
                              ],
                            ),
                          ),
                        );
                      }

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
                          child: SelectableText(item['text'] ?? ''),
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
                      enabled: !loading,
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
                      onPressed: loading ? null : sendMessage,
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
