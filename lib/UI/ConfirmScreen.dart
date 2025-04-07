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
      backgroundColor: Colors.white, // pure white background
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      color: Colors.white,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.help_outline,
                              size: 60,
                              color: Color(Config.COLOR_APP_BAR),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Est-ce bien toi ?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(Config.COLOR_APP_BAR),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(Config.COLOR_APP_BAR),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 160), // reserve space for buttons
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 48, // 48px from bottom
              child: Column(
                children: [
                  ActionButton(
                    icon: Icons.check,
                    text: 'Oui',
                    onPressed: () async {
                      log("Name: $name");
                      log("Dossard: $dossard");

                      var tmp = await NewUserController.getUser(dossard);
                      if (!tmp.hasError && tmp.value != null) {
                        await UserData.saveUser({
                          "id": tmp.value!['id'],
                          "username": tmp.value!['username'],
                          "bib_id": tmp.value!['bib_id'],
                          "event_id": tmp.value!['event_id'],
                        });

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const WorkingScreen()),
                        );
                      } else {
                        showInSnackBar(context, tmp.error ?? "Une erreur inconnue est survenue.");
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  DiscardButton(
                    icon: Icons.close,
                    text: 'Non',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
