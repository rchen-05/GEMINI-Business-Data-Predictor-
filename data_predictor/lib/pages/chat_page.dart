import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_predictor/components/ai_chat_bubble.dart';
import 'package:data_predictor/components/chat_bubble.dart';
import 'package:data_predictor/components/chat_controller.dart';
import 'package:data_predictor/services/auth/auth_service.dart';
import 'package:data_predictor/services/chat_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:http_parser/http_parser.dart';

class ChatPage extends StatefulWidget {
  final String conversationID;
  const ChatPage({
    super.key,
    required this.conversationID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  late ScrollController _scrollController;

  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  Future<void> getChatResponse(String userMessage) async {
    const url = 'http://127.0.0.1:5001/chat';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'];
        await _chatService.saveMessageToFirestore(
          widget.conversationID,
          'bot',
          aiResponse,
        );
      } else {
        print('Failed to get response from the server.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes != null) {
        try {
<<<<<<< HEAD
          await FirebaseStorage.instance
              .ref('uploads/$fileName')
              .putData(fileBytes);
=======
            final ref = FirebaseStorage.instance.ref('uploads/$fileName');
            await ref.putData(fileBytes);

            final downloadURL = await ref.getDownloadURL();

            await sendFileToBackend(downloadURL, fileName);


//           await FirebaseStorage.instance
//               .ref('uploads/$fileName')
//               .putData(fileBytes);
>>>>>>> WORKS-FINAL-FINAL
        } catch (e) {
          print('Error uploading file: $e');
        }
      }
    }
  }

<<<<<<< HEAD
=======
  Future<void> sendFileToBackend(String downloadURL, String fileName) async {
    const backendURL = 'http://127.0.0.1:5001/upload_file';

    try {
      final response = await http.post(
        Uri.parse(backendURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
        "file_url": downloadURL,
        "file_name": fileName,
        }),
      );

      if (response.statusCode == 200) {
        print('File sent to backend successfully');
      } else {
        print('Failed to get response from the server.');
      }
    } catch (e) {
      print('Error sending file to backend: $e');
    }
  }

>>>>>>> WORKS-FINAL-FINAL
  void sendMessage() async {
    // Only send message if the text field is not empty
    if (_messageController.text.isNotEmpty) {
      await _chatService.saveMessageToFirestore(
        widget.conversationID,
        'user',
        _messageController.text,
      );
      // Clear the text field after sending the message
      getChatResponse(_messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 19, 19, 20),
      appBar: AppBar(
        title: Text(widget.conversationID,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'SFCompactText')),
        backgroundColor: const Color.fromARGB(255, 19, 19, 20),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 19, 19, 20),
          ),
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Messages

              Expanded(
                child: _buildMessageList(),
              ),
              // User input

              _buildMessageInput(),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Build message list
  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: StreamBuilder(
        stream: _chatService.getMessages(widget.conversationID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}',
                style: const TextStyle(
                    fontFamily: 'SFCompactText', color: Colors.white));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Text('Loading...',
                    style: TextStyle(
                        fontFamily: 'SFCompactText', color: Colors.white)));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });

          return ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final document = snapshot.data!.docs[index];
              return _buildMessageItem(document);
            },
          );
        },
      ),
    );
  }

  // Build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    var alignment = (data['sender'] == 'user')
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            crossAxisAlignment: (data['sender'] == 'user')
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: (data['sender'] == 'user')
                ? [
                    ChatBubble(message: data['text']),
                  ]
                : [
                    AiChatBubble(message: data['text']),
                  ]),
      ),
    );
  }

  // Build message input
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 31, 32),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            // Attach file button
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 15,
                  icon: const Icon(Icons.attach_file,
                      size: 15, color: Color.fromARGB(255, 30, 31, 32)),
                  onPressed: pickFile,
                ),
              ),
            ),
            // Text field
            Expanded(
              child: ChatController(
                controller: _messageController,
                hintText: 'Enter message',
                obscureText: false,
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 15,
                  icon: const Icon(Icons.arrow_upward,
                      size: 15, color: Color.fromARGB(255, 30, 31, 32)),
                  onPressed: sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
