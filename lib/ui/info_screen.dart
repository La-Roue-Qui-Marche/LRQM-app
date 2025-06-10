// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/ui/components/app_top_bar.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(Config.backgroundColor),
        appBar: const AppTopBar(
          title: "Informations",
          showBackButton: true,
          showInfoButton: false,
          showLogoutButton: false,
        ),
        body: Container(
          color: const Color(Config.backgroundColor),
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 0.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'La Roue Qui Marche',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Le Roue Qui Marche est une association, mais c'est avant tout un événement. Un événement caritatif ayant comme objectif principal de rassembler naturellement et sportivement les personnes qui sont en situation de handicap, avec celles qui ne le sont pas. Le but est de parcourir 2'000'000 mètres (course à pied, marche, fauteuil roulant) en 24 heures ainsi que d'organiser une manifestation autour de l'événement. Tout un chacun peut rejoindre le parcours pour effectuer la distance qu'il peut et/ou qu'il veut.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Chaque mètre compte.",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final Uri uri = Uri.parse('https://larouequimarche.ch');
                                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                              },
                              child: Text(
                                "Plus d'information sur le site de la manifestation: ici",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(Config.primaryColor),
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Comment est venue l\'idée de créer une application dédiée ?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "L'idée a germé en essayant de trouver un moyen pour comptabiliser une distance collective sans que la performance soit le centre de l'attention, en valorisant les mètres (et non les kilomètres), car chaque mètre parcouru est important. Il fallait aussi laisser la liberté de la distance; permettre à chacun de faire un bout de chemin avec un minimum de contrainte associée à un parcours. Et enfin, la notion de collectif devait ressortir. Une application mobile semblait une évidence.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Dans une volonté de rassembler et de créer autour de l'événement, cette application a initialement fait l'objet d'un travail de diplôme de bachelor au sein de la filière informatique et systèemes de communication de la HEIG-VD. Ce travail a été effectué durant l'année 2024 par Thibault. La Roue Qui Marche le remercie pour son travail et le félicite pour l'obtention de son diplôme d'ingénieur.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 12),
                            Center(child: Image.asset('assets/pictures/HEIG_VD.jpg', height: 60)),
                            const SizedBox(height: 16),
                            Text(
                              "L'application a ensuite été reprise par des bénévoles dont l'informatique est le métier, sont sensibles à l'objectif de la Roue Qui Marche et au but de la manifestation. Ces 4 personnes ne sont pas purement des développeurs d'applications mobiles mais ont décidé d'unir leur talent pour proposer une solution adaptée à cet événement.",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            // --- Signature by Nicolas ---
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage('assets/pictures/minion.png'),
                                  radius: 30, // Same as contributors
                                  backgroundColor: Colors.grey[300],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Nicolas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Capitaine de l’app',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "— Merci de faire partie de l'aventure !",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            // --- End signature ---
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'L\'équipe de développement',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildContributorsSection(context),
                            const SizedBox(height: 24),
                            // --- Chef de projet section ---
                            // (REMOVE THIS SECTION)
                            // --- End Chef de projet section ---
                            Center(
                              child: Text(
                                "Un commentaire? Un bug? Une suggestion?\nlarqm.app.feedback@gmail.com",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final Uri uri = Uri.parse('mailto:larqm.app.feedback@gmail.com');
                                  await launchUrl(uri);
                                },
                                icon: const Icon(Icons.email, color: Colors.white),
                                label: const Text(
                                  'Contacter l\'équipe',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(Config.primaryColor),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'Made with ❤️ by AnCa ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<String>(
                                    future: Config.getAppVersion(),
                                    builder: (context, snapshot) {
                                      final version = snapshot.data ?? '';
                                      return version.isNotEmpty
                                          ? Text(
                                              'v$version',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black38,
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),
                                  Text(
                                    '© 2025 La Roue Qui Marche',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContributorsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 24,
        children: [
          _buildContributorProfile(context, 'https://github.com/therundmc',
              'https://avatars.githubusercontent.com/u/25774146?v=4', 'Antoine'),
          _buildContributorProfile(
              context, 'https://github.com/chloefont', 'https://avatars.githubusercontent.com/u/60699567?v=4', 'Chloé'),
          _buildContributorProfile(context, 'https://github.com/Maxime-Nicolet',
              'https://avatars.githubusercontent.com/u/21175110?v=4', 'Maxime'),
          _buildContributorProfile(context, 'https://github.com/tchekoto',
              'https://avatars.githubusercontent.com/u/16468108?v=4', 'William'),
        ],
      ),
    );
  }

  Widget _buildContributorProfile(BuildContext context, String? url, String? imageUrl, String name) {
    return GestureDetector(
      onTap: url != null
          ? () async {
              final Uri uri = Uri.parse(url);
              await launchUrl(uri, mode: LaunchMode.platformDefault);
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: imageUrl == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
