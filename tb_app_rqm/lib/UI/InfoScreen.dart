import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/config.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Image.asset('assets/pictures/LogoText.png', height: 80),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "La petite histoire",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Cette application a initialement fait l'objet d'un travail de diplôme de bachelor au sein de la filière Informatique et systèmes de communication de la HEIG-VD. Ce travail a été effectué durant l'année 2024. Merci à Thibault pour son travail et bravo pour l'obtention de son diplôme d'ingénieur.",
                    style: TextStyle(fontSize: 16, color: Color(Config.COLOR_APP_BAR)),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Image.asset('assets/pictures/HEIG_VD.jpg', height: 50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "L'application a ensuite été reprise par des bénévoles passionnés et éclairés de la Roue Qui Marche qui l'ont mis à jour, complété et finalement distribué.\nMerci à toute l'équipe de developpement.",
                    style: TextStyle(fontSize: 16, color: Color(Config.COLOR_APP_BAR)),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "L'équipe de developpement",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            _buildContributorProfile(context, 'https://github.com/MasterZeus97',
                                'https://avatars.githubusercontent.com/u/61197576?v=4', 'Thibault Seem'),
                            _buildContributorProfile(context, 'https://github.com/therundmc',
                                'https://avatars.githubusercontent.com/u/25774146?v=4', 'Antoine Cavallera'),
                            _buildContributorProfile(context, null, null, 'Chloé Fontaine'),
                            _buildContributorProfile(context, 'https://github.com/Maxime-Nicolet',
                                'https://avatars.githubusercontent.com/u/21175110?v=4', 'Maxime Nicolet'),
                            _buildContributorProfile(context, null, null, 'William Fromont'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product Owner",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                          ),
                          const SizedBox(height: 12),
                          _buildContributorProfile(context, null, null, 'Nicolas Fontaine'),
                        ],
                      ),
                      const SizedBox(width: 50),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "GitHub Repo",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                          ),
                          const SizedBox(height: 12),
                          _buildContributorProfile(context, 'https://github.com/RQMAppTB',
                              'https://avatars.githubusercontent.com/u/179916091?v=4', 'La RQM'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, left: 10),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(Config.COLOR_APP_BAR), size: 32),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorProfile(BuildContext context, String? url, String? imageUrl, String name) {
    return GestureDetector(
      onTap: url != null
          ? () async {
              final Uri uri = Uri.parse(url);
              await launch(
                uri.toString(),
                forceSafariVC: false,
                forceWebView: false,
                headers: <String, String>{'my_header_key': 'my_header_value'},
              );
            }
          : null,
      child: Container(
        width: 80, // Fixed width
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                child: imageUrl != null ? null : Icon(Icons.person, size: 30, color: Colors.white),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                radius: 30,
                backgroundColor: imageUrl != null ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 14, color: Color(Config.COLOR_APP_BAR)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
