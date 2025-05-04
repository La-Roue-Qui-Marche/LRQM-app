import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lrqm/api/event_controller.dart';
import 'package:lrqm/api/user_controller.dart';
import 'package:lrqm/utils/config.dart';
import 'package:lrqm/data/event_data.dart';
import 'package:lrqm/ui/confirm_screen.dart';
import 'package:lrqm/ui/loading_screen.dart';
import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/components/modal_bottom_text.dart';
import 'package:lrqm/ui/components/app_toast.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _controller = TextEditingController();

  bool _isEventActive = false;
  String? _eventName;
  List<dynamic> _events = [];
  dynamic _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadSavedEvent();
    _checkEventStatus();
  }

  Future<void> _loadSavedEvent() async {
    final eventName = await EventData.getEventName();
    setState(() => _eventName = eventName);
  }

  Future<void> _checkEventStatus() async {
    setState(() => _isEventActive = false);

    final eventsResult = await EventController.getAllEvents();
    if (eventsResult.hasError) {
      log("Error fetching events: ${eventsResult.error}");
      AppToast.showError("Erreur lors de la récupération des évènements.");
      _showErrorModal("Erreur lors de la récupération de l'évènement.");
      return;
    }

    _events = eventsResult.value ?? [];
    if (_events.isEmpty) {
      AppToast.showError("Erreur lors de la récupération des évènements.");
      _showErrorModal("Aucun évènement trouvé.");
      return;
    }

    setState(() => _events = _events);

    if (_events.length == 1) {
      _handleEventSelected(_events.first);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEventSelectionModal());
    }
  }

  Future<void> _handleEventSelected(dynamic event) async {
    _selectedEvent = event;
    await EventData.saveEvent(event);
    _loadSavedEvent();
    setState(() => _isEventActive = true);
  }

  void _showErrorModal(String message) {
    setState(() => _isEventActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomText(
        context,
        "Erreur",
        message,
        showConfirmButton: true,
        onConfirm: _checkEventStatus,
      );
    });
  }

  void _showEventSelectionModal() {
    dynamic selectedEvent = _events.first;

    showModalBottomText(
      context,
      "Sélectionne ton évènement",
      "Merci de sélectionner ton évènement",
      dropdownItems: _events.map((e) => e['name']).toList(),
      selectedDropdownValue: selectedEvent['name'],
      onDropdownChanged: (value) => selectedEvent = _events.firstWhere((e) => e['name'] == value),
      showConfirmButton: true,
      onConfirm: () => _handleEventSelected(selectedEvent),
    );
  }

  Future<void> _getUsername() async {
    FocusScope.of(context).unfocus();

    if (_controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomText(
          context,
          "Numéro de dossard manquant",
          "Il faut entrer ton numéro de dossard entre 1 et 9999. Si tu n'es pas inscrit, tu peux le faire sur le site de la RQM",
          showConfirmButton: true,
          externalUrl: "https://larouequimarche.ch/levenement/inscription/",
          externalUrlLabel: "S'inscrire en ligne",
        );
      });
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoadingScreen()));

    try {
      int.parse(_controller.text);

      final loginResult = await UserController.login(_controller.text, _selectedEvent['id']);
      final user = loginResult.value;

      if (loginResult.error != null ||
          user == null ||
          user['id'] == null ||
          user['username'] == null ||
          user['bib_id'] == null ||
          user['event_id'] == null) {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomText(
            context,
            "Utilisateur non trouvé",
            "Aucun numéro de dossard ne correspond pas à l'évènement sélectionné.",
            showConfirmButton: true,
            externalUrl: "https://larouequimarche.ch/levenement/inscription/",
            externalUrlLabel: "S'inscrire en ligne",
          );
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmScreen(userData: user)),
      );
    } catch (e) {
      AppToast.showError("Numéro de dossard invalide");
      Navigator.pop(context);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppToast.showError("Impossible d'ouvrir le lien d'inscription.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEventActive) return const LoadingScreen();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/pictures/background_2.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                  child: Container(color: Colors.black.withOpacity(0.05)),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_eventName != null)
                        const Text(
                          'Entre ton numéro de dossard pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(4)],
                        textAlign: TextAlign.center,
                        showCursor: false,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(Config.primaryColor),
                          letterSpacing: 5.0,
                        ),
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(fontSize: 18, color: Color(Config.primaryColor)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(Config.primaryColor), width: 1),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(Config.primaryColor), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Numéro entre 1 et 9999.',
                          style: TextStyle(fontSize: 14, color: Color(Config.primaryColor)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ButtonAction(
                        icon: Icons.login,
                        text: 'Connexion',
                        onPressed: _getUsername,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => _launchUrl("https://larouequimarche.ch/levenement/inscription/"),
                          child: const Text(
                            "Tu n'es pas encore inscrit ?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: Config.getAppVersion(),
                        builder: (context, snapshot) {
                          final version = snapshot.data ?? '...';
                          return Text(
                            'v$version',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          );
                        },
                      ),
                    ],
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
