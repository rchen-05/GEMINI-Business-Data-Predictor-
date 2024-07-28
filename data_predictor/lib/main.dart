import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String stringOutput = "Text Output";

  final TextEditingController _textController = TextEditingController();

  Future<void> geminiOutput() async {
    if (_textController.text.isEmpty) {
      return;
    }

    final csvContent = _textController.text;
    final url = 'http://127.0.0.1:5001/get_regressor';
    // Flask server URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"csv_content": csvContent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stringOutput = data['model'];
        });
      } else {
        setState(() {
          stringOutput = 'Error: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        stringOutput = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("App"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  stringOutput,
                ),
              ),
            ),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "Enter text here",
              ),
              onChanged: (value) {
                setState(() {
                  print(_textController.text);
                });
              },
            ),
            ElevatedButton(
              onPressed: geminiOutput,
              child: Text("Gemini API"),
            ),
          ],
        ),
      ),
    );
  }
}
