import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Utils/config.dart';
import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'SetupScanScreen.dart';
import 'LoadingScreen.dart';
import 'Components/TapCard.dart';

class SetupTeamScreen extends StatefulWidget {
  const SetupTeamScreen({super.key});

  @override
  _SetupTeamScreenState createState() => _SetupTeamScreenState();
}

class _SetupTeamScreenState extends State<SetupTeamScreen> {
  bool _isLoading = false;
  int _selectedContributors = 0;

  void _navigateToSetupScanScreen() async {
    setState(() {
      _isLoading = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupScanScreen(contributors: _selectedContributors),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _selectParticipants(int count) {
    setState(() {
      _selectedContributors = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/pictures/background.svg', // Set the background SVG
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Color(Config.COLOR_APP_BAR), size: 32),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                            Center(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: const Image(
                                  image: AssetImage('assets/pictures/DrawTeam-removebg.png'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const InfoCard(
                              title: "L'équipe !",
                              data: "Pour combien de personnes comptes-tu les mètres ?",
                              actionItems: [],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          children: [
                            TapCard(
                              logo: const Icon(Icons.looks_one, size: 32),
                              text: "Je pars en solo",
                              onTap: () => _selectParticipants(1),
                              isSelected: _selectedContributors == 1,
                            ),
                            Container(
                              height: 1,
                              color: Color(Config.COLOR_BACKGROUND), // Separator color
                            ),
                            TapCard(
                              logo: const Icon(Icons.looks_two, size: 32),
                              text: "On fait la paire",
                              onTap: () => _selectParticipants(2),
                              isSelected: _selectedContributors == 2,
                            ),
                            Container(
                              height: 1,
                              color: Color(Config.COLOR_BACKGROUND), // Separator color
                            ),
                            TapCard(
                              logo: const Icon(Icons.looks_3, size: 32),
                              text: "On se lance en triplettte",
                              onTap: () => _selectParticipants(3),
                              isSelected: _selectedContributors == 3,
                            ),
                            Container(
                              height: 1,
                              color: Color(Config.COLOR_BACKGROUND), // Separator color
                            ),
                            TapCard(
                              logo: const Icon(Icons.looks_4, size: 32),
                              text: "La monstre équipe",
                              onTap: () => _selectParticipants(4),
                              isSelected: _selectedContributors == 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedContributors > 0 && _selectedContributors < 5)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                  child: ActionButton(
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
}
