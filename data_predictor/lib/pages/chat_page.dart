import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  

  @override
  State<ChatPage> createState() => _ChatPageState();
}



class _ChatPageState extends State<ChatPage> {
  List<ChatMessage> _messages = <ChatMessage>[];

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Daniel', lastName: 'Bobby');
  final ChatUser _geminiUser = ChatUser(id: '2', firstName: 'Ai', lastName: 'man');

  List<ChatUser> _typingUsers = <ChatUser>[];
  final TextEditingController _textController = TextEditingController();
  

  Future<void> getChatResponse(ChatMessage message) async {
    final userMessage = message.text;
    final url = 'http://127.0.0.1:5001/chat'; // Flask server URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final aiResponse = data['response'];
        if (aiResponse is String) {
          setState(() {
            _messages.insert(
              0, 
              ChatMessage(
                text: aiResponse,
                createdAt: DateTime.now(),
                user: _geminiUser,
              ));
          });
        } else {
          setState(() {
            _messages.insert(
              0, 
              ChatMessage(
                text: 'Error: Unexpected response format',
                createdAt: DateTime.now(),
                user: _geminiUser,
              ));
          });
        }
      } else {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: 'Error: ${response.reasonPhrase}',
              createdAt: DateTime.now(),
              user: _geminiUser,
            ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: 'An error occurred: $e',
            createdAt: DateTime.now(),
            user: _geminiUser,
          ));
      });
    }
    setState(() {
      _typingUsers.remove(_geminiUser);
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes != null) {
        try {
          await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
        } catch (e) {
          print('Error uploading file: $e');
        }
      }
    }
  }
  Widget sendButton(){
    return FloatingActionButton(
      onPressed: pickFile,
      child: const Icon(Icons.attach_file),
    );
  }
  List<Widget> inputOptions(){
    return [
      sendButton()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 184, 60, 22),
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        typingUsers: _typingUsers,
        inputOptions: InputOptions(
          sendOnEnter: true,
          alwaysShowSend: true,
          trailing: inputOptions()
        ),
        messageOptions:  MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromARGB(255, 184, 60, 22),
          textColor: Colors.white,
          messageTextBuilder: (currentMessage, previousMessage, nextMessage) {
             if (currentMessage.user.id == _geminiUser.id && nextMessage == null) {
              return AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    currentMessage.text,
                    speed: const Duration(milliseconds: 30),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
                totalRepeatCount: 1,
              );
            } else {
              return SelectableText(
                currentMessage.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              );
            }
          },
  ),
        onSend: (ChatMessage message) {
          setState(() {
            _messages.insert(0, message);
            _typingUsers.add(_geminiUser);
          });
          
          getChatResponse(message);
        },
        messages: _messages,
      ),
    );
  }
}
