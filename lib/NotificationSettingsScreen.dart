// lib/ProfileScreens/NotificationSettingsScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared.dart';
import '../firebase_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _newAlerts     = true;
  bool _sightings     = true;
  bool _childFound    = true;
  bool _comments      = false;
  bool _appUpdates    = false;
  bool _saving        = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uid = FirebaseService.currentUid;
    if (uid == null) return;
    final user = await FirebaseService.getUserProfile(uid);
    if (user == null || !mounted) return;
    final prefs = (user.toMap()['notificationPrefs'] as Map?) ?? {};
    setState(() {
      _newAlerts  = prefs['newAlerts']  ?? true;
      _sightings  = prefs['sightings']  ?? true;
      _childFound = prefs['childFound'] ?? true;
      _comments   = prefs['comments']   ?? false;
      _appUpdates = prefs['appUpdates'] ?? false;
    });
  }

  Future<void> _save() async {
    final uid = FirebaseService.currentUid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseService.updateUserProfile(uid, {
        'notificationPrefs': {
          'newAlerts' : _newAlerts,
          'sightings' : _sightings,
          'childFound': _childFound,
          'comments'  : _comments,
          'appUpdates': _appUpdates,
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Notification Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Text('Save',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Missing Child Alerts'),
          _tile(
            title: 'New Missing Alerts',
            subtitle: 'Get notified when a new child is reported missing',
            icon: Icons.warning_rounded,
            color: AppTheme.danger,
            value: _newAlerts,
            onChanged: (v) => setState(() => _newAlerts = v),
          ),
          _tile(
            title: 'Sightings Reported',
            subtitle: 'When someone reports seeing a missing child',
            icon: Icons.visibility_rounded,
            color: AppTheme.warning,
            value: _sightings,
            onChanged: (v) => setState(() => _sightings = v),
          ),
          _tile(
            title: 'Child Found',
            subtitle: 'When a missing child case is resolved',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
            value: _childFound,
            onChanged: (v) => setState(() => _childFound = v),
          ),
          const SizedBox(height: 8),
          _sectionHeader('Community'),
          _tile(
            title: 'Comments on My Alerts',
            subtitle: 'When someone comments on your alerts',
            icon: Icons.comment_rounded,
            color: AppTheme.primary,
            value: _comments,
            onChanged: (v) => setState(() => _comments = v),
          ),
          const SizedBox(height: 8),
          _sectionHeader('App'),
          _tile(
            title: 'App Updates & News',
            subtitle: 'Important announcements from ChildSafe',
            icon: Icons.campaign_rounded,
            color: AppTheme.textLight,
            value: _appUpdates,
            onChanged: (v) => setState(() => _appUpdates = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: Text(title,
        style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textLight,
            letterSpacing: 0.8)),
  );

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
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
        child: SwitchListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textLight)),
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      );
}