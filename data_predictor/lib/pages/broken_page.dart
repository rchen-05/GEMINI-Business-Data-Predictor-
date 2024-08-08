

// import 'dart:convert';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:dash_chat_2/dash_chat_2.dart';
// import 'package:data_predictor/services/auth/auth_service.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:data_predictor/services/chat_service.dart';
// import 'package:provider/provider.dart';

// class ChatPage extends StatefulWidget {
//   final String conversationId;

//   const ChatPage({super.key, required this.conversationId,});
  
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final ChatService _chatService = ChatService();
//   final List<ChatMessage> _messages = <ChatMessage>[];
//   final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Daniel', lastName: 'Bobby');
//   final ChatUser _geminiUser = ChatUser(id: '2', firstName: 'Ai', lastName: 'man');
//   final List<ChatUser> _typingUsers = <ChatUser>[];
//   String? latestConversationId;

//   @override
//   void initState() {
//     super.initState();
//     _fetchLatestConversationId().then((id) {
//       setState(() {
//         latestConversationId = id;
//       });
//     });
//     print('Initializing chat');
//     _initializeChat();
//   }

//   Future<void> _initializeChat() async {
//     final messages = await _chatService.getMessagesOnce(widget.conversationId);
//     print('Number of messages: ${messages.length}');

//     if (messages.isEmpty) {
//       await _sendInitialMessage();
//     }
//   }

//   Future<void> _sendInitialMessage() async {
//     final initialMessage = ChatMessage(
//       text: 'Hello, how can I help you today?',
//       createdAt: DateTime.now(),
//       user: _geminiUser,
//     );

//     await _chatService.saveMessageToFirestore(widget.conversationId, initialMessage);
//   }

//   Future<void> getChatResponse(ChatMessage message) async {
//     final userMessage = message.text;
//     const url = 'http://127.0.0.1:5001/chat';

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"message": userMessage}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final aiResponse = data['response'];
//         if (aiResponse is String) {
//           final aiMessage = ChatMessage(
//             text: aiResponse,
//             createdAt: DateTime.now(),
//             user: _geminiUser,
//           );
//           setState(() {
//             _messages.insert(0, aiMessage);
//           });
//           _chatService.saveMessageToFirestore(widget.conversationId, aiMessage);
//         } else {
//           final errorMessage = ChatMessage(
//             text: 'Error: Unexpected response format',
//             createdAt: DateTime.now(),
//             user: _geminiUser,
//           );
//           setState(() {
//             _messages.insert(0, errorMessage);
//           });
//         }
//       } else {
//         final errorMessage = ChatMessage(
//           text: 'Error: ${response.reasonPhrase}',
//           createdAt: DateTime.now(),
//           user: _geminiUser,
//         );
//         setState(() {
//           _messages.insert(0, errorMessage);
//         });
//       }
//     } catch (e) {
//       final errorMessage = ChatMessage(
//         text: 'An error occurred: $e',
//         createdAt: DateTime.now(),
//         user: _geminiUser,
//       );
//       setState(() {
//         _messages.insert(0, errorMessage);
//       });
//     }
//     setState(() {
//       _typingUsers.remove(_geminiUser);
//     });
//   }

//   void _navigateToConversation(String conversationId) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => ChatPage(conversationId: conversationId)),
//     );
//   }

//   Future<List<Map<String, dynamic>>> _fetchConversationHistory() async {
//     final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//     final currentUserID = _firebaseAuth.currentUser?.uid;
//     final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserID).collection('conversations').get();
//     final conversations = querySnapshot.docs;

//     List<Map<String, dynamic>> conversationHistories = [];

//     for (var conversation in conversations) {
//       final messagesSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUserID)
//           .collection('conversations')
//           .doc(conversation.id)
//           .collection('messages')
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .get();

//       final lastMessage = messagesSnapshot.docs.isNotEmpty
//           ? messagesSnapshot.docs.first.data()['text']
//           : 'No messages yet';

//       conversationHistories.add({
//         'id': conversation.id,
//         'lastMessage': _truncateMessage(lastMessage, 30),
//       });
//     }

//     return conversationHistories;
//   }

//   Future<void> pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles();

//     if (result != null && result.files.isNotEmpty) {
//       final fileBytes = result.files.first.bytes;
//       final fileName = result.files.first.name;

//       if (fileBytes != null) {
//         try {
//           await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
//         } catch (e) {
//           print('Error uploading file: $e');
//         }
//       }
//     }
//   }

//   Widget sendButton() {
//     return FloatingActionButton.small(
//       onPressed: pickFile,
//       child: const Icon(Icons.attach_file),
//     );
//   }

//   List<Widget> inputOptions() {
//     return [
//       sendButton()
//     ];
//   }

//   String _truncateMessage(String message, int limit) {
//     if (message.length > limit) {
//       return '${message.substring(0, limit)}...';
//     }
//     return message;
//   }

//   Future<String?> _fetchLatestConversationId() async {
//     final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//     final currentUserID = _firebaseAuth.currentUser?.uid;
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(currentUserID)
//         .collection('conversations')
//         .orderBy('createdAt', descending: true)
//         .limit(1)
//         .get();

