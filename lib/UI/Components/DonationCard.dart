import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faire un don',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(Config.COLOR_APP_BAR),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chaque don pourra venir en aide aux associations que nous soutenons qui sont PluSport, FRAGILE Vaud et le sentier Handicap & Nature.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                // Add logic to open the Twint QR code
              },
              child: Image.asset(
                'assets/pictures/twint.png', // Replace with the actual path to the Twint QR code image
                width: 150,
                height: 150,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Suivez-nous sur les réseaux sociaux :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/facebook.svg',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  // Add Facebook link logic
                },
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/linkedin.svg',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  // Add LinkedIn link logic
                },
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/instagram.svg',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  // Add Instagram link logic
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
