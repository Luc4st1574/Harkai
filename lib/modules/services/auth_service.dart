// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harkai/home.dart';
import 'package:harkai/login.dart';


class AuthService {

  Future<void> signup({
    required String email,
    required String password,
    required String userName, // Add the username parameter
    required BuildContext context,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's displayName with the username
      User? user = userCredential.user;
      if (user != null) {
        await user.updateProfile(displayName: userName);
        await user.reload(); // Refresh the user to reflect changes
        user = FirebaseAuth.instance.currentUser; // Reload the user data
      }

      // Add a short delay before navigating to home
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to the Home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Home(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      String message = "";

      // Handle specific errors
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'An error occurred. Please try again.';
      }

      // Display error message with Fluttertoast
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      // Handle other exceptions
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Add a short delay before navigating to home
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to the Home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Home(),
        ),
      );
      
    } on FirebaseAuthException catch (e) {
      String message = "";
      
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'An error occurred. Please try again.';
      }
      
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }


  Future<void> signout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Ensure that the current context is replaced by the Login page after signout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,  // This removes all previous routes in the stack
      );
    } catch (e) {
      // Handle any errors that might occur during signout
      Fluttertoast.showToast(
        msg: 'Error signing out. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

}
