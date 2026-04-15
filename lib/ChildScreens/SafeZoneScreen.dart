// lib/ChildScreens/SafeZoneScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';

class SafeZoneScreen extends StatefulWidget {
  final ChildProfile child;
  const SafeZoneScreen({super.key, required this.child});

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  double _radius = 500; // metres
  double? _lat, _lng;
  bool _isLoading = false;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.child.hasSafeZone) {
      _lat = widget.child.safeZoneLat;
      _lng = widget.child.safeZoneLng;
      _radius = widget.child.safeZoneRadius;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Location error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _saveSafeZone() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please set a location first'),
            backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseService.setSafeZone(
          widget.child.id, _lat!, _lng!, _radius);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Safe zone saved! You will be alerted if '
                  '${''} leaves this area.'),
              backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearSafeZone() async {
    await FirebaseService.clearSafeZone(widget.child.id);
    if (mounted) {
      setState(() {
        _lat = null;
        _lng = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Safe zone removed'),
            backgroundColor: AppTheme.warning),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Safe Zone — ${widget.child.name}'),
        actions: [
          if (widget.child.hasSafeZone)
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              onPressed: _clearSafeZone,
              tooltip: 'Remove safe zone',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_rounded, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set a safe zone around your child\'s home or school. '
                        'You will receive an instant alert if ${widget.child.name} '
                        'leaves this area.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textDark),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // Current safe zone status
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
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_lat != null)
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.textLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _lat != null
                            ? AppTheme.success
                            : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Safe Zone Center',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark)),
                          Text(
                            _lat != null
                                ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                : 'Not set',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppTheme.textMid),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: _fetchingLocation
                        ? 'Getting Location...'
                        : 'Use My Current Location',
                    icon: Icons.my_location_rounded,
                    isLoading: _fetchingLocation,
                    onTap: _getCurrentLocation,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Radius slider
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
                  Text('Safe Zone Radius',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Alert if child goes further than:',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textMid)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _radius < 1000
                            ? '${_radius.toInt()}m'
                            : '${(_radius / 1000).toStringAsFixed(1)}km',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary),
                      ),
                    ),
                  ]),
                  Slider(
                    value: _radius,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('100m',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppTheme.textLight)),
                      Text('5km',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preset buttons
                  Wrap(spacing: 8, children: [
                    _presetChip('School', 200),
                    _presetChip('Neighbourhood', 500),
                    _presetChip('Town', 2000),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Geofence event history
            if (widget.child.hasSafeZone) ...[
              Text('Recent Safe Zone Events',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              StreamBuilder<List<GeofenceEvent>>(
                stream:
                FirebaseService.geofenceEventsStream(widget.child.id),
                builder: (context, snap) {
                  final events = snap.data ?? [];
                  if (events.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('No safe zone events yet.',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textLight)),
                    );
                  }
                  return Column(
                    children: events
                        .map((e) => _eventTile(e))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            GradientButton(
              label: _isLoading ? 'Saving...' : 'Save Safe Zone',
              icon: Icons.shield_rounded,
              isLoading: _isLoading,
              onTap: _saveSafeZone,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, double radius) {
    final selected = _radius == radius;
    return GestureDetector(
      onTap: () => setState(() => _radius = radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.12)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primary : AppTheme.textMid)),
      ),
    );
  }

  Widget _eventTile(GeofenceEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_rounded,
              color: AppTheme.danger, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.eventType == 'exit'
                    ? 'Left safe zone'
                    : 'Returned to safe zone',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 13),
              ),
              Text(
                '${e.lat.toStringAsFixed(4)}, ${e.lng.toStringAsFixed(4)}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
        Text(
          _timeAgo(e.timestamp),
          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
        ),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}