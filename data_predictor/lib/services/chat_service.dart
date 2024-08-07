import 'package:cloud_firestore/cloud_firestore.dart';
// i want to import my chat_page file

//import dash_chat_2.dart
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:data_predictor/models/message.dart';
import 'package:data_predictor/pages/chat_page2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService {
  
  Future<List<ChatMessage>> getMessagesOnce(String conversationId) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;

    

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ChatMessage(
        text: data['text'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        user: ChatUser(id: data['senderId']), // Adjust based on your ChatUser structure
      );
    }).toList();
  }
  Future<void> saveMessageToFirestore(String conversationId,String sender, String message) async {
  try {
    final _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;
    final Timestamp timestamp = Timestamp.now();

    

    Message newMessage = Message(
      text: message,
      sender: sender,
      timestamp: timestamp
    );

    if (currentUserID == null) {
      throw Exception("No user logged in");
    }

    final userConversationRef = _firestore.collection('users').doc(currentUserID).collection('conversations').doc(conversationId);

    // Ensure the parent document exists
    await userConversationRef.set({
      'conversationId': conversationId,
      'lastUpdated': Timestamp.now(),  // Optionally add metadata like lastUpdated
    }, SetOptions(merge: true));

    // Add the message to the subcollection
    await userConversationRef.collection('messages').add({
      'text': newMessage.text,
      'sender': newMessage.sender,
      'timestamp': newMessage.timestamp,
    });

    print('Message saved successfully');
  } catch (e) {
    print('Error saving message: $e');
  }
}
  Stream<QuerySnapshot> getMessages(String conversationId) {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final currentUserID = _firebaseAuth.currentUser?.uid;

    if (currentUserID == null) {
      throw Exception("No user logged in");
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  

  
}