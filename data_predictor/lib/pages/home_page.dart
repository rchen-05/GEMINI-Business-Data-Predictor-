import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_predictor/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:data_predictor/pages/chat_page.dart';

class NewHomePage extends StatefulWidget {
  final String userId;

  NewHomePage({required this.userId});

  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final ChatService _chatService = ChatService();
  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _conversationHistoryFuture;
  late Future<List<String>> _conversationIdsFuture;

  @override
  void initState() {
    super.initState();
    _conversationHistoryFuture = _fetchConversationHistory();
    _conversationIdsFuture = getUserConversationIds();
  }

  Future<void> _startNewConversation() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;
    Timestamp timestamp = Timestamp.now();
    if (currentUserID == null) return;

    final newConversationDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .doc();
    final newConversationId = newConversationDocRef.id;

    newConversationDocRef.set({
      'conversationId': newConversationId,
      'lastUpdated': timestamp,
    });

    const initialMessage = 'Hello! How can I help you today?';

    // Save the initial message to Firestore
    await _chatService.saveMessageToFirestore(
      newConversationId,
      'bot',
      initialMessage,
    );

    // Refresh the conversation history
    setState(() {
      _conversationHistoryFuture = _fetchConversationHistory();
      _conversationIdsFuture = getUserConversationIds();
    });

    // Navigate to the new conversation's chat page
    setState(() {
      _selectedIndex = 0; // Assuming the new conversation is at the top
    });
  }

  Future<List<Map<String, dynamic>>> _fetchConversationHistory() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;
    if (currentUserID == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .orderBy('lastUpdated', descending: true) // Order by latest updated conversation
        .get();

    final conversations = querySnapshot.docs;

    if (conversations.isEmpty) {
      // No conversations exist, so start a new one
      await _startNewConversation();
      // Fetch the conversation history again after creating the new conversation
      return _fetchConversationHistory();
    }

    List<Map<String, dynamic>> conversationHistories = [];

    for (var conversation in conversations) {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .collection('conversations')
          .doc(conversation.id)
          .collection('messages')
          .orderBy('timestamp', descending: true) // Get the most recent message
          .limit(1)
          .get();

      final lastMessage = messagesSnapshot.docs.isNotEmpty
          ? messagesSnapshot.docs.first.data()['text'] as String
          : 'No messages yet';

      conversationHistories.add({
        'id': conversation.id,
        'lastMessage': _truncateMessage(lastMessage, 30),
      });
    }

    return conversationHistories;
  }

  Future<List<String>> getUserConversationIds() async {
    try {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final currentUserID = _firebaseAuth.currentUser?.uid;
      if (currentUserID == null) {
        throw Exception("No user logged in");
      }

      // Fetch conversation documents for the current user
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserID)
          .collection('conversations')
          .get();

      // Extract conversation IDs
      final conversationIds = snapshot.docs.map((doc) => doc.id).toList();

      return conversationIds;
    } catch (e) {
      print('Error fetching conversation IDs: $e');
      return [];
    }
  }

  void _onConversationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _truncateMessage(String message, int limit) {
    if (message.length > limit) {
      return '${message.substring(0, limit)}...';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            color: const Color.fromARGB(255, 30, 31, 32),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 70,
                  child: DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 30, 31, 32),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'SFCompactText',
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
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _conversationHistoryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Text('Loading...',
                              style: TextStyle(
                                  fontFamily: 'SFCompactText',
                                  color: Colors.white)),
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          title: Text('Error: ${snapshot.error}',
                              style: const TextStyle(
                                  fontFamily: 'SFCompactText',
                                  color: Colors.white)),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const ListTile(
                          title: Text(
                            'No conversation history',
                            style: TextStyle(
                                fontFamily: 'SFCompactText',
                                color: Colors.white),
                          ),
                        );
                      } else {
                        final conversationHistories = snapshot.data!;
                        return ListView.builder(
                          itemCount: conversationHistories.length,
                          itemBuilder: (context, index) {
                            final conversation = conversationHistories[index];
                            return ListTile(
                              tileColor: _selectedIndex == index
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade900,
                              hoverColor: Colors.grey.shade600,
                              title: Text(conversation['lastMessage'],
                                  style: const TextStyle(
                                      fontFamily: 'SFCompactText',
                                      color: Colors.white)),
                              onTap: () => _onConversationTapped(index),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _conversationIdsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Text('Loading...',
                          style: TextStyle(fontFamily: 'SFCompactText')));
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading page',
                          style: TextStyle(fontFamily: 'SFCompactText')));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No data available',
                          style: TextStyle(fontFamily: 'SFCompactText')));
                } else {
                  List<Widget> pages = snapshot.data!
                      .map((conversationID) =>
                          ChatPage(conversationID: conversationID))
                      .toList();
                  return IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
