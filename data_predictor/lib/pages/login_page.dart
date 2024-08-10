
import 'package:data_predictor/components/my_button.dart';
import 'package:data_predictor/components/signin_button.dart';
import 'package:data_predictor/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:data_predictor/components/my_text_field.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // sign in user
  void signIn() async {
    // get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signInWithEmailAndPassword(
          emailController.text, passwordController.text);
    } catch (e) {
      // show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 19, 19, 20),
      body: SafeArea(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 31, 32),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //logo
                  const Icon(
                    Icons.data_usage,
                    size: 100,
                    color: Color.fromARGB(255, 210, 36, 58),
                  ),
                  //empty space
                  const SizedBox(height: 60),
                  //welcome back message
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SFCompactText',
                    ),
                  ),
                  const SizedBox(height: 25),

                  //email textfield
                  MyTextField(
                    hintText: 'Email',
                    controller: emailController,
                    obscureText: false,
                  ),

                  const SizedBox(height: 10),

                  //password textfield
                  MyTextField(
                    hintText: 'Password',
                    controller: passwordController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 25),

                  // sign  in button
                  AnimatedButton(text: 'Log in', onTap: signIn),

                  const SizedBox(height: 50),

                  // not a member? register now
                  Row(
                    children: [
                      const Text('Not a member?',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'SFCompactText')),
                      const SizedBox(width: 4),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Register now',
                            style:  TextStyle(
                              color: Color.fromARGB(255, 210, 36, 58),
                              fontFamily: 'SFCompactText',
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
