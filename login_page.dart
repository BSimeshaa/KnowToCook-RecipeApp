import 'package:flutter/material.dart';
import 'package:knowtocook/pages/account_creation.dart';
import 'package:knowtocook/auth.dart';
import 'package:knowtocook/pages/welcome_back_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isPasswordValid = false;
  bool hasNumber = false;
  bool isLoading = false;

  void _validatePassword(String password) {
    setState(() {
      isPasswordValid = password.length >= 6;
      hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      String? result = await Auth().signUp(email, password);

      setState(() => isLoading = false);

      if (result == "success") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AccountCreationPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? "Sign-Up Failed"), backgroundColor: Colors.red),
        );
      }
    }
  }


  void _navigateToLogin() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => WelcomeBackPage(userId: '',)));
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
              Text("Welcome!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Please enter your details here", style: TextStyle(color: Colors.grey)),

              SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: "Email Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? "Enter a valid email" : null,
              ),

              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  hintText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onChanged: _validatePassword,
                validator: (value) =>
                !isPasswordValid || !hasNumber ? "Password must be 6+ characters and contain a number" : null,
              ),

              SizedBox(height: 10),
              Row(
                children: [
                  Icon(isPasswordValid ? Icons.check_circle : Icons.cancel, color: isPasswordValid ? Colors.green : Colors.grey),
                  SizedBox(width: 5),
                  Text("At least 6 characters", style: TextStyle(color: isPasswordValid ? Colors.black : Colors.grey)),
                ],
              ),
              Row(
                children: [
                  Icon(hasNumber ? Icons.check_circle : Icons.cancel, color: hasNumber ? Colors.green : Colors.grey),
                  SizedBox(width: 5),
                  Text("Contains a number", style: TextStyle(color: hasNumber ? Colors.black : Colors.grey)),
                ],
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: _navigateToLogin,
                    child: Text(
                      "Log In",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
