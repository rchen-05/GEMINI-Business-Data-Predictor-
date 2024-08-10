import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;

  const MyTextField({
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
      decoration: InputDecoration(
        labelText: hintText,  // This sets the hint text as a floating label
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'SFCompactText',
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,  // Automatically floats the label
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        fillColor: const Color.fromARGB(255, 30, 31, 32),
        filled: true,
      ),
      style: const TextStyle(
        color: Colors.white,  // Text color inside the text field
      ),
    );
  }
}