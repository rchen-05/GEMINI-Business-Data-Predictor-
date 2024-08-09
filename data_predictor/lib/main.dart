
import 'package:data_predictor/pages/home_page.dart';
import 'package:data_predictor/services/auth/auth_gate.dart';
import 'package:data_predictor/services/auth/auth_service.dart';
import 'package:data_predictor/services/auth/login_or_register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';


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
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MyApp(),
    ),
  );
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
      home: AuthGate(),
    );
  }
}

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
