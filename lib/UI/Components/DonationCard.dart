import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/config.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
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
          Text(
            'Faire un don',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chaque don aide PluSport, FRAGILE Vaud et le sentier Handicap & Nature à accomplir leur mission.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl('https://larouequimarche.ch/nous-soutenir/#faire-don'),
              icon: const Icon(Icons.favorite, color: Colors.white),
              label: const Text(
                'Faire un don maintenant',
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
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(
            'Suis-nous sur les réseaux sociaux :',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
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
                _launchUrl('https://www.instagram.com/larouequimarche/#');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
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
