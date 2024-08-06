import 'dart:convert';
import 'dart:io' show Platform;
import 'package:data_predictor/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCzBt-9HzTi5eVDKJ728Hha6Em1ebs4fEw',
      appId: '1:408279633368:web:812409e43b1e0a1c54f6ad',
      messagingSenderId: '408279633368',
      projectId: 'data-predictor-32a58',
      authDomain: 'data-predictor-32a58.firebaseapp.com',
      storageBucket: 'data-predictor-32a58.appspot.com',
      measurementId: 'G-XPXXV293SC',
    )
  );
  print('Firebase initialized');
  runApp(MaterialApp(
    home: MyApp(),
  ));
}


class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Data Predictor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 184, 60, 22)),
      ),
      home: SplashScreen()
    );
  }
}
class SplashScreen extends StatelessWidget {
  Future<String> _createNewConversation() async {
    deleteAllMessages('2TVl17L9Riha8KnkAw10');
    final conversationIds = await getAllDocumentIds('conversations');
    await clearDatabase(conversationIds);
    print('Existing conversation IDs: $conversationIds'); // Log the IDs for debugging
    // Create a new conversation ID
    final newConversationId = FirebaseFirestore.instance.collection('conversations').doc().id;
    print('New conversation ID: $newConversationId'); // Log the ID for debugging
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
