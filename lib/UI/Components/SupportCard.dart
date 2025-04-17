import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/config.dart';

class SupportCard extends StatelessWidget {
  const SupportCard({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 8.0, top: 16.0),
          child: Text(
            'Informations sur l\'événement',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12.0, right: 12.0, left: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'À propos de l\'événement',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Découvrez les détails de l\'événement, les objectifs, et comment vous pouvez participer pour faire une différence.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('https://larouequimarche.ch/'),
                  icon: const Icon(Icons.open_in_browser, color: Colors.white),
                  label: const Text(
                    'Découvrir comment aider',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(Config.COLOR_APP_BAR),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Color(Config.COLOR_BACKGROUND)),
              const SizedBox(height: 16),
              Text(
                'Suis-nous sur les réseaux sociaux :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _socialIcon('assets/icons/facebook.svg', () {
                    _launchUrl('https://www.facebook.com/larouequimarche');
                  }),
                  _socialIcon('assets/icons/linkedin.svg', () {
                    _launchUrl('https://www.linkedin.com/company/la-roue-qui-marche');
                  }),
                  _socialIcon('assets/icons/instagram.svg', () {
                    _launchUrl('https://www.instagram.com/larouequimarche/');
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(Config.COLOR_BACKGROUND),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}
