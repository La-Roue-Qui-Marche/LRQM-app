import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Components/TopAppBar.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      appBar: const TopAppBar(
        title: "Informations",
        showBackButton: true,
        showInfoButton: false,
        showLogoutButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0).copyWith(bottom: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 0.0, bottom: 6.0, top: 0.0),
              child: Text(
                'La petite histoire',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildCard(
              context,
              title: null, // Title moved outside
              content: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Origines et évolution',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    "Cette application a initialement fait l'objet d'un travail de diplôme de bachelor au sein de la filière Informatique et systèmes de communication de la HEIG-VD. Ce travail a été effectué durant l'année 2024. Merci à Thibault pour son travail et bravo pour l'obtention de son diplôme d'ingénieur.",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Image.asset('assets/pictures/HEIG_VD.jpg', height: 60)),
                  const SizedBox(height: 16),
                  Text(
                    "L'application a ensuite été reprise par des bénévoles passionnés et éclairés de la Roue Qui Marche qui l'ont mis à jour, complété et finalement distribué.\nMerci à toute l'équipe de développement. \n",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "- Nicolas Fontaine",
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 0.0, bottom: 6.0, top: 6.0),
              child: Text(
                'L\'équipe de développement bénévole',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildCard(
              context,
              title: null, // Title moved outside
              content: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Les Developpeurs',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildContributorsSection(context),
                  const SizedBox(height: 24),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildContributorProfile(context, null, null, 'Nicolas Fontaine'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "GitHub Repo",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
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
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String? title,
    String? content,
    String? image,
    String? secondaryContent,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          if (content != null) ...[
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.left,
            ),
          ],
          if (image != null) ...[
            const SizedBox(height: 16),
            Center(child: Image.asset(image, height: 60)),
          ],
          if (secondaryContent != null) ...[
            Text(
              secondaryContent,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ],
          if (child != null) ...[
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildContributorsSection(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildContributorProfile(context, 'https://github.com/therundmc',
            'https://avatars.githubusercontent.com/u/25774146?v=4', 'Antoine Cavallera'),
        _buildContributorProfile(context, 'https://github.com/chloefont',
            'https://avatars.githubusercontent.com/u/60699567?v=4', 'Chloé Fontaine'),
        _buildContributorProfile(context, 'https://github.com/Maxime-Nicolet',
            'https://avatars.githubusercontent.com/u/21175110?v=4', 'Maxime Nicolet'),
        _buildContributorProfile(context, 'https://github.com/tchekoto',
            'https://avatars.githubusercontent.com/u/16468108?v=4', 'William Fromont'),
      ],
    );
  }

  Widget _buildContributorProfile(BuildContext context, String? url, String? imageUrl, String name) {
    return GestureDetector(
      onTap: url != null
          ? () async {
              final Uri uri = Uri.parse(url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          : null,
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
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: imageUrl == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