//     if (querySnapshot.docs.isNotEmpty) {
//       return querySnapshot.docs.first.id;
//     }
//     return null;
//   }

//   void signOut() async {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     authService.signOut();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 184, 60, 22),
//         title: const Text(
//           'Chat',
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             onPressed: signOut,
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             SizedBox(
//               height: 70,
//               child: DrawerHeader(
//                 decoration: const BoxDecoration(
//                   color: Color.fromARGB(255, 184, 60, 22),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'History',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.chat),
//                       color: Colors.white,
//                       onPressed: _startNewConversation,
//                       tooltip: 'Start New Chat',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             FutureBuilder<List<Map<String, dynamic>>>(
//               future: _fetchConversationHistory(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return ListTile(
//                     title: Text('Error: ${snapshot.error}'),
//                   );
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const ListTile(
//                     title: Text('No conversation history'),
//                   );
//                 } else {
//                   final conversationHistories = snapshot.data!;
//                   return Column(
//                     children: conversationHistories.map((conversation) {
//                       return ListTile(
//                         title: Text(conversation['id']),
//                         subtitle: Text(conversation['lastMessage']),
//                         onTap: () {
//                           _navigateToConversation(conversation['id']);
//                         },
//                       );
//                     }).toList(),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//       body: Center(
//         child: StreamBuilder<List<ChatMessage>>(
//           stream: _chatService.getMessages(widget.conversationId),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   const Text('No messages yet.'),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       _sendInitialMessage();
//                       _startNewConversation();
//                     },
//                     child: const Text('Create New Chat'),
//                   ),
//                 ],
//               );
//             } else {
//               final messages = snapshot.data!;
//               return DashChat(
//                 currentUser: _currentUser,
//                 typingUsers: _typingUsers,
//                 inputOptions: InputOptions(
//                   sendOnEnter: true,
//                   alwaysShowSend: true,
//                   trailing: inputOptions(),
//                 ),
//                 messageOptions: MessageOptions(
//                   currentUserContainerColor: Colors.black,
//                   containerColor: const Color.fromARGB(255, 184, 60, 22),
//                   textColor: Colors.white,
//                   messageTextBuilder: (currentMessage, previousMessage, nextMessage) {
//                     if (currentMessage.user.id == _geminiUser.id && nextMessage == null && latestConversationId == widget.conversationId) {
//                       return AnimatedTextKit(
//                         animatedTexts: [
//                           TyperAnimatedText(
//                             currentMessage.text,
//                             speed: const Duration(milliseconds: 9),
//                             textStyle: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                         totalRepeatCount: 1,
//                       );
//                     } else {
//                       return SelectableText(
//                         currentMessage.text,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//                 onSend: (ChatMessage message) {
//                   setState(() {
//                     _messages.insert(0, message);
//                   });
//                   _chatService.saveMessageToFirestore(widget.conversationId, message);
//                   getChatResponse(message);
//                 },
//                 messages: messages,
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
  
//   void _startNewConversation() async {
//     final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//     final currentUserID = _firebaseAuth.currentUser?.uid;
//     final newConversationId = FirebaseFirestore.instance.collection('users').doc(currentUserID).collection('conversations').doc().id;

//     final initialMessage = ChatMessage(
//       text: 'Hello, how can I help you today?',
//       createdAt: DateTime.now(),
//       user: _geminiUser,
//     );
//     await _chatService.saveMessageToFirestore(newConversationId, initialMessage);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => ChatPage(conversationId: newConversationId)),
//     );
//   }
// }
// import 'package:flutter/material.dart';

// class ChatBubble extends StatelessWidget {
//   final String message; // Keep as String

//   const ChatBubble({
//     super.key,
//     required this.message,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Convert the message to RichText with bold formatting
//     final richText = _convertToRichText(message);

//     return Container(
//       padding: const EdgeInsets.all(12.0),
//       decoration: BoxDecoration(
//         color: const Color.fromARGB(255, 184, 60, 22), // Bubble color
//         borderRadius: BorderRadius.circular(8.0), // Bubble border radius
//       ),
//       child: richText, // Use the RichText widget here
//     );
//   }

//   RichText _convertToRichText(String text) {
//     final List<TextSpan> spans = [];
//     final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
//     int lastIndex = 0;

//     for (final match in regex.allMatches(text)) {
//       // Add the text before the match
//       if (match.start > lastIndex) {
//         spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
//       }

//       // Add the bold text
//       spans.add(TextSpan(
//         text: match.group(1),
//         style: TextStyle(fontWeight: FontWeight.bold),
//       ));

//       lastIndex = match.end;
//     }

//     // Add any remaining text after the last match
//     if (lastIndex < text.length) {
//       spans.add(TextSpan(text: text.substring(lastIndex)));
//     }

//     return RichText(
//       text: TextSpan(
//         children: spans, 
//         style: const TextStyle(
//           color: Colors.black, // Text color
//           fontSize: 16.0, // Text size
//         ),
//       ),
//     );
//   }
// }