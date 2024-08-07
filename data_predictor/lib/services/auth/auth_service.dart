import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  //sign in 
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async{
    try{
      //sign in 
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      _fireStore.collection('users').doc(_firebaseAuth.currentUser!.uid).set({
      'email': email,
      'uid': _firebaseAuth.currentUser!.uid,
      }, SetOptions(merge: true));


      return userCredential;
    } 
    // catch any errors
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //create new user
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async{
    try{
      //create new user
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      //after creating user, create new document for the user in the users collection
    _fireStore.collection('users').doc(_firebaseAuth.currentUser!.uid).set({
      'email': email,
      'uid': _firebaseAuth.currentUser!.uid,
    });
      return userCredential;
    } 
    // catch any errors
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }


  //sign out 
  Future<void> signOut() async{
    return await FirebaseAuth.instance.signOut();
  }

}