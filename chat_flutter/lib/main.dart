import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('ws://10.0.2.2:8000/ws/chat/lobby/'),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Django Chat',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: ChatPage(channel: channel),
    );
  }
}

class ChatPage extends StatefulWidget {
  final WebSocketChannel channel;

  ChatPage({required this.channel});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String formatTimestamp(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final formatted = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    return formatted;
  }
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late String _myId;
  late String _myUsername;
  List<String> _suggestions = [];
  String? _summary;
  List<String> sampleNames = ['Alex', 'Viki', 'Sam', 'Taylor', 'Jordan', 'Casey'];
  
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = _controller.text.trim();
      widget.channel.sink.add(jsonEncode({'message': message, 'sender': _myId, 'username': _myUsername , 'timestamp': DateTime.now().toIso8601String(),}));
      _controller.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _myId = DateTime.now().millisecondsSinceEpoch.toString();
    _myUsername = sampleNames[Random().nextInt(sampleNames.length)];
    widget.channel.stream.listen((message) {
      try {
        dynamic decoded = jsonDecode(message);
        setState(() {
          if (decoded is Map<String, dynamic> &&
            decoded.containsKey('message') &&
            decoded.containsKey('sender') &&
            decoded.containsKey('username')) {
            setState(() {
              _messages.add(decoded);
            });
          }
        });
      } catch (e) {
        print("Failed to decode message: $message");
      }
    });
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Real-Time Django Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                print("Sender: ${msg['sender']}  |  MyId: $_myId");
                final isMe = msg['sender'].toString() == _myId; // compare with your ID

                return Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      CircleAvatar(
                        child: Text(msg['sender'][0]), // first character of sender ID
                        radius: 16,
                      ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              msg['username'] ?? 'Anonymous',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              formatTimestamp(msg['timestamp']),
                              style: TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),

                      ),
                    ),
                    if (isMe) SizedBox(width: 8),
                  ],
                );

              },
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_summary != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Card(
                      color: Colors.amber[100],
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                _summary!,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _summary = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),



                if (_suggestions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: _suggestions.map((s) {
                      return ActionChip(
                        label: Text(s),
                        onPressed: () {
                          setState(() {
                            _controller.text = s;
                            _suggestions = [];
                          });
                        },
                      );
                    }).toList(),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(hintText: 'Enter your message'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.bolt), // ⚡️ Ask AI button
                      onPressed: () async {
                        final lastReceived = _messages.lastWhere(
                          (m) => m['sender'] != _myId,
                          orElse: () => {},
                        );
                        if (lastReceived.isNotEmpty) {
                          final prompt = lastReceived['message'] ?? '';
                          try {
                            final replies = await getReplySuggestions(prompt);
                            setState(() {
                              _suggestions = replies;
                            });
                          } catch (e) {
                            print("AI error: $e");
                          }
                        }
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.summarize), // 📋
                      onPressed: () async {
                        await summarizeChat();
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Future<List<String>> getReplySuggestions(String prompt) async {
    final url = Uri.parse('http://10.0.2.2:8001/chat'); // Android emulator = 10.0.2.2

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': 'Suggest 3 replies to: "$prompt"'}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final rawText = decoded['response']?.toString() ?? '';

      // Safely split only if it's a proper string
      return rawText
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    } else {
      throw Exception('Failed to get suggestions');
    }
  }

  Future<void> summarizeChat() async {
    if (_messages.isEmpty) return;

    // Get last 10 messages, or fewer if not available
    final last10 = _messages.takeLast(10).toList();

    // Format as a string
    final conversation = last10.map((m) =>
      "${m['username'] ?? 'User'}: ${m['message']}"
    ).join("\n");

    final url = Uri.parse('http://10.0.2.2:8001/chat');

    try {
      final response = await http.post(    
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': 'Summarize this conversation in 1-2 lines:\n$conversation'
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _summary = decoded['response'] ?? 'No summary available.';
        });
      } else {
        print("Failed to get summary: ${response.statusCode}");
      }
    } catch (e) {
      print("Summary error: $e");
    }
  }

}

extension LastMessages<T> on List<T> {
  Iterable<T> takeLast(int n) {
    final len = this.length;
    return this.skip(len - (n < len ? n : len));
  }
}
