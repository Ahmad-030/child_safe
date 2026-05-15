// lib/ProfileScreens/AboutChildSafeScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared.dart';

class AboutChildSafeScreen extends StatelessWidget {
  const AboutChildSafeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('About ChildSafe',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Logo / hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.child_care_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              Text('ChildSafe',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              Text('Version 1.0.0',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text('Protecting Children Through Community',
                  style: GoogleFonts.poppins(
                      color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 24),

          _infoCard(
            icon: Icons.info_outline_rounded,
            title: 'Our Mission',
            body:
            'ChildSafe is a community-powered missing child alert platform. '
                'We use AI-assisted face verification and real-time alerts to help '
                'reunite missing children with their families as quickly as possible.',
          ),
          _infoCard(
            icon: Icons.bolt_rounded,
            title: 'Key Features',
            body:
            '• Real-time missing child alerts\n'
                '• AI-powered face verification\n'
                '• Community sighting reports\n'
                '• Emergency instant reporting\n'
                '• Leaderboard & community rewards',
          ),
          _infoCard(
            icon: Icons.gavel_rounded,
            title: 'Legal',
            body:
            'ChildSafe is intended solely for reporting and locating missing '
                'children. Misuse of this platform is strictly prohibited and may '
                'result in account suspension and legal action.',
          ),

          const SizedBox(height: 8),

          const SizedBox(height: 24),
          Text('Made with ❤️ to protect children',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('© 2025 ChildSafe. All rights reserved.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 10),
          Text(body,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textMid, height: 1.6)),
        ]),
      );

  Widget _linkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          title: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right,
              color: AppTheme.textLight),
          onTap: onTap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}