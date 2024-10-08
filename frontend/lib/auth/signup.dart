import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/constants.dart'; // Import the constants file

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

  Dio dio = Dio(); // Create a Dio instance

  bool isPhoneNumber(String input) {
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
        String phoneNumber = _phoneController.text.trim();

        // If the phone number starts with 0, remove the leading zero
        if (phoneNumber.startsWith('0') && phoneNumber.length == 10) {
          phoneNumber = phoneNumber
              .substring(1); // Remove the first character (the leading 0)
        }

        // Prepend +254 to the cleaned phone number
        String fullPhoneNumber = '+254$phoneNumber';

        var response = await dio.post(
          ApiConstants.registerEndpoint,
          data: {
            "name": _nameController.text,
            "phone": fullPhoneNumber,
            "password": _passwordController.text,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          // Registration successful, navigate to the login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          String errorMsg =
              response.data["msg"] ?? "Registration failed. Please try again.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } on DioException catch (e) {
        // Handle Dio errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Connection error. Please try again later. ${e.message}')),
        );
        debugPrint('DioException: ${e.message}');
      } catch (e) {
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
                  hintText: '7XXXXXXXX',
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
