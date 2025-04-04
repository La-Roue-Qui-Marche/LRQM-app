import 'dart:developer';
import 'dart:async'; // Import Timer from dart:async

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package

import '../API/NewEventController.dart';
import '../API/NewUserController.dart';
import '../Utils/Result.dart';
import '../Utils/config.dart';
import 'ConfirmScreen.dart';
import 'LoadingScreen.dart';
import 'Components/ActionButton.dart';
import '../Data/EventData.dart';
import 'Components/CountdownModal.dart';
import 'Components/TextModal.dart';

/// Class to display the login screen.
/// This screen allows the user to enter his dossard number
/// and check if the name is correct.
/// The user can then access the information screen.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

/// State of the Login class.
class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  /// Controller to get the dossard number entered by the user.
  final TextEditingController _controller = TextEditingController();

  /// Name of the user.
  String _name = "";

  /// Dossard number of the user.
  int _dossard = -1;

  /// Event status.
  bool _isEventActive = false;
  String _eventMessage = "";

  @override
  void initState() {
    super.initState();
    _checkEventStatus();
  }

  void _checkEventStatus() async {
    setState(() {
      _isEventActive = false; // Show loading screen while fetching event info
    });

    Result<List<dynamic>> eventsResult = await NewEventController.getAllEvents();
    if (eventsResult.hasError) {
      log("Error fetching events: ${eventsResult.error}"); // Log the error details
      setState(() {
        _isEventActive = true; // Render login page before showing modal
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Erreur",
          "Erreur lors de la récupération de l'évènement. Veuillez vérifier votre connexion internet.",
          showConfirmButton: true,
          onConfirm: _checkEventStatus, // Retry fetching events on confirmation
        );
      });
      return;
    }

    var events = eventsResult.value!;
    var event = events.firstWhere(
      (event) => event['name'] == Config.EVENT_NAME,
      orElse: () => null,
    );

    if (event == null) {
      setState(() {
        _isEventActive = true; // Render login page before showing modal
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Erreur",
          "L'évènement '${Config.EVENT_NAME}' n'existe pas.",
          showConfirmButton: true,
          onConfirm: _checkEventStatus, // Retry fetching events on confirmation
        );
      });
      return;
    }

    DateTime startDate = DateTime.parse(event['start_date']);
    DateTime endDate = DateTime.parse(event['end_date']);
    DateTime now = DateTime.now();

    // Save all event details using EventData
    await EventData.saveEvent(event);

    setState(() {
      _isEventActive = true; // Render login page
    });

    if (now.isBefore(startDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCountdownModal(context, "C'est bientôt l'heure !", startDate: startDate); // Show countdown modal
      });
    } else if (now.isAfter(endDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(context, "C'est fini !", "Malheureusement, l'évènement est terminé.");
      });
    }
  }

  void _onTextChanged() {}

  /// Show a modal when the user ID is not found.
  void _showUserNotFoundModal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTextModal(
        context,
        "Dossard introuvable",
        "Cet utilisateur n'existe pas. Veuillez vérifier le numéro de dossard et réessayer.",
        showConfirmButton: true,
      );
    });
  }

  /// Function to show a snackbar with the message [value].
  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  /// Function to get the name of the user with the dossard number entered by the user.
  void _getUserame() async {
    log("Trying to login");

    // Hide the keyboard
    FocusScope.of(context).unfocus();

    if (_controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Erreur",
          "Veuillez entrer un numéro de dossard.",
          showConfirmButton: true,
        );
      });
      return;
    }

    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Ensure LoadingScreen is correctly referenced
    );

    try {
      int dossardNumber = int.parse(_controller.text);
      Result dosNumResult = await NewUserController.getUser(dossardNumber); // Use NewUserController

      if (dosNumResult.error != null) {
        // Show error message in snackbar
        showInSnackBar(dosNumResult.error!);
        _showUserNotFoundModal(); // Display modal for user not found
        setState(() {});
        Navigator.pop(context); // Close the loading page
      } else {
        setState(() {
          _name = dosNumResult.value['username']; // Extract username from the API response
          _dossard = dossardNumber;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfirmScreen(name: _name, dossard: _dossard)),
        );
      }
    } catch (e) {
      showInSnackBar("Numéro de dossard invalide ");
      setState(() {});
      Navigator.pop(context); // Close the loading page
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEventActive) {
      return const LoadingScreen();
    }

    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    _controller.addListener(_onTextChanged);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/pictures/background.svg', // Revert to SVG background
              fit: BoxFit.cover, // Ensure it covers the entire screen
            ),
          ),
          Center(
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
                          child: Image(
                            image: AssetImage('assets/pictures/LogoTextAnimated.gif'),
                            height: 100, // Adjust height as needed
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Entre ton numéro de dossard pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(Config.COLOR_APP_BAR), // Updated color
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(Config.COLOR_APP_BAR), // Bottom border in COLOR_APP_BAR
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4),
                            ],
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            ),
                            style: const TextStyle(
                              fontSize: 26,
                              color: Color(Config.COLOR_APP_BAR), // Updated color
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Entre un numéro entre 1 et 9999.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(Config.COLOR_APP_BAR), // Updated color
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ActionButton(
                          icon: Icons.login, // Add login icon
                          text: 'Se Connecter',
                          onPressed: _getUserame,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<String>(
                          future: Config.getAppVersion(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return Text(
                                'Version ${snapshot.data}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              );
                            } else {
                              return const Text(
                                'Version ...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
