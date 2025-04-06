import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(Config.COLOR_APP_BAR), size: 32),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "La petite histoire",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Cette application a initialement fait l'objet d'un travail de diplôme de bachelor au sein de la filière Informatique et systèmes de communication de la HEIG-VD. Ce travail a été effectué durant l'année 2024. Merci à Thibault pour son travail et bravo pour l'obtention de son diplôme d'ingénieur.",
                          style: TextStyle(fontSize: 14, color: Color(Config.COLOR_APP_BAR)),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Image.asset('assets/pictures/HEIG_VD.jpg', height: 50),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "L'application a ensuite été reprise par des bénévoles passionnés et éclairés de la Roue Qui Marche qui l'ont mis à jour, complété et finalement distribué.\nMerci à toute l'équipe de développement.",
                          style: TextStyle(fontSize: 14, color: Color(Config.COLOR_APP_BAR)),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "L'équipe de développement",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            _buildContributorProfile(context, 'https://github.com/MasterZeus97',
                                'https://avatars.githubusercontent.com/u/61197576?v=4', 'Thibault Seem'),
                            _buildContributorProfile(context, 'https://github.com/therundmc',
                                'https://avatars.githubusercontent.com/u/25774146?v=4', 'Antoine Cavallera'),
                            _buildContributorProfile(
                                context,
                                "https://github.com/chloefont?tab=overview&from=2025-03-01&to=2025-03-14",
                                "https://avatars.githubusercontent.com/u/60699567?v=4",
                                'Chloé Fontaine'),
                            _buildContributorProfile(context, 'https://github.com/Maxime-Nicolet',
                                'https://avatars.githubusercontent.com/u/21175110?v=4', 'Maxime Nicolet'),
                            _buildContributorProfile(context, 'https://github.com/tchekoto',
                                'https://avatars.githubusercontent.com/u/16468108?v=4', 'William Fromont'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Product Owner",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildContributorProfile(context, null, null, 'Nicolas Fontaine'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "GitHub Repo",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildContributorProfile(
                                    context,
                                    'https://github.com/La-Roue-Qui-Marche/LRQM-app',
                                    'https://avatars.githubusercontent.com/u/205062865?s=200&v=4',
                                    'La RQM',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({String? title, String? content, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(Config.COLOR_APP_BAR)),
            ),
          if (title != null) const SizedBox(height: 8),
          if (content != null)
            Text(
              content,
              style: const TextStyle(fontSize: 16, color: Color(Config.COLOR_APP_BAR)),
              textAlign: TextAlign.justify,
            ),
          if (child != null) child,
        ],
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
        width: 80,
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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                child: imageUrl != null ? null : const Icon(Icons.person, size: 30, color: Colors.white),
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
