import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final String sender; // 'user' or 'support'
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'sender': sender,
    'timestamp': timestamp,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    text: m['text'] as String,
    sender: m['sender'] as String,
    timestamp: m['timestamp'] as String,
  );
}

class ChatService {
  static const _key = 'chat_messages_v1';

  static Future<List<ChatMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addMessage(ChatMessage m) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = await getMessages();
    final newList = [...cur, m];
    final raw = jsonEncode(newList.map((e) => e.toMap()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
