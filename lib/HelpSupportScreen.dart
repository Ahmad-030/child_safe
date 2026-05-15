// lib/ProfileScreens/HelpSupportScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    _FAQ(
      q: 'How do I report a missing child?',
      a: 'Tap the "+" button on the Alerts screen or use the Emergency Report for urgent cases. Fill in the child\'s name, age, last seen location, and a recent photo.',
    ),
    _FAQ(
      q: 'What is Face Verification?',
      a: 'When marking a child as found, AI Face Verification compares a live photo with the original report photo to confirm identity before closing the case.',
    ),
    _FAQ(
      q: 'How do sightings work?',
      a: 'Any community member can report seeing a missing child by opening the alert and tapping "Report Sighting". This notifies the original reporter immediately.',
    ),
    _FAQ(
      q: 'What happens when I use Emergency Report?',
      a: 'An emergency alert is instantly saved to the database and visible to all users. For life-threatening situations always call 1122 directly.',
    ),
    _FAQ(
      q: 'How do I earn points and badges?',
      a: 'You earn points by reporting missing children, submitting sightings, and helping resolve cases. Visit the Leaderboard to see your ranking.',
    ),
    _FAQ(
      q: 'Can I delete an alert I created?',
      a: 'Open the alert and tap the options menu. Only the original reporter or an admin can delete an alert.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Help & Support',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text('Need Help?',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Our support team is available 24/7',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _contactBtn(
                    icon: Icons.email_outlined,
                    label: 'Email Us',
                    onTap: () => _launch('mailto:support@childsafe.app'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _contactBtn(
                    icon: Icons.phone_outlined,
                    label: 'Call Us',
                    onTap: () => _launch('tel:+921234567890'),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Frequently Asked Questions',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),

          ..._faqs.map((faq) => _FAQTile(faq: faq)),
          const SizedBox(height: 24),

          // Emergency helpline reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.local_police_rounded,
                  color: AppTheme.danger, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Emergency?',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.danger)),
                  const SizedBox(height: 2),
                  Text('Call police immediately for life-threatening situations',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textMid)),
                ]),
              ),
              GestureDetector(
                onTap: () => _launch('tel:15'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Call 15',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border:
            Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
          const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: AppTheme.primary, size: 18),
          ),
          title: Text(widget.faq.q,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          initiallyExpanded: _expanded,
          children: [
            Text(widget.faq.a,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMid, height: 1.6)),
          ],
        ),
      ),
    );
  }
}