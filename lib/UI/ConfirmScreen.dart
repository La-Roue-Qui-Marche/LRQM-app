// ignore_for_file: prefer_const_declarations, prefer_const_constructors

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../Data/UserData.dart';
import 'WorkingScreen.dart';
import 'Components/button_action.dart';
import 'Components/button_discard.dart';
import '../Utils/config.dart';

class ConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ConfirmScreen({super.key, required this.userData});

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

  void showConfirmationCodeModal(BuildContext context, dynamic bibId, {Map<String, dynamic>? userData}) {
    int bibInt = bibId is int ? bibId : int.tryParse(bibId.toString()) ?? 0;
    final int secretKey = Config.confirmationSecretKey;
    final int prime = Config.confirmationPrime;
    final String prefix = Config.confirmationPrefixLetter;
    final TextEditingController pinController = TextEditingController();
    final FocusNode pinFocusNode = FocusNode();

    String? errorText;
    bool showRetry = false;

    // Pin theme as in the provided style
    final Color pinBorderColor = Color(Config.accentColor); // Use your app's button color

    const errorColor = Color.fromRGBO(255, 234, 238, 1);
    final Color fillColor = Color(Config.backgroundColor); // Use your app's background color
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 32,
        color: Color(Config.primaryColor),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      height: 68,
      width: 64,
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: pinBorderColor),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: errorColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );

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
            String expectedCode = generate4DigitKey(bibInt, secretKey, prime);

            return SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
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
                        "Code de confirmation",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(Config.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le code de confirmation commence par la lettre "$prefix-" suivie de 4 chiffres. Tu l\'as reçu par email lors de ton inscription.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: 70, // Fixed width to reserve space for the prefix
                            child: Text(
                              '$prefix-',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(Config.primaryColor),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 68,
                            width: 260,
                            child: Align(
                              alignment: Alignment.center,
                              child: Pinput(
                                length: 4,
                                controller: pinController,
                                focusNode: pinFocusNode,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: focusedPinTheme,
                                errorPinTheme: errorPinTheme,
                                separatorBuilder: (index) => const SizedBox(width: 6),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (errorText != null || showRetry) {
                                    setState(() {
                                      errorText = null;
                                      showRetry = false;
                                    });
                                  }
                                },
                                onCompleted: (code) async {
                                  if (code == expectedCode) {
                                    if (userData != null) {
                                      await UserData.saveUser({
                                        "id": userData['id'],
                                        "username": userData['username'],
                                        "bib_id": userData['bib_id'],
                                        "event_id": userData['event_id'],
                                      });
                                    }
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).pop();
                                    Navigator.pushReplacement(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(builder: (context) => const WorkingScreen()),
                                    );
                                  } else {
                                    setState(() {
                                      errorText = "Le code de confirmation est incorrect. Merci de réessayer.";
                                      showRetry = true;
                                    });
                                  }
                                },
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                      if (showRetry) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ButtonDiscard(
                                text: "Annuler",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ButtonAction(
                                icon: Icons.refresh,
                                text: "Réessayer",
                                onPressed: () {
                                  pinController.clear();
                                  setState(() {
                                    errorText = null;
                                    showRetry = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!showRetry) ...[
                        const SizedBox(height: 24),
                        // No Annuler button here anymore
                      ],
                    ],
                  ),
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
    final String name = userData['username'] ?? '';
    final int dossard = int.tryParse(userData['bib_id'].toString()) ?? 0;

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
                              color: Color(Config.primaryColor),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Est-ce bien toi ?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(Config.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(Config.primaryColor),
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
                      ButtonAction(
                        icon: Icons.check,
                        text: 'Oui',
                        onPressed: () async {
                          log("Name: $name");
                          log("Dossard: $dossard");

                          // Use bib_id for code generation and pass userData directly
                          showConfirmationCodeModal(context, userData['bib_id'], userData: userData);
                        },
                      ),
                      const SizedBox(height: 6),
                      ButtonDiscard(
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
