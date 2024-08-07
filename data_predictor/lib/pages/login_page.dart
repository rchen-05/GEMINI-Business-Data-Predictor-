import 'package:data_predictor/components/my_button.dart';
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

class _LoginPageState extends State<LoginPage>{
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
 // sign in user
  void signIn() async {
    // get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    try{
      await authService.signInWithEmailAndPassword(emailController.text, passwordController.text);
    }
    catch (e){
      // show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                const Icon(
                  Icons.data_usage,
                  size: 100,
                  color: Colors.blue,
                ),
                //welcome back message
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 16,
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
                MyButton(
                  onTap: signIn,
                   text: 'Sign in'
                ),

                const SizedBox(height: 50),
            
                // not a member? register now
                 Row(
                  children: [
                    const Text('Not a member?'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
    );
  } 
}