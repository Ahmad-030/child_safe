// lib/Profile/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared.dart';
import '../firebase_service.dart';
import '../app_models.dart';
import '../Authentication/LoginScreen.dart';
import 'LeaderboardScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseService.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUid;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<AppUser?>(
        stream: FirebaseService.userStream(uid),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: Column(children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border:
                        Border.all(color: Colors.white, width: 3),
                      ),
                      child: user.photoUrl != null
                          ? ClipOval(
                          child: Image.network(user.photoUrl!,
                              fit: BoxFit.cover))
                          : Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text(user.email,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(user.roleLabel, Colors.white),
                        const SizedBox(width: 8),
                        _chip('${user.badge} 🏆',
                            AppTheme.warning),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.warning, size: 28),
                          const SizedBox(width: 8),
                          Text('${user.points} Points',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      StreamBuilder<List<MissingAlert>>(
                        stream: FirebaseService.myAlertsStream(uid),
                        builder: (ctx, snap) {
                          final alerts = snap.data ?? [];
                          final active = alerts
                              .where((a) => a.status == 'active')
                              .length;
                          final found = alerts
                              .where((a) => a.status == 'found')
                              .length;
                          return Row(children: [
                            Expanded(
                                child: _statBox(
                                    '${alerts.length}',
                                    'Total Alerts',
                                    AppTheme.primary)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _statBox(
                                    '$active',
                                    'Active',
                                    AppTheme.danger)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _statBox(
                                    '$found',
                                    'Found',
                                    AppTheme.success)),
                          ]);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Menu items
                      _menuSection(context, [
                        _menuItem(
                            Icons.person_rounded,
                            'Edit Profile',
                            AppTheme.primary,
                                () {}),
                        _menuItem(
                            Icons.leaderboard_rounded,
                            'Leaderboard',
                            AppTheme.warning,
                                () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const LeaderboardScreen()))),
                        _menuItem(
                            Icons.notifications_rounded,
                            'Notification Settings',
                            AppTheme.accent,
                                () {}),
                        _menuItem(
                            Icons.security_rounded,
                            'Privacy & Security',
                            AppTheme.success,
                                () {}),
                        _menuItem(
                            Icons.help_rounded,
                            'Help & Support',
                            AppTheme.textMid,
                                () {}),
                        _menuItem(
                            Icons.info_rounded,
                            'About ChildSafe',
                            AppTheme.textLight,
                                () {}),
                      ]),

                      const SizedBox(height: 16),

                      // Sign out
                      GestureDetector(
                        onTap: () => _signOut(context),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                AppTheme.danger.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.logout_rounded,
                                color: AppTheme.danger),
                            const SizedBox(width: 12),
                            Text('Sign Out',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.danger,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: AppTheme.danger),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text,
        style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600)),
  );

  Widget _statBox(String value, String label, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)
      ],
    ),
    child: Column(children: [
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color)),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppTheme.textLight)),
    ]),
  );

  Widget _menuSection(BuildContext context, List<Widget> items) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(children: items),
      );

  Widget _menuItem(IconData icon, String title, Color color,
      VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
            ]),
          ),
        ),
      );
}