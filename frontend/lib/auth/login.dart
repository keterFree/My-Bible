import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:frontend/lit_Screens/home.dart';
import 'package:frontend/auth/signup.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/auth/forgot_password.dart';
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
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null) {
      Provider.of<TokenProvider>(context, listen: false).setToken(token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String phoneNo = _phoneController.text.trim();
        if (RegExp(r'^0[0-9]{9}$').hasMatch(phoneNo)) {
          phoneNo = '+254${phoneNo.substring(1)}';
        }

        Response response = await _dio.post(
          ApiConstants.loginEndpoint,
          data: {"phone": phoneNo, "password": _passwordController.text},
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          var token = response.data['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          Provider.of<TokenProvider>(context, listen: false).setToken(token);

          _phoneController.clear();
          _passwordController.clear();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showError(response.data["msg"] ?? "Login failed. Please try again.");
        }
      } on DioException catch (e) {
        _handleDioError(e);
      } catch (e) {
        _showError('An unexpected error occurred. Please try again. $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDioError(DioException e) {
    String errorMessage = '';
    if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timed out. Please try again later.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Response timed out. Please try again later.';
    } else if (e.response != null) {
      errorMessage = e.response?.data["msg"] ?? 'Login failed.';
    } else {
      errorMessage = 'An unexpected error occurred.';
    }
    _showError(errorMessage);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    String iconImage =
        isDarkMode ? 'assets/images/iconnn.png' : 'assets/images/icon.png';

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width / 5,
                    backgroundColor: Colors.transparent,
                    child: Image.asset(iconImage, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodySmall,
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter phone number'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    style: Theme.of(context).textTheme.bodySmall,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter password'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      elevatedB("Login", _login),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      elevatedB(
                          "Forgot Password?",
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()),
                              )),
                      const SizedBox(width: 20),
                      elevatedB(
                          "Register",
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpScreen()),
                              )),
                    ],
                  ),
                ],
              ),
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
