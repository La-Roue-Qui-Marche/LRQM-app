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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12.0, right: 0.0, left: 0.0, top: 2.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'À propos de l\'événement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Découvrez les détails de l\'événement, les objectifs, et comment tu peux participer pour faire une différence.',
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
                    backgroundColor: const Color(Config.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(Config.backgroundColor)),
              const SizedBox(height: 16),
              const Text(
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
          color: Color(Config.backgroundColor),
          shape: BoxShape.circle,
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
