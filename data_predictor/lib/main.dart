import 'dart:convert';
import 'dart:js_interop_unsafe';
import 'package:data_predictor/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Clear existing conversations and messages
    await _clearFirestoreData();

    // Create a new conversation ID
    final newConversationId = FirebaseFirestore.instance.collection('conversations').doc().id;
    print('New conversation ID: $newConversationId'); // Log the ID for debugging
    return newConversationId;
  }

  Future<void> _clearFirestoreData() async {
    final fireStore = FirebaseFirestore.instance;
    final collectionRef = fireStore.collection('conversations');
    final snapshot = await collectionRef.get();
    final batch = fireStore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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

