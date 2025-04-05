import 'dart:developer';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _name = "";
  int _dossard = -1;
  bool _isEventActive = false;

  @override
  void initState() {
    super.initState();
    _checkEventStatus();
  }

  void _checkEventStatus() async {
    setState(() {
      _isEventActive = false;
    });

    Result<List<dynamic>> eventsResult = await NewEventController.getAllEvents();
    if (eventsResult.hasError) {
      log("Error fetching events: ${eventsResult.error}");
      setState(() {
        _isEventActive = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Erreur",
          "Erreur lors de la récupération de l'évènement. Veuillez vérifier votre connexion internet.",
          showConfirmButton: true,
          onConfirm: _checkEventStatus,
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
        _isEventActive = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Erreur",
          "L'évènement '${Config.EVENT_NAME}' n'existe pas.",
          showConfirmButton: true,
          onConfirm: _checkEventStatus,
        );
      });
      return;
    }

    DateTime startDate = DateTime.parse(event['start_date']);
    DateTime endDate = DateTime.parse(event['end_date']);
    DateTime now = DateTime.now();

    await EventData.saveEvent(event);

    setState(() {
      _isEventActive = true;
    });

    if (now.isBefore(startDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCountdownModal(context, "C'est bientôt l'heure !", startDate: startDate);
      });
    } else if (now.isAfter(endDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(context, "C'est fini !", "Malheureusement, l'évènement est terminé.");
      });
    }
  }

  void _onTextChanged() {}

  void _showUserNotFoundModal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTextModal(
        context,
        "Numéro de dossard introuvable",
        "Il faut entrer ton numéro de dossard compris entre 1 et 9999. Si tu n'es pas inscrit, tu peux le faire sur le site de la RQM.",
        showConfirmButton: true,
      );
    });
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void _getUserame() async {
    log("Trying to login");

    FocusScope.of(context).unfocus();

    if (_controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTextModal(
          context,
          "Numéro de dossard manquant",
          "Il faut entrer ton numéro de dossard compris entre 1 et 9999. Si tu n'es pas inscrit, tu peux le faire sur le site de la RQM.",
          showConfirmButton: true,
        );
      });
      return;
    }

    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()),
    );

    try {
      int dossardNumber = int.parse(_controller.text);
      Result dosNumResult = await NewUserController.getUser(dossardNumber);

      if (dosNumResult.error != null) {
        _showUserNotFoundModal();
        setState(() {});
        Navigator.pop(context);
      } else {
        setState(() {
          _name = dosNumResult.value['username'];
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEventActive) {
      return const LoadingScreen();
    }

    _controller.addListener(_onTextChanged);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/pictures/background_2.png',
                    fit: BoxFit.cover, // Ensure the background image covers the full screen
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), // Reduce blur effect
                    child: Container(
                      color: Colors.black.withOpacity(0.05), // Add a very subtle overlay
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Card(
                  elevation: 10,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const Center(
                          child: Image(
                            image: AssetImage('assets/pictures/LogoTextAnimated.gif'),
                            height: 90,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Entre ton numéro de dossard pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(Config.COLOR_APP_BAR),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(Config.COLOR_APP_BAR),
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
                              fontSize: 24,
                              color: Color(Config.COLOR_APP_BAR),
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
                              color: Color(Config.COLOR_APP_BAR),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ActionButton(
                          icon: Icons.login,
                          text: 'Connexion',
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
