import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_predictor/components/chat_bubble.dart';
import 'package:data_predictor/components/my_text_field.dart';
import 'package:data_predictor/models/message.dart';
import 'package:data_predictor/services/auth/auth_service.dart';
import 'package:data_predictor/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

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

  Future<List<Map<String, dynamic>>> _fetchConversationHistory() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .get();
    final conversations = querySnapshot.docs;

    List<Map<String, dynamic>> conversationHistories = [];

    for (var conversation in conversations) {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .collection('conversations')
          .doc(conversation.id)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(1)
          .get();

      final lastMessage = messagesSnapshot.docs.isNotEmpty
          ? messagesSnapshot.docs.first.data()['text']
          : 'No messages yet';

      conversationHistories.add({
        'id': conversation.id,
        'lastMessage': _truncateMessage(lastMessage, 30),
      });
    }

    return conversationHistories;
  }

  String _truncateMessage(String message, int limit) {
    if (message.length > limit) {
      return '${message.substring(0, limit)}...';
    }
    return message;
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

  void _startNewConversation() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;
    final newConversationId = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .doc()
        .id;

    final initialMessage = 'Hello! How can I help you today?';
    await _chatService.saveMessageToFirestore(
        newConversationId, 'bot', initialMessage);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ChatPage(conversationID: newConversationId)),
    );
  }

  void _navigateToConversation(String conversationId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ChatPage(
                conversationID: conversationId,
              )),
    );
  }

  void signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 70,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 184, 60, 22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat),
                      color: Colors.white,
                      onPressed: _startNewConversation,
                      tooltip: 'Start New Chat',
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchConversationHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Center(child: Text('Loading...')));
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const ListTile(
                    title: Text('No conversation history'),
                  );
                } else {
                  final conversationHistories = snapshot.data!;
                  return Column(
                    children: conversationHistories.map((conversation) {
                      return ListTile(
                        title: Text(conversation['id']),
                        subtitle: Text(conversation['lastMessage']),
                        onTap: () {
                          _navigateToConversation(conversation['id']);
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(widget.conversationID),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessageList(),
          ),
          // User input
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.conversationID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Loading...'));
        }
        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  // Build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    // Align messages to the right if they are from the user and to the left if they are from the bot
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
          children: [
            ChatBubble(message: data['text']),
          ],
        ),
      ),
    );
  }

  // Build message input
  Widget _buildMessageInput() {
    return Row(
      children: [
        // Text field
        Expanded(
          child: MyTextField(
            controller: _messageController,
            hintText: 'Enter message',
            obscureText: false,
          ),
        ),
        // Send button
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 40),
          onPressed: sendMessage,
        ),
      ],
    );
  }
}
