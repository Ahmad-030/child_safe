// lib/Notifications/NotificationsScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared.dart';
import '../firebase_service.dart';
import '../app_models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Color _typeColor(String type) {
    switch (type) {
      case 'alert':
        return AppTheme.danger;
      case 'sighting':
        return AppTheme.warning;
      case 'found':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_rounded;
      case 'sighting':
        return Icons.visibility_rounded;
      case 'found':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUid;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => FirebaseService.markAllNotificationsRead(uid),
              child: Text('Mark all read',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<AppNotification>>(
        stream: FirebaseService.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifs = snap.data ?? [];

          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              subtitle:
              'You\'ll be notified about alerts and sightings here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (ctx, i) {
              final n = notifs[i];
              final color = _typeColor(n.type);
              return Dismissible(
                key: Key(n.id),
                onDismissed: (_) =>
                    FirebaseService.markNotificationRead(n.id),
                background: Container(
                  color: AppTheme.success,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: GestureDetector(
                  onTap: () =>
                      FirebaseService.markNotificationRead(n.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.read
                          ? Colors.white
                          : color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: n.read
                          ? null
                          : Border.all(
                          color: color.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(n.type),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: GoogleFonts.poppins(
                                          fontWeight: n.read
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: 14)),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(n.body,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textMid),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(
                                _timeAgo(n.createdAt),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}