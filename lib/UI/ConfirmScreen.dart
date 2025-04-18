import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../API/NewUserController.dart';
import '../Data/UserData.dart';
import 'WorkingScreen.dart';
import 'Components/ActionButton.dart';
import 'Components/DiscardButton.dart';
import '../Utils/config.dart';
import 'Components/TextModal.dart'; // Add this import for showTextModal

class ConfirmScreen extends StatelessWidget {
  final String name;
  final int dossard;

  const ConfirmScreen({super.key, required this.name, required this.dossard});

  void showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String generate4DigitKey(dynamic input, int secretKey, int prime) {
    // Ensure input is int
    int bibInt = input is int ? input : int.tryParse(input.toString()) ?? 0;
    int xored = bibInt ^ secretKey;
    int masked = xored * prime;
    int result = masked % 10000;
    return result.toString().padLeft(4, '0');
  }

  void showConfirmationCodeModal(BuildContext context, dynamic bibId) {
    // Ensure bibId is int
    int bibInt = bibId is int ? bibId : int.tryParse(bibId.toString()) ?? 0;
    final List<TextEditingController> digitControllers = List.generate(4, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
    String? errorText;
    final int secretKey = Config.CONFIRMATION_SECRET_KEY;
    final int prime = Config.CONFIRMATION_PRIME;
    final String prefix = Config.PREFIX_LETTER;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper to get the code from the 4 boxes
            String getCode() => digitControllers.map((c) => c.text).join();

            // Helper to move focus to next/previous box
            void handleInput(int idx, String value) {
              if (value.length == 1 && idx < 3) {
                focusNodes[idx + 1].requestFocus();
              } else if (value.isEmpty && idx > 0) {
                focusNodes[idx - 1].requestFocus();
              }
            }

            return SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 32.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Confirmation requise",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- Show prefix with dash before input boxes ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '$prefix-',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(Config.COLOR_APP_BAR),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        // The 4 input boxes
                        ...List.generate(4, (idx) {
                          return Container(
                            width: 48,
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            child: TextField(
                              controller: digitControllers[idx],
                              focusNode: focusNodes[idx],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Color(Config.COLOR_APP_BAR),
                                letterSpacing: 2.0,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(Config.COLOR_APP_BAR),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(Config.COLOR_APP_BAR),
                                    width: 2,
                                  ),
                                ),
                                errorText: idx == 0 ? errorText : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              onChanged: (value) {
                                if (value.length > 1) {
                                  digitControllers[idx].text = value.substring(0, 1);
                                  digitControllers[idx].selection = TextSelection.fromPosition(
                                    TextPosition(offset: 1),
                                  );
                                }
                                handleInput(idx, value);
                                setState(() {
                                  errorText = null;
                                });
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Code à 4 chiffres.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(Config.COLOR_APP_BAR),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DiscardButton(
                            text: "Annuler",
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ActionButton(
                            text: "OK",
                            onPressed: () async {
                              String code = getCode();
                              String expectedCode = generate4DigitKey(bibInt, secretKey, prime);
                              if (code.length == 4 && code == expectedCode) {
                                Navigator.of(context).pop(); // Close modal
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const WorkingScreen()),
                                );
                              } else {
                                setState(() {
                                  errorText =
                                      "Le code de confirmation n'est pas correct. Merci de vérifier dans vos mails, sinon rapprochez-vous des organisateurs pour en obtenir un.";
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                const SizedBox(height: 160), // Reserve space for buttons
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0, // Align to bottom
              child: SafeArea(
                top: false,
                bottom: true, // ✅ Protect bottom (gesture bar / notch)
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24), // Add nice spacing above gesture area
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

                            // Use bib_id for code generation
                            showConfirmationCodeModal(context, tmp.value!['bib_id']);
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
