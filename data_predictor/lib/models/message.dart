import 'package:cloud_firestore/cloud_firestore.dart';

class Message {         
  final String text;        // The content of the message
  final Timestamp timestamp; // Timestamp when the message was created
  final String sender;

  Message({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  // Convert the Message instance to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'timestamp': timestamp,
    };
  }
  
}