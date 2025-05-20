import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/ui/components/card_info.dart';
import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/setup_scan_screen.dart';
import 'package:lrqm/ui/loading_screen.dart';
import 'package:lrqm/ui/components/button_tap.dart';
import 'package:lrqm/ui/components/app_top_bar.dart';

class SetupTeamScreen extends StatefulWidget {
  const SetupTeamScreen({super.key});

  @override
  _SetupTeamScreenState createState() => _SetupTeamScreenState();
}

class _SetupTeamScreenState extends State<SetupTeamScreen> {
  bool _isLoading = false;
  int _selectedContributors = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/pictures/DrawTeam-AI.png'), context);
  }

  void _navigateToSetupScanScreen() async {
    setState(() => _isLoading = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupScanScreen(contributors: _selectedContributors),
      ),
    );

    setState(() => _isLoading = false);
  }

  void _selectParticipants(int count) {
    setState(() => _selectedContributors = count);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: const Color(Config.backgroundColor),
        appBar: _isLoading
            ? null
            : const AppTopBar(
                title: "Équipe",
                showBackButton: true,
                showInfoButton: false,
                showLogoutButton: false,
              ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 0.0, bottom: 120.0),
              child: Column(
                children: [
                  _buildTeamSelector(),
                ],
              ),
            ),
            if (_selectedContributors > 0 && _selectedContributors < 5)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 48.0),
                  child: ButtonAction(
                    icon: Icons.arrow_forward,
                    text: 'Suivant',
                    onPressed: _navigateToSetupScanScreen,
                  ),
                ),
              ),
            if (_isLoading) const LoadingScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.55,
              padding: const EdgeInsets.only(bottom: 12.0),
              child: FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: const AssetImage('assets/pictures/DrawTeam-AI.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const CardInfo(
            title: "L'équipe !",
            data: "Pour combien de personnes comptes-tu les mètres ?",
            actionItems: [],
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (i) => _buildTapCard(i + 1)),
        ],
      ),
    );
  }

  Widget _buildTapCard(int number) {
    final texts = ["Je pars en solo", "On fait la paire", "On se lance en triplettte", "La monstre équipe"];
    return Column(
      children: [
        ButtonTap(
          logo: SvgPicture.asset(
            'assets/icons/square-$number.svg',
            width: 32,
            height: 32,
          ),
          text: texts[number - 1],
          onTap: () => _selectParticipants(number),
          isSelected: _selectedContributors == number,
        ),
      ],
    );
  }
}
