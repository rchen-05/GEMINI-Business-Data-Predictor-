
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_predictor/pages/chat_page.dart';
import 'package:flutter/material.dart';

Future<List<String>> getAllDocumentIds(String collectionPath) async {
  const batchSize = 100; // Adjust batch size if needed
  final documentIds = <String>[];
  bool hasMore = true;
  DocumentSnapshot? lastDoc;

  while (hasMore) {
    Query query = FirebaseFirestore.instance.collection(collectionPath).limit(batchSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      hasMore = false;
    } else {
      for (var doc in snapshot.docs) {
        documentIds.add(doc.id);
      }
      lastDoc = snapshot.docs.last;
    }
  }

  return documentIds;
}
Future<void> clearDatabase(List<String> conversationIDs) async {
  for (var id in conversationIDs){
    await deleteAllMessages(id);
    await deleteConversation(id);
  }
}
Future<void> deleteConversation(String conversationId) async {
  try {
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    // Delete the conversation document
    await conversationRef.delete();
    print('Conversation deleted successfully.');
  } catch (e) {
    print('Error deleting conversation: $e');
  }
}
Future<void> deleteAllMessages(String conversationId) async {
  try {
    final messagesCollectionRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    // Fetch all documents in the Messages subcollection
    final snapshot = await messagesCollectionRef.get();

    // Check if there are any documents
    if (snapshot.docs.isEmpty) {
      print('No messages to delete.');
      return;
    }

    // Delete each document
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch
    await batch.commit();
    print('All messages deleted successfully.');
  } catch (e) {
    print('Error deleting messages: $e');
  }
}






class HomePage extends StatelessWidget {
  Future<String> _createNewConversation() async {
    final conversationIds = await getAllDocumentIds('conversations');
    await clearDatabase(conversationIds);
    final newConversationId = FirebaseFirestore.instance.collection('conversations').doc().id;
    return newConversationId;
  }

  

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _createNewConversation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final conversationId = snapshot.data!;
          // Navigate to ChatPage with the new conversation ID
          return ChatPage(conversationId: conversationId);
        }
      },
    );
  }
}