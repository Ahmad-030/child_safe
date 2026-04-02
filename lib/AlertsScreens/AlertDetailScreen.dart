// lib/AlertsScreens/AlertDetailScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // FIX: for tel & maps
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';
import '../face_verification_sheet.dart';
import 'AddSightingScreen.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commentController = TextEditingController();
  bool _submittingComment = false;
  MissingAlert? _latestAlert;

  // FIX: track current user role for permission check
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
  }

  // FIX: load user role so we can restrict "Mark as Found"
  Future<void> _loadUserRole() async {
    final uid = FirebaseService.currentUid;
    if (uid != null) {
      final user = await FirebaseService.getUserProfile(uid);
      if (mounted) setState(() => _currentUserRole = user?.role);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String alertId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseService.currentUid;
    if (uid == null) return;
    final user = await FirebaseService.getUserProfile(uid);
    if (user == null) return;
    setState(() => _submittingComment = true);
    try {
      await FirebaseService.addComment(AlertComment(
        id: '',
        alertId: alertId,
        authorUid: uid,
        authorName: user.name,
        text: text,
        createdAt: DateTime.now(),
      ));
      _commentController.clear();
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  void _startMarkAsFoundFlow() {
    final alert = _latestAlert;
    if (alert == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => FaceVerificationSheet(
        originalPhotoUrl: alert.childPhotoUrl,
        childName: alert.childName,
        actionLabel: 'Mark as Found',
        onVerified: (File photo) async {
          if (!mounted) return;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Mark as Found',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(photo,
                        height: 120, width: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Face verified ✅\nAre you sure ${alert.childName} has been found safely?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                  child: Text('Yes, Found!',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
          if (confirm == true) await _doMarkAsFound(alert, photo);
        },
        onCancelled: () {},
      ),
    );
  }

  Future<void> _doMarkAsFound(MissingAlert alert, File verifiedPhoto) async {
    try {
      final photoUrl =
      await FirebaseService.uploadImage(verifiedPhoto, 'found_confirmations');
      await FirebaseService.updateAlertStatus(
        alert.id,
        'found',
        resolvedBy: FirebaseService.currentUid,
        foundPhotoUrl: photoUrl,
      );
      if (alert.childId.isNotEmpty) {
        await FirebaseService.updateChildProfile(
            alert.childId, {'status': 'safe'});
      }
      if (FirebaseService.currentUid != null) {
        await FirebaseService.addPoints(FirebaseService.currentUid!, 50);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child marked as found! +50 points awarded.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MissingAlert?>(
      stream: FirebaseService.db
          .collection('missing_alerts')
          .doc(widget.alertId)
          .snapshots()
          .map((d) =>
      d.exists ? MissingAlert.fromMap(d.id, d.data()!) : null),
      builder: (context, snap) {
        final alert = snap.data;
        if (alert != null) _latestAlert = alert;

        if (alert == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alert')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.bg,
          // FIX: ensure scaffold resizes for keyboard (fixes comment overflow)
          resizeToAvoidBottomInset: true,
          floatingActionButtonLocation:
          FloatingActionButtonLocation.endContained,
          floatingActionButton: alert.status == 'active'
              ? FloatingActionButton.small(
            heroTag: 'alert_detail_sighting_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSightingScreen(
                  alertId: alert.id,
                  childName: alert.childName,
                  childPhotoUrl: alert.childPhotoUrl,
                ),
              ),
            ),
            backgroundColor: AppTheme.warning,
            tooltip: 'Report Sighting',
            child: const Icon(Icons.visibility_rounded, size: 20),
          )
              : null,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppTheme.primary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => Share.share(
                      'MISSING CHILD ALERT!\n\nName: ${alert.childName}\nAge: ${alert.childAge}\nLast Seen: ${alert.lastSeenLocation}\n\nIf you see this child, please call 1122 immediately!\n\n#ChildSafe #MissingChild',
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      alert.childPhotoUrl != null
                          ? Image.network(alert.childPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primary.withOpacity(0.2),
                            child: const Icon(Icons.child_care,
                                size: 100, color: AppTheme.primary),
                          ))
                          : Container(
                        color: AppTheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.child_care,
                            size: 100, color: AppTheme.primary),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7)
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              StatusBadge(alert.status),
                              const SizedBox(width: 8),
                              Text(alert.timeAgo,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 12)),
                            ]),
                            const SizedBox(height: 8),
                            Text(alert.childName,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800)),
                            Text(
                                'Age ${alert.childAge} • ${alert.lastSeenLocation}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Sightings'),
                    Tab(text: 'Comments'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // FIX: pass uid + role so _DetailsTab can gate "Mark as Found"
                _DetailsTab(
                  alert: alert,
                  onMarkFound: _startMarkAsFoundFlow,
                  currentUserUid: FirebaseService.currentUid,
                  currentUserRole: _currentUserRole,
                ),
                _SightingsTab(alertId: alert.id),
                _CommentsTab(
                  alertId: alert.id,
                  controller: _commentController,
                  onSubmit: () => _submitComment(alert.id),
                  isSubmitting: _submittingComment,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── DETAILS TAB ──────────────────────────────────────────────────────────────
class _DetailsTab extends StatelessWidget {
  final MissingAlert alert;
  final VoidCallback onMarkFound;
  // FIX: added for role-based access control
  final String? currentUserUid;
  final String? currentUserRole;

  const _DetailsTab({
    required this.alert,
    required this.onMarkFound,
    this.currentUserUid,
    this.currentUserRole,
  });

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textLight)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: only reporter or authority can mark as found
    final canMarkFound = alert.status == 'active' &&
        (currentUserUid == alert.reportedBy ||
            currentUserRole == 'authority');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: show Mark as Found only to reporter or authority
          if (canMarkFound) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.face_retouching_natural_rounded,
                        color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Face Verification Required',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    'You will be asked to take a photo and ML Kit will confirm it matches the child before marking as found.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textMid),
                  ),
                  const SizedBox(height: 14),
                  _FoundButton(onTap: onMarkFound),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Child Information',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _infoRow('Full Name', alert.childName, Icons.person_rounded),
                _infoRow(
                    'Age', '${alert.childAge} years old', Icons.cake_rounded),
                _infoRow('Last Seen', alert.lastSeenLocation,
                    Icons.location_on_rounded),
                _infoRow('Reported By', alert.reporterName,
                    Icons.account_circle_rounded),
                _infoRow(
                    'Reported', alert.timeAgo, Icons.access_time_rounded),
                _infoRow('Sightings', '${alert.sightingCount} reported',
                    Icons.visibility_rounded),
                if (alert.clothingDescription.isNotEmpty)
                  _infoRow('Clothing', alert.clothingDescription,
                      Icons.checkroom_rounded),
                if (alert.description.isNotEmpty)
                  _infoRow('Description', alert.description,
                      Icons.description_rounded),
              ],
            ),
          ),

          if (alert.status == 'found' && alert.foundAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Child Found Safely!',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success)),
                      Text(
                        'Resolved on ${alert.foundAt!.day}/${alert.foundAt!.month}/${alert.foundAt!.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textMid),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoundButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FoundButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        label: Text('Mark as Found',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── SIGHTINGS TAB ────────────────────────────────────────────────────────────
class _SightingsTab extends StatelessWidget {
  final String alertId;
  const _SightingsTab({required this.alertId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sighting>>(
      stream: FirebaseService.sightingsStream(alertId),
      builder: (context, snap) {
        final sightings = snap.data ?? [];
        if (sightings.isEmpty) {
          return const EmptyState(
            icon: Icons.visibility_off_rounded,
            title: 'No Sightings Yet',
            subtitle: 'Be the first to report a sighting',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sightings.length,
          itemBuilder: (ctx, i) {
            final s = sightings[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        s.reporterName.isNotEmpty
                            ? s.reporterName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.reporterName,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            '${s.reportedAt.day}/${s.reportedAt.month}/${s.reportedAt.year} ${s.reportedAt.hour}:${s.reportedAt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Sighting',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning)),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // FIX: location row is now tappable — opens Google Maps
                  GestureDetector(
                    onTap: () async {
                      if (s.lat != null && s.lng != null) {
                        final uri = Uri.parse(
                            'https://maps.google.com/?q=${s.lat},${s.lng}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Row(children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: (s.lat != null && s.lng != null)
                            ? AppTheme.primary
                            : AppTheme.danger,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.location,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (s.lat != null && s.lng != null)
                                ? AppTheme.primary
                                : AppTheme.textDark,
                            decoration: (s.lat != null && s.lng != null)
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                      ),
                      if (s.lat != null && s.lng != null)
                        const Icon(Icons.open_in_new_rounded,
                            size: 14, color: AppTheme.primary),
                    ]),
                  ),

                  if (s.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(s.description,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textMid)),
                  ],

                  // FIX: show reporter contact as tappable phone link
                  if (s.reporterContact.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('tel:${s.reporterContact}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Row(children: [
                        const Icon(Icons.phone_rounded,
                            size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.reporterContact,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ]),
                    ),
                  ],

                  if (s.photoUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(s.photoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── COMMENTS TAB ─────────────────────────────────────────────────────────────
class _CommentsTab extends StatelessWidget {
  final String alertId;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _CommentsTab({
    required this.alertId,
    required this.controller,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<AlertComment>>(
            stream: FirebaseService.commentsStream(alertId),
            builder: (context, snap) {
              final comments = snap.data ?? [];
              if (comments.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No Comments Yet',
                  subtitle: 'Be the first to share information',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (ctx, i) {
                  final c = comments[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            c.authorName.isNotEmpty
                                ? c.authorName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(c.authorName,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(
                                  '${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppTheme.textLight),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(c.text,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.textDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // FIX: wrap input bar in keyboard-aware Padding to prevent overflow
        Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.poppins(
                            color: AppTheme.textLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSubmitting ? null : onSubmit,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}