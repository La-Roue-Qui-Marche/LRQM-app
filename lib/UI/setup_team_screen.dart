import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transparent_image/transparent_image.dart';

import '../Utils/config.dart';
import 'Components/InfoCard.dart';
import 'Components/button_action.dart';
import 'setup_scan_screen.dart';
import 'LoadingScreen.dart';
import 'Components/TapCard.dart';
import 'Components/top_app_bar.dart';

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
    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      appBar: _isLoading
          ? null
          : const TopAppBar(
              title: "Équipe",
              showBackButton: true,
              showInfoButton: false,
              showLogoutButton: false,
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 6.0, bottom: 120.0),
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
              width: MediaQuery.of(context).size.width * 0.45,
              padding: const EdgeInsets.all(16.0),
              child: FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: const AssetImage('assets/pictures/DrawTeam-AI.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const InfoCard(
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
        TapCard(
          logo: SvgPicture.asset(
            'assets/icons/square-$number.svg',
            width: 32,
            height: 32,
          ),
          text: texts[number - 1],
          onTap: () => _selectParticipants(number),
          isSelected: _selectedContributors == number,
        ),
        Container(
          height: 1,
          color: const Color(Config.backgroundColor),
        ),
      ],
    );
  }
}
