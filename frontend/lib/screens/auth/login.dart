import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/home.dart';
import 'package:frontend/screens/auth/signup.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/screens/auth/forgot_password.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus(); // Check if token exists
  }

  // Check if a token is already stored in SharedPreferences
  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null) {
      // If token exists, set it in the TokenProvider and navigate to HomeScreen
      Provider.of<TokenProvider>(context, listen: false).setToken(token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      var phoneNo = _phoneController.text;

      // Check if it's a phone number (adjust regex to your phone number format)
      if (RegExp(r'^0[0-9]{9}$').hasMatch(phoneNo)) {
        // If phone number starts with 0 and is 10 digits, remove the leading zero
        if (phoneNo.startsWith('0') && phoneNo.length == 10) {
          phoneNo = phoneNo.substring(1); // Remove the leading 0
        }
        // Prepend +254 for Kenya
        phoneNo = '+254$phoneNo';
      }
      var url = Uri.parse(ApiConstants.loginEndpoint);
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": phoneNo,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var token = responseData['token'];

        // Save the token in SharedPreferences for persistent login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Save the token in TokenProvider
        Provider.of<TokenProvider>(context, listen: false).setToken(token);

        // Navigate to Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials!')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).textTheme.bodyMedium!.color!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).textTheme.bodyMedium!.color!),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text("Don't have an account? Register here"),
              ),
              // const SizedBox(height: 5),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
