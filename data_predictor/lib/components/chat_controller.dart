import 'package:flutter/material.dart';

class ChatController extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;

  const ChatController({
    super.key,
    required this.hintText,
    required this.controller,
    required this.obscureText,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white, // Set the text color to grey
        ),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:  const BorderSide(color: Color.fromARGB(255,30,31,32)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color.fromARGB(255,30,31,32)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:  const BorderSide(color: Color.fromARGB(255,30,31,32)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:  const BorderSide(color: Color.fromARGB(255,30,31,32)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:  const BorderSide(color: Color.fromARGB(255,30,31,32)),
          ),
          fillColor: const Color.fromARGB(255,30,31,32),
          filled: true,
          hoverColor: Colors.transparent, // Disable hover effect
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey, // Set the hint text color to grey
          ),
        ),
        cursorColor: Colors.grey, // Set the cursor color to grey
      ),
    );
  }
}
