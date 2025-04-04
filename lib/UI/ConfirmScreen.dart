import 'dart:developer';

import 'package:flutter/material.dart';
import '../API/NewUserController.dart';
import '../Data/UserData.dart';
import 'WorkingScreen.dart';
import 'Components/ActionButton.dart';
import 'Components/DiscardButton.dart';
import '../Utils/config.dart';

class ConfirmScreen extends StatelessWidget {
  final String name;
  final int dossard;

  const ConfirmScreen({super.key, required this.name, required this.dossard});

  void showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND), // Set background color to COLOR_BACKGROUND
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 10,
              color: Colors.white, // Ensure the card background is white
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.verified_user, // Suggested modern icon
                        size: 80,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Est-ce bien toi ?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24, // Make the name more prominent
                        fontWeight: FontWeight.bold,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Align "Oui" to the right
                      children: [
                        Expanded(
                          child: DiscardButton(
                            icon: Icons.close, // Add icon to "Non" button
                            text: 'Non',
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16), // Add spacing between buttons
                        Expanded(
                          child: ActionButton(
                            icon: Icons.check, // Add icon to "Oui" button
                            text: 'Oui',
                            onPressed: () async {
                              log("Name: $name");
                              log("Dossard: $dossard");

                              var tmp = await NewUserController.getUser(dossard);
                              if (!tmp.hasError && tmp.value != null) {
                                // Save user data in UserData
                                await UserData.saveUser({
                                  "id": tmp.value!['id'], // Use null-aware operator
                                  "username": tmp.value!['username'], // Use null-aware operator
                                  "bib_id": tmp.value!['bib_id'], // Use null-aware operator
                                  "event_id": tmp.value!['event_id'], // Use null-aware operator
                                });

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return const WorkingScreen();
                                  }),
                                );
                              } else {
                                showInSnackBar(context, tmp.error ?? "An unknown error occurred.");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
