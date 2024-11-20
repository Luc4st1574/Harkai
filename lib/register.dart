// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_service.dart';
import 'home.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Variable to track password visibility

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      print('Existing Firebase apps: ${Firebase.apps}');
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not initialized. Check main.dart setup.');
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } catch (e) {
      print('Error during Google Sign-In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  Future<void> _handleEmailSignup(BuildContext context) async {
  try {
    await AuthService().signup(
      userName: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      context: context,
    );

    // Navigate to Home after successful signup
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signup successful!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to sign up: $e')),
    );
  }
}


  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundImage(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 30),
                    const Text(
                      'REGISTER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF57D463),
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 25),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 25),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF57D463),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 45),
                    _buildSignupButton(context),
                    const SizedBox(height: 25),
                    _buildGoogleSignupButton(context),
                    const SizedBox(height: 30),
                    _buildSignInLink(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 150,
      height: 150,
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async => await _handleEmailSignup(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF011935),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'SIGN UP',
          style: TextStyle(fontSize: 18, color: Color(0xFF57D463)),
        ),
      ),
    );
  }

  Widget _buildGoogleSignupButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleGoogleSignIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 24,
        ),
        label: const Text(
          'Sign up with Google',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? "),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Text(
            'LOG IN',
            style: TextStyle(color: Color(0xFF57D463)),
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF57D463)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF57D463)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF57D463)),
        ),
        suffixIcon: suffixIcon,
      ),
      keyboardAppearance: Brightness.dark,
      cursorColor: const Color(0xFF57D463),
    );
  }
}
