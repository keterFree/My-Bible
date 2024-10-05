import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // Import the Dio package
import 'package:frontend/screens/home.dart';
import 'package:frontend/screens/auth/signup.dart';
import 'package:frontend/constants.dart'; // Ensure you have the correct path for ApiConstants
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

  // Initialize Dio instance
  final Dio _dio = Dio();

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

      try {
        var phoneNo = _phoneController.text;

        // Validate and format the phone number
        if (RegExp(r'^0[0-9]{9}$').hasMatch(phoneNo)) {
          // If phone number starts with 0 and is 10 digits, remove the leading zero
          if (phoneNo.startsWith('0') && phoneNo.length == 10) {
            phoneNo = phoneNo.substring(1); // Remove the leading 0
          }
          // Prepend +254 for Kenya
          phoneNo = '+254$phoneNo';
        }

        // Make the Dio POST request
        Response response = await _dio.post(
          ApiConstants.loginEndpoint,
          data: {
            "phone": phoneNo,
            "password": _passwordController.text,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 10), // Request timeout
          ),
        );

        if (response.statusCode == 200) {
          var responseData = response.data;
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
          // Handle non-200 status codes and show the error message from the server
          String errorMsg =
              response.data["msg"] ?? "Login failed. Please try again.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } on DioException catch (e) {
        // Handle Dio errors like request timeout, server error, etc.
        String errorMessage = '';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timed out. Please try again later.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Response timed out. Please try again later.';
        } else if (e.response != null) {
          // Non-200 status code errors
          errorMessage =
              e.response?.data["msg"] ?? 'Login failed. Please try again.';
        } else {
          errorMessage =
              'An unexpected error occurred. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        debugPrint('DioError: $e');
      } catch (e) {
        // Handle any other unforeseen errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'An unexpected error occurred. Please try again later. $e')),
        );
        debugPrint('Unexpected error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
