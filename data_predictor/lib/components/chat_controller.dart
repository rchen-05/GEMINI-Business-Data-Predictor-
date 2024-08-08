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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.black, // Set the text color to grey
      ),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide:  BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide:  BorderSide(color: Colors.grey.shade200),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide:  BorderSide(color: Colors.grey.shade200),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide:  BorderSide(color: Colors.grey.shade200),
        ),
        fillColor: Colors.grey[200],
        filled: true,
        hoverColor: Colors.transparent, // Disable hover effect
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey, // Set the hint text color to grey
        ),
      ),
      cursorColor: Colors.grey, // Set the cursor color to grey
    );
  }
}
