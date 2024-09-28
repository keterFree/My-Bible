import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/token_provider.dart';
import 'package:frontend/screens/baseScaffold.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Logger _logger = Logger();
  String userName = '';
  String userContacts = '';
  String userId = '';
  bool isEditingName = false;
  bool isEditingPhone = false;
  bool isChangingPassword = false;
  final _nameFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _logger = Logger();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final token = Provider.of<TokenProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('Token not found or expired');
      }

      final jwt = JWT.decode(token);
      setState(() {
        userName = jwt.payload['user']['name'] ?? 'User';
        userContacts = jwt.payload['user']['phone'] ?? '';
        userId = jwt.payload['user']['id'] ?? 'User';
      });

      var url = Uri.parse(ApiConstants.accDetailsEndpoint);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final user = json.decode(response.body);
        setState(() {
          userName = user['name'] ?? userName;
          userContacts = user['phone'] ?? userContacts;
          _nameController.text = userName;
          _phoneController.text = userContacts.replaceFirst('+254', '');
        });
        _logger.i('Fetched user details from: $url');
      } else {
        _logger.e('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching user details: $e');
    }
  }

  Future<void> _updateUserDetails(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _logger.e("Token not found or expired");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please log in again.'),
        ),
      );
      return;
    }

    try {
      var url = Uri.parse(ApiConstants.accDetailsEndpoint);
      _logger.i("API URL: $url");

      String formattedPhoneNumber = userContacts;
      Map<String, dynamic> requestBody = {
        'name': isEditingName ? _nameController.text : userName,
        'phone': isEditingPhone ? formattedPhoneNumber : userContacts,
      };

      if (isChangingPassword && _newPasswordController.text.isNotEmpty) {
        requestBody['oldPassword'] = _oldPasswordController.text;
        requestBody['password'] = _newPasswordController.text;
      }

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var token = responseData['token'];

        // Save the token in SharedPreferences for persistent login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        setState(() {
          userName = _nameController.text;
          userContacts = formattedPhoneNumber;
          isEditingName = false;
          isEditingPhone = false;
          isChangingPassword = false;
          _clearFormFields();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['msg'])),
        );
      } else {
        var decodedResponse = json.decode(response.body);
        _logger.e('Failed to update user details: ${decodedResponse["msg"]}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update details\n${decodedResponse["msg"] ?? "Unknown error"}',
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  void _clearFormFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Account",
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display user details
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 60),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userContacts,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Clickable tile for editing name
              ListTile(
                leading: Icon(
                  isEditingName ? Icons.cancel : Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(isEditingName ? 'Cancel' : 'Edit Name',
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  setState(() {
                    isEditingName = !isEditingName;
                    isEditingPhone = false;
                    isChangingPassword = false;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Form for editing name
              if (isEditingName)
                Form(
                  key: _nameFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: Theme.of(context).textTheme.bodyMedium,
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('Save',
                            style: Theme.of(context).textTheme.bodySmall),
                        onPressed: () => _updateUserDetails(_nameFormKey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Clickable tile for editing phone number
              ListTile(
                leading: Icon(
                  isEditingPhone ? Icons.cancel : Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(isEditingPhone ? 'Cancel' : 'Edit Phone Number',
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  setState(() {
                    isEditingPhone = !isEditingPhone;
                    isEditingName = false;
                    isChangingPassword = false;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Form for editing phone
              if (isEditingPhone)
                Form(
                  key: _phoneFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: Theme.of(context).textTheme.bodyMedium,
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (without +254)',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number cannot be empty';
                          }
                          if (value.length != 9 && value.length != 10) {
                            return 'Phone number must be 9 or 10 digits';
                          }
                          if (value.length == 10 && !value.startsWith('0')) {
                            return 'Phone number must start with 0 if 10 digits long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('Save',
                            style: Theme.of(context).textTheme.bodySmall),
                        onPressed: () => _updateUserDetails(_phoneFormKey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Clickable tile for changing password
              ListTile(
                leading: Icon(
                  isChangingPassword ? Icons.cancel : Icons.lock,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(isChangingPassword ? 'Cancel' : 'Change Password',
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  setState(() {
                    isChangingPassword = !isChangingPassword;
                    isEditingName = false;
                    isEditingPhone = false;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Form for changing password
              if (isChangingPassword)
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: Theme.of(context).textTheme.bodyMedium,
                        controller: _oldPasswordController,
                        decoration:
                            const InputDecoration(labelText: 'Old Password'),
                        obscureText: true,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter your old password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: Theme.of(context).textTheme.bodyMedium,
                        controller: _newPasswordController,
                        decoration:
                            const InputDecoration(labelText: 'New Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: Theme.of(context).textTheme.bodyMedium,
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                            labelText: 'Confirm New Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('Save',
                            style: Theme.of(context).textTheme.bodySmall),
                        onPressed: () => _updateUserDetails(_passwordFormKey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
