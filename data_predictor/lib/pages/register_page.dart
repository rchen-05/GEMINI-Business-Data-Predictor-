import 'package:data_predictor/components/my_button.dart';
import 'package:data_predictor/components/signin_button.dart';
import 'package:data_predictor/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:data_predictor/components/my_text_field.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }
    // get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signUpWithEmailAndPassword(
        emailController.text, 
        passwordController.text,
      );
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
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
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
                  //welcome message
                  const Text(
                    'Let\'s create an account for you!',
                    style: TextStyle(
                      fontSize: 22,
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

                  const SizedBox(height: 10),

                  //confirm password textfield
                  MyTextField(
                    hintText: 'Confirm Password',
                    controller: confirmPasswordController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 25),

                  // sign up button
                  AnimatedButton(text: 'Sign up', onTap: signUp),

                  const SizedBox(height: 50),

                  // already a member? login now
                  Row(
                    children: [
                      const Text(
                        'Already a member?',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SFCompactText',
                        ),
                      ),
                      const SizedBox(width: 4),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Login now',
                            style: TextStyle(
                              color: Color.fromARGB(255, 210, 36, 58),
                              fontFamily: 'SFCompactText',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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