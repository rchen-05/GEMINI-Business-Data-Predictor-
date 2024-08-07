import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _conversationHistoryFuture;
  late Future<List<String>> _conversationIdsFuture;

  @override
  void initState() {
    super.initState();
    _conversationHistoryFuture = _fetchConversationHistory();
    _conversationIdsFuture = getUserConversationIds();
  }

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
            width: 200,
            color: const Color.fromARGB(255, 184, 60, 22),
            child: Column(
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
                          onPressed: () {},
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
                        return const Center(child: Text('Loading...'));
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
                        return ListView.builder(
                          itemCount: conversationHistories.length,
                          itemBuilder: (context, index) {
                            final conversation = conversationHistories[index];
                            return ListTile(
                              title: Text(conversation['id']),
                              subtitle: Text(conversation['lastMessage']),
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
                        return const Center(child: Text('Loading...'));
                }else if (snapshot.hasError) {
                  return Center(child: Text('Error loading page'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  List<Widget> pages = snapshot.data!
                      .map((conversationID) => ChatPage(conversationID: conversationID))
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
