import 'package:cloud_firestore/cloud_firestore.dart';
// i want to import my chat_page file

//import dash_chat_2.dart
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatService {
  Future<List<ChatMessage>> getMessagesOnce(String userId, String conversationId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
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
  Future<void> saveMessageToFirestore(String userId, String conversationId, ChatMessage message) async {
  try {
    final firestore = FirebaseFirestore.instance;

    final userConversationRef = firestore.collection('users').doc(userId).collection('conversations').doc(conversationId);
    
    // Ensure the parent document exists
    await userConversationRef.set({
      'conversationId': conversationId,
      'lastUpdated': Timestamp.now(),  // Optionally add metadata like lastUpdated
    }, SetOptions(merge: true));

    // Add the message to the subcollection
    await userConversationRef.collection('messages').add({
      'text': message.text,
      'senderId': message.user.id,
      'createdAt': Timestamp.fromDate(message.createdAt),
    });

    print('Message saved successfully');
  } catch (e) {
    print('Error saving message: $e');
  }
}
  Future<List<QueryDocumentSnapshot>> _fetchConversations() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('conversations').get();
    return querySnapshot.docs;
  }

  Stream<List<ChatMessage>> getMessages(String userId, String conversationId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Provide default values in case of missing fields
          final text = data['text'] ?? '';
          final senderId = data['senderId'] ?? 'unknown';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          return ChatMessage(
            text: text,
            user: ChatUser(id: senderId), // Adjust as needed
            createdAt: createdAt,
          );
        }).toList();
  });
}
}