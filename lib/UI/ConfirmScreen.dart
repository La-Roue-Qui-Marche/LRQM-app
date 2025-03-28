import 'dart:developer';

import 'package:flutter/material.dart';
import '../API/NewUserController.dart';
import '../Data/UserData.dart';
import 'WorkingScreen.dart';
import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'Components/DiscardButton.dart';

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
      backgroundColor: Colors.white, // Set background color to white
      body: Stack(
        children: [
          SingleChildScrollView(
            // Make the full page scrollable
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0), // Add margin
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: <Widget>[
                  const SizedBox(height: 90), // Add margin at the top
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.12,
                      child: const Image(
                          image: AssetImage('assets/pictures/question.png')),
                    ),
                  ),
                  const SizedBox(height: 70), // Add margin after the logo
                  InfoCard(
                    logo: Icon(Icons.face),
                    title: "Est-ce bien toi ?",
                    data: name,
                    actionItems: const [],
                  ),
                  const SizedBox(
                      height:
                          100), // Add more margin at the bottom to allow more scrolling
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter, // Fix the buttons at the bottom
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10.0, vertical: 20.0), // Add padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(
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
                          "username":
                              tmp.value!['username'], // Use null-aware operator
                          "bib_id":
                              tmp.value!['bib_id'], // Use null-aware operator
                          "event_id":
                              tmp.value!['event_id'], // Use null-aware operator
                        });

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return const WorkingScreen();
                          }),
                        );
                      } else {
                        showInSnackBar(
                            context, tmp.error ?? "An unknown error occurred.");
                      }
                    },
                  ),
                  const SizedBox(height: 10), // Add space between buttons
                  DiscardButton(
                    icon: Icons.close, // Add icon to "Non" button
                    text: 'Non',
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
