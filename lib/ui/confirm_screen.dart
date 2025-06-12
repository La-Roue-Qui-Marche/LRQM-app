// ignore_for_file: prefer_const_constructors, prefer_const_declarations

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import 'package:lrqm/data/user_data.dart';
import 'package:lrqm/utils/config.dart';
import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/components/button_discard.dart';
import 'package:lrqm/ui/working_screen.dart';
import 'package:lrqm/ui/login_screen.dart';

class ConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ConfirmScreen({super.key, required this.userData});

  void _showConfirmationModal(BuildContext context, dynamic bibId) {
    final int bibInt = bibId is int ? bibId : int.tryParse(bibId.toString()) ?? 0;
    final expectedCode = _generateConfirmationCode(bibInt);
    final prefix = Config.confirmationPrefixLetter;

    final pinController = TextEditingController();
    final focusNode = FocusNode();
    final fillColor = Color(Config.backgroundColor);
    final pinBorderColor = Color(Config.accentColor);
    final errorColor = Color.fromRGBO(255, 234, 238, 1);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(fontSize: 32, color: Color(Config.primaryColor), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
          color: fillColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.transparent)),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      height: 68,
      width: 64,
      decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: pinBorderColor)),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(color: errorColor, borderRadius: BorderRadius.circular(8)),
    );

    String? errorText;
    bool showRetry = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Code de confirmation",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(Config.primaryColor))),
                  SizedBox(height: 8),
                  Text(
                    'Le code de confirmation commence par la lettre "$prefix-" suivie de 4 chiffres. Tu l\'as reçu avec ton numéro de dossard.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$prefix-',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(Config.primaryColor),
                              letterSpacing: 2)),
                      SizedBox(
                        height: 68,
                        width: 260,
                        child: Pinput(
                          length: 4,
                          controller: pinController,
                          focusNode: focusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          errorPinTheme: errorPinTheme,
                          separatorBuilder: (index) => SizedBox(width: 6),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) {
                            if (errorText != null || showRetry) {
                              setState(() {
                                errorText = null;
                                showRetry = false;
                              });
                            }
                          },
                          onCompleted: (code) async {
                            if (code == expectedCode) {
                              await UserData.saveUser({
                                "id": userData['id'],
                                "username": userData['username'],
                                "bib_id": userData['bib_id'],
                                "event_id": userData['event_id'],
                              });
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (_) => const WorkingScreen()));
                            } else {
                              setState(() {
                                errorText = "Le code de confirmation est incorrect. Merci de réessayer.";
                                showRetry = true;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(errorText!, style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  ],
                  SizedBox(height: 16),
                  if (showRetry)
                    Row(
                      children: [
                        Expanded(child: ButtonDiscard(text: "Annuler", onPressed: () => Navigator.pop(context))),
                        SizedBox(width: 12),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _generateConfirmationCode(int bibId) {
    final secretKey = Config.confirmationSecretKey;
    final prime = Config.confirmationPrime;
    final masked = (bibId ^ secretKey) * prime;
    return (masked % 10000).toString().padLeft(4, '0');
  }

  @override
  Widget build(BuildContext context) {
    final name = userData['username'] ?? '';
    final dossard = int.tryParse(userData['bib_id'].toString()) ?? 0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline, size: 60, color: Color(Config.primaryColor)),
                              SizedBox(height: 24),
                              Text("Est-ce bien toi ?",
                                  style: TextStyle(fontSize: 16, color: Color(Config.primaryColor))),
                              SizedBox(height: 16),
                              Text(name,
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold, color: Color(Config.primaryColor))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 160),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        ButtonAction(
                          icon: Icons.check,
                          text: 'Oui',
                          onPressed: () {
                            log("Name: $name");
                            log("Dossard: $dossard");
                            _showConfirmationModal(context, dossard);
                          },
                        ),
                        SizedBox(height: 6),
                        ButtonDiscard(
                          icon: Icons.close,
                          text: 'Non',
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
