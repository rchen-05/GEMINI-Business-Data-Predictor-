import 'package:data_predictor/pages/home_page.dart';
import 'package:data_predictor/services/auth/login_or_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            final User? user = snapshot.data;
            if (user != null) {
              final userId = user.uid;
              return NewHomePage(userId: userId); // Pass the userId to HomePage
            } else {
              return const LoginOrRegister();
            }
          }
          // User is not logged in
          else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}