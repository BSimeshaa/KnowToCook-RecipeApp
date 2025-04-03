import 'package:flutter/material.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/login_page.dart';
import 'package:knowtocook/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeBackPage extends StatefulWidget {
  const WelcomeBackPage({super.key, required String userId});

  @override
  _WelcomeBackPageState createState() => _WelcomeBackPageState();
}

class _WelcomeBackPageState extends State<WelcomeBackPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      String? result = await Auth().signIn(email, password);
      setState(() => isLoading = false);

      if (result == "success") {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User not found"), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? "Login Failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _signInWithGoogle() async {
    String? result = await Auth().signInWithGoogle();
    if (result == "success") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage(userId: '',)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Google Sign-In Failed"), backgroundColor: Colors.red),
      );
    }
  }

  void _forgotPassword() async {
    if (emailController.text.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent!"), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter your email to reset password"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome Back!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Please enter your details here", style: TextStyle(color: Colors.grey)),

              SizedBox(height: 30),
              // Email input
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: "Email Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (value) => value!.isEmpty || !value.contains('@') ? "Enter a valid email" : null,
              ),

              SizedBox(height: 20),
              // Password input
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  hintText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (value) => value!.isEmpty ? "Enter your password" : null,
              ),

              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text("Forgot password?", style: TextStyle(color: Colors.blue)),
                ),
              ),

              // Login button
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Login", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              SizedBox(height: 20),
              Text("Or continue with", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Icon(Icons.g_mobiledata, color: Colors.white),
                label: Text("Google", style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don’t have an account? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    ),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
