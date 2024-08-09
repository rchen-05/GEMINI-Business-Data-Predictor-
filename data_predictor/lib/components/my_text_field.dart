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
       enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade200),
       ),
       focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
       ),
       fillColor: Colors.grey[300],
       filled: true,
       hintText: hintText,
       hintStyle: const TextStyle(
        color: Colors.grey,
       ),


      ),
    );
  }
}