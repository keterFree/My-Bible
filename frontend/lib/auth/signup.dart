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

  // Dispose controllers to avoid memory leaks
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate Kenyan phone numbers and allow spaces or hyphens
  bool isPhoneNumber(String input) {
    final phoneRegex = RegExp(r'^[0-9\s\-]{9,10}$');
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
        phoneNumber =
            phoneNumber.replaceAll(RegExp(r'\s+|-'), ''); // Clean input

        // Remove leading zero if present and prepend +254
        if (phoneNumber.startsWith('0')) {
          phoneNumber = phoneNumber.substring(1);
        }
        String fullPhoneNumber = '+254$phoneNumber';
        print(
            " ${ApiConstants.registerEndpoint} \n name: ${_nameController.text},\n phone: $fullPhoneNumber,\npassword: ${_passwordController.text},\n");
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
          bool error = response.data["status"] == "400";
          if (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data["msg"])),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          String errorMsg = response.data["msg"] ?? "Registration failed.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
          print("else error : $errorMsg");
        }
      } on DioException catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        // print(e.message);
        print("Dio error : ${e.message}");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
        print(e);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    String iconImage =
        isDarkMode ? 'assets/images/iconnn.png' : 'assets/images/icon.png';

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width / 5,
                  backgroundColor: Colors.transparent,
                  child: Image.asset(iconImage, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  style: Theme.of(context).textTheme.bodySmall,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: Theme.of(context).textTheme.bodySmall,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    prefixText: '+254 ',
                    hintText: '7XXXXXXXX',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !isPhoneNumber(value)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: Theme.of(context).textTheme.bodySmall,
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a password'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: Theme.of(context).textTheme.bodySmall,
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Confirm your password'
                      : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    elevatedB(
                      "Login",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : elevatedB('Sign Up', _register),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton elevatedB(String label, VoidCallback method) {
    return ElevatedButton(
      onPressed: _isLoading ? null : method,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        // Add any default style properties here
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // example padding
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label),
    );
  }
}
