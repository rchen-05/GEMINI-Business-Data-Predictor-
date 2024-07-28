import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: ChatScreen(),
  ));
}

<<<<<<< Updated upstream


class MyHomePage extends StatefulWidget {
=======
class ChatScreen extends StatefulWidget {
>>>>>>> Stashed changes
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> sendMessage() async {
    if (_textController.text.isEmpty) {
      return;
    }

<<<<<<< Updated upstream
    final csvContent = _textController.text;
    final url = 'http://127.0.0.1:5001/get_regressor'; // Flask server URL
=======
    final userMessage = _textController.text;
    final url = 'http://127.0.0.1:5001/chat'; // Flask server URL

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      _textController.clear();
    });
>>>>>>> Stashed changes

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure we are dealing with the correct data type
        final aiResponse = data['response'];
        if (aiResponse is String) {
          setState(() {
            messages.add({"role": "ai", "content": aiResponse});
          });
        } else {
          setState(() {
            messages.add({"role": "ai", "content": 'Error: Unexpected response format'});
          });
        }
      } else {
        setState(() {
          messages.add({"role": "ai", "content": 'Error: ${response.reasonPhrase}'});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "content": 'An error occurred: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Chat AI"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['role'] == 'user';
                return ListTile(
                  title: Text(
                    message['content']!,
                    textAlign: isUser ? TextAlign.end : TextAlign.start,
                  ),
                  tileColor: isUser ? Colors.blue[100] : Colors.grey[200],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Enter your message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
