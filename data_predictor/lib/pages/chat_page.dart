import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_predictor/utilities/chat_utilities.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});
  
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = <ChatMessage>[]; // List to store chat messages
  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Daniel', lastName: 'Bobby'); // Current user details
  final ChatUser _geminiUser = ChatUser(id: '2', firstName: 'Ai', lastName: 'man'); // AI user details
  final List<ChatUser> _typingUsers = <ChatUser>[]; // List of users currently typing

  @override
  void initState() {
    super.initState();
    print('Initializing chat');
    _initializeChat(); // Initialize chat when the widget is first built
  }

  Future<void> _initializeChat() async {
    // Fetch initial messages from Firestore
    final messages = await _chatService.getMessagesOnce(widget.conversationId);
    print('Number of messages: ${messages.length}'); // Log the number of messages

    if (messages.isEmpty) {
      // Send the initial message only if there are no messages
      await _sendInitialMessage();
    }
  }

  Future<void> _sendInitialMessage() async {
    final initialMessage = ChatMessage(
      text: 'Hello, how can I help you today?',
      createdAt: DateTime.now(),
      user: _geminiUser,
    );

    // Save the initial message to Firestore
    await _chatService.saveMessageToFirestore(widget.conversationId, initialMessage);
  }

  Future<void> getChatResponse(ChatMessage message) async {
    final userMessage = message.text;
    const url = 'http://127.0.0.1:5001/chat'; // Flask server URL

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
          final aiMessage = ChatMessage(
            text: aiResponse,
            createdAt: DateTime.now(),
            user: _geminiUser,
          );
          setState(() {
            _messages.insert(0, aiMessage); // Insert AI response to the message list
          });
          _chatService.saveMessageToFirestore(widget.conversationId, aiMessage);
        } else {
          final errorMessage = ChatMessage(
            text: 'Error: Unexpected response format',
            createdAt: DateTime.now(),
            user: _geminiUser,
          );
          setState(() {
            _messages.insert(0, errorMessage); // Insert error message
          });
        }
      } else {
        final errorMessage = ChatMessage(
          text: 'Error: ${response.reasonPhrase}',
          createdAt: DateTime.now(),
          user: _geminiUser,
        );
        setState(() {
          _messages.insert(0, errorMessage); // Insert error message
        });
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'An error occurred: $e',
        createdAt: DateTime.now(),
        user: _geminiUser,
      );
      setState(() {
        _messages.insert(0, errorMessage); // Insert error message
      });
    }
    setState(() {
      _typingUsers.remove(_geminiUser); // Remove AI from typing users
    });
  }
  void _navigateToConversation(String conversationId) { // Navigate to a specific conversation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(conversationId: conversationId)),
    );
  }
  Future<List<Map<String, dynamic>>> _fetchConversationHistory() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('conversations').get();
    final conversations = querySnapshot.docs;

    // Create a list to store conversations with their last messages
    List<Map<String, dynamic>> conversationHistories = [];

    for (var conversation in conversations) {
      // Fetch the last message of the conversation
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversation.id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // Get the last message text if available
      final lastMessage = messagesSnapshot.docs.isNotEmpty
          ? messagesSnapshot.docs.first.data()['text']
          : 'No messages yet';

      // Add the conversation ID and last message to the list
      conversationHistories.add({
        'id': conversation.id,
        'lastMessage': lastMessage,
      });
    }

    return conversationHistories;
  }

  Future<void> pickFile() async { // File picker function
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      if (fileBytes != null) {
        try {
          await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes); // Upload file to Firebase Storage
        } catch (e) {
          print('Error uploading file: $e');
        }
      }
    }
  }

  Widget sendButton() {
    return FloatingActionButton.small(
      onPressed: pickFile, // Trigger file picker
      child: const Icon(Icons.attach_file),
    );
  }

  List<Widget> inputOptions() {
    return [
      sendButton() // Add send button as an input option
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
                      onPressed: _startNewConversation, // Start a new conversation
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
                  return const Center(child: CircularProgressIndicator());
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
      body: Center(
        child: StreamBuilder<List<ChatMessage>>(
          stream: _chatService.getMessages(widget.conversationId), // Stream messages from Firestore
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // Show loading indicator
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}')); // Show error message
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('No messages yet.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _sendInitialMessage();
                      _startNewConversation();
                    },
                    child: const Text('Create New Chat'),
                  ),
                ],
              );
            } else {
              final messages = snapshot.data!;
              return DashChat(
                currentUser: _currentUser,
                typingUsers: _typingUsers,
                inputOptions: InputOptions(
                  sendOnEnter: true,
                  alwaysShowSend: true,
                  trailing: inputOptions(),
                ),
                messageOptions: MessageOptions(
                  currentUserContainerColor: Colors.black,
                  containerColor: const Color.fromARGB(255, 184, 60, 22),
                  textColor: Colors.white,
                  messageTextBuilder: (currentMessage, previousMessage, nextMessage) {
                    if (currentMessage.user.id == _geminiUser.id && nextMessage == null) {
                      return AnimatedTextKit(
                        animatedTexts: [
                          TyperAnimatedText(
                            currentMessage.text,
                            speed: const Duration(milliseconds: 9),
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
                    _messages.insert(0, message); // Add new message to the list
                  });
                  _chatService.saveMessageToFirestore(widget.conversationId, message); // Save message to Firestore
                  getChatResponse(message); // Get AI response for the message
                },
                messages: messages,
              );
            }
          },
        ),
      ),
    );
  }

  void _startNewConversation() async {
    final newConversationId = FirebaseFirestore.instance.collection('conversations').doc().id; // Generate new conversation ID
    // Create and save initial message for the new conversation
    final initialMessage = ChatMessage(
      text: 'Hello, how can I help you today?',
      createdAt: DateTime.now(),
      user: _geminiUser,
    );
    await _chatService.saveMessageToFirestore(newConversationId, initialMessage); // Save initial message to Firestore

    // Navigate to the new conversation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(conversationId: newConversationId)),
    );
  }
}
