// lib/ChildScreens/ChildDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';
import 'AddChildScreen.dart';
import 'SafeZoneScreen.dart';
import '../AlertsScreens/CreateAlertScreen.dart';

class ChildDetailScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  bool _trackingActive = false;

  Future<void> _simulateLocationUpdate() async {
    setState(() => _trackingActive = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await FirebaseService.updateChildLocation(
          widget.child.id, pos.latitude, pos.longitude);
      await FirebaseService.addLocationHistory(
          widget.child.id, pos.latitude, pos.longitude);

      // ── CHECK GEOFENCE AFTER EVERY LOCATION UPDATE ──
      await FirebaseService.checkGeofenceAndNotify(
        child: widget.child,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Location error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _trackingActive = false);
    }
  }

  Future<void> _triggerSOS() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Trigger SOS?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'This will send an emergency SOS alert for ${widget.child.name} to all authorities and volunteers.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text('Send SOS',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await FirebaseService.triggerChildSOS(
        childId: widget.child.id,
        childName: widget.child.name,
        parentUid: widget.child.parentUid,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🆘 SOS alert sent! Authorities have been notified.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('SOS error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _deleteChild() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete ${widget.child.name}\'s profile?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseService.deleteChildProfile(widget.child.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(child.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddChildScreen(existingChild: child)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _deleteChild,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: child.photoUrl != null
                        ? ClipOval(
                        child: Image.network(child.photoUrl!,
                            fit: BoxFit.cover))
                        : const Icon(Icons.child_care_rounded,
                        size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(child.name,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text('${child.age} years • ${child.gender}',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  StatusBadge(child.status),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (child.status == 'safe') ...[
                    // SOS Button
                    GestureDetector(
                      onTap: _triggerSOS,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.danger.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sos_rounded,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text('TRIGGER SOS ALERT',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GradientButton(
                      label: _trackingActive
                          ? 'Updating Location...'
                          : 'Update Location',
                      icon: Icons.my_location_rounded,
                      isLoading: _trackingActive,
                      onTap: _simulateLocationUpdate,
                    ),
                    const SizedBox(height: 12),

                    // Safe Zone button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SafeZoneScreen(child: child),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              child.hasSafeZone
                                  ? Icons.shield_rounded
                                  : Icons.add_location_alt_rounded,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              child.hasSafeZone
                                  ? 'Manage Safe Zone ✓'
                                  : 'Set Up Safe Zone',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAlertScreen(child: child),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: AppTheme.danger),
                            const SizedBox(width: 8),
                            Text('Report Missing',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Safe zone status card
                  if (child.hasSafeZone) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: AppTheme.success.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.shield_rounded,
                            color: AppTheme.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Safe Zone Active',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.success)),
                              Text(
                                'Alert radius: ${child.safeZoneRadius < 1000 ? '${child.safeZoneRadius.toInt()}m' : '${(child.safeZoneRadius / 1000).toStringAsFixed(1)}km'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.textMid),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile Information',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _infoRow('Blood Group', child.bloodGroup,
                            Icons.bloodtype_rounded, AppTheme.danger),
                        _infoRow('Emergency Contact', child.emergencyContact,
                            Icons.phone_rounded, AppTheme.success),
                        if (child.description.isNotEmpty)
                          _infoRow('Description', child.description,
                              Icons.description_rounded, AppTheme.primary),
                        if (child.medicalConditions.isNotEmpty)
                          _infoRow(
                              'Medical Conditions',
                              child.medicalConditions.join(', '),
                              Icons.medical_services_rounded,
                              AppTheme.warning),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location tracking card
                  StreamBuilder<LocationUpdate?>(
                    stream: FirebaseService.childLocationStream(child.id),
                    builder: (context, snap) {
                      final loc = snap.data;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text('Last Known Location',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 12),
                            if (loc != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.gps_fixed_rounded,
                                          color: AppTheme.success, size: 16),
                                      const SizedBox(width: 6),
                                      Text('GPS Coordinates',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme.textLight)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${loc.lat.toStringAsFixed(6)}, ${loc.lng.toStringAsFixed(6)}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark),
                                    ),
                                    if (loc.timestamp != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Updated ${_timeAgo(loc.timestamp!)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textLight),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.textLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.location_off_rounded,
                                      color: AppTheme.textLight),
                                  const SizedBox(width: 8),
                                  Text('No location data yet',
                                      style: GoogleFonts.poppins(
                                          color: AppTheme.textLight)),
                                ]),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _infoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textLight)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
      ]),
    );
  }
}