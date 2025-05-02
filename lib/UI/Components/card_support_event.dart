// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lrqm/utils/config.dart';

class CardSupportEvent extends StatelessWidget {
  const CardSupportEvent({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.all(20.0),
      color: Colors.white, // simple fond blanc sans ombre ni bord arrondi
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reste connecté',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Suis-nous sur les réseaux sociaux pour découvrir les coulisses de l’événement, les prochaines étapes, et comment tu peux y contribuer.',
            style: TextStyle(
              fontSize: 16,
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _launchUrl('https://larouequimarche.ch/'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Visiter le site',
                    style: TextStyle(
                      color: Color(Config.primaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 18, color: Color(Config.primaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(Config.backgroundColor),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          assetPath,
          width: 28,
          height: 28,
        ),
      ),
    );
  }
}
