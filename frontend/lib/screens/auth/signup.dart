import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/constants.dart'; // Import the constants file

// Sign Up Screen widget
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Validator for phone number
  bool isPhoneNumber(String input) {
    debugPrint('Hello, Flutter! $input');
    final phoneRegex =
        RegExp(r'^[0-9]{9}$'); // Adjust to match your phone format
    return phoneRegex.hasMatch(input);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Get the phone number from the controller
        String phoneNumber = _phoneController.text.trim();

        // If the phone number starts with 0, remove the leading zero
        if (phoneNumber.startsWith('0') && phoneNumber.length == 10) {
          phoneNumber = phoneNumber
              .substring(1); // Remove the first character (the leading 0)
        }

        // Prepend +254 to the cleaned phone number
        String fullPhoneNumber = '+254$phoneNumber';

        var url = Uri.parse(ApiConstants.registerEndpoint);

        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": _nameController.text,
            "phone": fullPhoneNumber, // Send the cleaned phone number with +254
            "password": _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          // Registration successful, navigate to the login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          // Show error message from the server
          String errorMsg = json.decode(response.body)["msg"] ??
              "Registration failed. Please try again.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } on http.ClientException catch (e) {
        // Handle HTTP client errors like connection issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Connection error. Please try again later.$e')),
        );
        debugPrint('ClientException: $e');
      } on FormatException catch (e) {
        // Handle JSON decoding issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Response format error. Please contact support.$e')),
        );
        debugPrint('FormatException: $e');
      } on TimeoutException catch (e) {
        // Handle request timeout errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Request timed out. Please try again later.$e')),
        );
        debugPrint('TimeoutException: $e');
      } catch (e) {
        // Handle any other errors that might occur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'An unexpected error occurred. Please try again later.$e')),
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
        title: const Text('Sign Up'),
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+254 ', // Display +254 prefix in the UI
                  hintText: '7XXXXXXXX', // Guide the user on input format
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !isPhoneNumber(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text('Sign Up',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
