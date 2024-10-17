import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/chat_Screens/direct.dart';
import 'package:frontend/constants.dart';

class UsersListScreen extends StatelessWidget {
  final List<dynamic> users;
  final String currentUser; // Add a parameter for the current user

  const UsersListScreen(
      {super.key, required this.users, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Filter out the current user from the list
    final List<dynamic> filteredUsers = users.where((user) {
      return user['_id'] != currentUser;
    }).toList();

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Container(
            decoration: BoxDecoration(
              // color: Colors.white.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .color!
                      .withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 3), // Changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.person_2_rounded,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(
                filteredUsers[index]['name'],
                style: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(
                      fontWeight: FontWeight.bold, // Make the title bold
                      fontSize: 16, // Set font size for title
                    ),
              ),
              subtitle: Text(
                filteredUsers[index]['phone'],
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 12,
                    ),
              ),
              trailing: Text(
                filteredUsers[index]["tier"],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700], // Small trailing text with a color
                ),
              ),
              onTap: () async {
                // Replace with logic to get or create the DirectMessage ID
                final Map? directMessageId = await fetchOrCreateDirectMessageId(
                    currentUser, filteredUsers[index]['_id']);

                print(directMessageId);

                if (directMessageId != null) {
                  // Navigate to DirectMessageScreen with the correct directMessageId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectMessageScreen(
                        user: filteredUsers[index],
                        directMessage:
                            directMessageId, // Pass the directMessageId
                      ),
                    ),
                  );
                } else {
                  // Display an error message if directMessageId is null
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to create or fetch direct message ID.'),
                    ),
                  );
                }
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map?> fetchOrCreateDirectMessageId(
      String currentUser, String filteredUser) async {
    try {
      // Initialize Dio with base URL and headers if needed
      Dio dio = Dio();

      // Create the POST request body
      final Map<String, dynamic> body = {
        'currentUser': currentUser,
        'otherUser': filteredUser,
      };

      // Send the POST request
      final response = await dio.post(
        ApiConstants.directMessageEndpoint,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Check for a successful response
      if (response.statusCode == 200) {
        final data = response.data;
        print("*****data*****\n${response.data}");
        return data; // Return the direct message ID
      } else {
        print(
            'Failed to fetch or create direct message: ${response.statusCode} - ${response.data}');
        return null;
      }
    } on DioError catch (dioError) {
      if (dioError.response != null) {
        // DioError with server response
        print(
            'DioError: ${dioError.response?.data} - Status: ${dioError.response?.statusCode}');
      } else {
        // DioError without response (like a network error)
        print('DioError: ${dioError.message}');
      }
      return null;
    } catch (e) {
      // Handle other types of exceptions
      print('Unexpected error occurred: $e');
      return null;
    }
  }
}
