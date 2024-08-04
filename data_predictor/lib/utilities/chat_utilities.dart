import 'package:cloud_firestore/cloud_firestore.dart';
// i want to import my chat_page file

//import dash_chat_2.dart
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatService {
  Future<List<ChatMessage>> getMessagesOnce(String conversationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ChatMessage(
        text: data['text'],
        user: ChatUser(id: data['senderId'], firstName: 'Name', lastName: ''),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }
  Future<void> saveMessageToFirestore(String conversationId, ChatMessage message) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
            'text': message.text,
            'senderId': message.user.id,
            'createdAt': Timestamp.fromDate(message.createdAt),
          });
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              text: data['text'],
              user: ChatUser(id: data['senderId'], firstName: 'Name', lastName: ''),
              createdAt: (data['createdAt'] as Timestamp).toDate(),
            );
          }).toList();
        });
  }
}