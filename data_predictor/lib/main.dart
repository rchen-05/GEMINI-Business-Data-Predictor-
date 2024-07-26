import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

  void geminiOutput() async {
    if (_textController.text.isEmpty) {
      return;
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: "AIzaSyAw0O3QQZalaBbdhwaSpYREwBut_kP3wkw");
    final content = [Content.text(_textController.text)];
    final response = await model.generateContent(content);
    print(response.text);

    setState(() {
      stringOutput = response.text!;
    });
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
