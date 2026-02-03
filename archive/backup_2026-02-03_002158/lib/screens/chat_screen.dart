import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  Future<void> _load() async {
    final msgs = await ChatService.getMessages();
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final m = ChatMessage(text: text.trim(), sender: 'user', timestamp: now);
    await ChatService.addMessage(m);
    _controller.clear();
    await _load();

    // Simulate automated reply
    Future.delayed(const Duration(seconds: 2), () async {
      final reply = ChatMessage(
        text: 'Thanks for reaching out. Our team will contact you shortly.',
        sender: 'support',
        timestamp: DateTime.now().toIso8601String(),
      );
      await ChatService.addMessage(reply);
      if (!mounted) return;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with us')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    itemCount: _messages.length,
                    reverse: false,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final time = DateFormat.Hm().format(
                        DateTime.parse(m.timestamp),
                      );
                      final isUser = m.sender == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.text),
                              const SizedBox(height: 6),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                    onSubmitted: _send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
