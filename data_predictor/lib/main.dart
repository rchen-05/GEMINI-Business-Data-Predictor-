import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCzBt-9HzTi5eVDKJ728Hha6Em1ebs4fEw',
      appId: '1:408279633368:web:812409e43b1e0a1c54f6ad',
      messagingSenderId: '408279633368',
      projectId: 'data-predictor-32a58',
      authDomain: 'data-predictor-32a58.firebaseapp.com',
      storageBucket: 'data-predictor-32a58.appspot.com',
      measurementId: 'G-XPXXV293SC',
    )
  );
  runApp(MaterialApp(
    home: ChatScreen(),
  ));
 
}

class ChatScreen extends StatefulWidget {
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

    final userMessage = _textController.text;
    final url = 'http://127.0.0.1:5001/chat'; // Flask server URL

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      _textController.clear();
    });

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

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes != null) {
        FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
      }
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
                  title: SelectableText(
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
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: pickFile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
