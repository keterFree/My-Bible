import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/lit_Screens/base_scaffold.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';
import '../constants.dart'; // Ensure ApiConstants.group is defined

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isRestricted = false;
  bool _isLoading = false;

  final Dio _dio = Dio();

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final token = Provider.of<TokenProvider>(context, listen: false).token;
    if (token == null) {
      _showSnackbar('Authentication required');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _dio.post(
        ApiConstants.group,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'restricted': _isRestricted,
        },
      );

      if (response.statusCode == 201) {
        _showSnackbar('Group created successfully');
        Navigator.pop(context); // Navigate back to the previous screen
      } else {
        _handleError(response);
      }
    } on DioException catch (e) {
      _handleDioException(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleError(Response response) {
    final errorMessage = response.data['message'] ?? 'Failed to create group';
    _showSnackbar('Error: $errorMessage');
  }

  void _handleDioException(DioException e) {
    print(e);
    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server took too long to respond. Try again later.';
        break;
      case DioExceptionType.badResponse:
        message = 'An error occurred.';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
      default:
        message = 'Unexpected error: ${e.message}';
        break;
    }
    _showSnackbar(message);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Create Group',
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: Theme.of(context).textTheme.bodyLarge),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    inactiveTrackColor: Colors.green,
                    title: Text(
                      'Restricted Group',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    value: _isRestricted,
                    onChanged: (value) {
                      setState(() {
                        _isRestricted = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _createGroup,
                          child: const Text('Create Group'),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
