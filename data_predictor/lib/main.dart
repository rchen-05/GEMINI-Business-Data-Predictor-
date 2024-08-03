import 'dart:convert';
import 'package:data_predictor/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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
      home: const ChatPage(),
    );
  }
}

