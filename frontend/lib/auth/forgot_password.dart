import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String emailOrPhone = _emailOrPhoneController.text.trim();

      // Check if it's a phone number (adjust regex to your phone number format)
      if (RegExp(r'^0[0-9]{9}$').hasMatch(emailOrPhone)) {
        // If phone number starts with 0 and is 10 digits, remove the leading zero
        if (emailOrPhone.startsWith('0') && emailOrPhone.length == 10) {
          emailOrPhone = emailOrPhone.substring(1); // Remove the leading 0
        }
        // Prepend +254 for Kenya
        emailOrPhone = '+254$emailOrPhone';
      }

      var url = Uri.parse(ApiConstants.passwordResetSendEndpoint);
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": emailOrPhone, // Send the processed email/phone number
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reset code sent! Check your email or SMS.')),
        );
        Navigator.pop(context); // Return to the login screen
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reset code!')),
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
        title: const Text('Forgot Password'),
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
                controller: _emailOrPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  helperText: '+254 will be added automatically',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendResetCode,
                      child: Text('Send Reset Code',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
