// lib/AlertsScreens/AlertsScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';
import 'AlertDetailScreen.dart';
import 'CreateAlertScreen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Live counts for tab badges
  int _activeCount = 0;
  int _foundCount  = 0;
  int _allCount    = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenCounts();
  }

  /// Lightweight count listeners — update badges without rebuilding lists.
  void _listenCounts() {
    FirebaseFirestore.instance
        .collection('missing_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((s) { if (mounted) setState(() => _activeCount = s.docs.length); });

    FirebaseFirestore.instance
        .collection('missing_alerts')
        .where('status', isEqualTo: 'found')
        .snapshots()
        .listen((s) { if (mounted) setState(() => _foundCount = s.docs.length); });

    FirebaseFirestore.instance
        .collection('missing_alerts')
        .snapshots()
        .listen((s) { if (mounted) setState(() => _allCount = s.docs.length); });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Missing Alerts',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_activeCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_activeCount ACTIVE',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateAlertScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or location...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.white70, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 18),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              // Tabs with live count badges
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  _BadgeTab(label: 'Active', count: _activeCount, color: AppTheme.danger),
                  _BadgeTab(label: 'Found',  count: _foundCount,  color: AppTheme.success),
                  _BadgeTab(label: 'All',    count: _allCount,    color: Colors.white70),
                ],
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: null, // prevent duplicate hero in IndexedStack
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateAlertScreen())),
        backgroundColor: AppTheme.danger,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Report Missing',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        elevation: 4,
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertList(filter: 'active', searchQuery: _searchQuery),
          _AlertList(filter: 'found',  searchQuery: _searchQuery),
          _AlertList(filter: 'all',    searchQuery: _searchQuery),
        ],
      ),
    );
  }
}

// ─── Tab badge ────────────────────────────────────────────────────────────────
class _BadgeTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _BadgeTab({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Alert list per tab ───────────────────────────────────────────────────────
class _AlertList extends StatelessWidget {
  final String filter;   // 'active' | 'found' | 'all'
  final String searchQuery;
  const _AlertList({required this.filter, required this.searchQuery});

  /// Build a direct Firestore query so ALL users see real-time updates.
  /// NOTE: The 'active' and 'found' queries need a composite Firestore index:
  ///   Collection: missing_alerts
  ///   Fields    : status ASC, reportedAt DESC
  /// Firebase will print the direct creation link in the debug console
  /// the first time this runs — just tap it.
  Stream<List<MissingAlert>> _stream() {
    Query<Map<String, dynamic>> q =
    FirebaseFirestore.instance.collection('missing_alerts');

    if (filter == 'active') {
      q = q.where('status', isEqualTo: 'active');
    } else if (filter == 'found') {
      q = q.where('status', isEqualTo: 'found');
    }

    q = q.orderBy('reportedAt', descending: true);

    return q.snapshots().map((snap) =>
        snap.docs.map((d) => MissingAlert.fromMap(d.id, d.data())).toList());
  }

  List<MissingAlert> _filtered(List<MissingAlert> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list
        .where((a) =>
    a.childName.toLowerCase().contains(q) ||
        a.lastSeenLocation.toLowerCase().contains(q) ||
        a.reporterName.toLowerCase().contains(q) ||
        a.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MissingAlert>>(
      stream: _stream(),
      builder: (context, snap) {

        // Loading
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text('Loading alerts…',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ],
            ),
          );
        }

        // Firestore error (e.g. missing index)
        if (snap.hasError) {
          return _ErrorState(error: snap.error.toString());
        }

        final alerts = _filtered(snap.data ?? []);

        // Empty
        if (alerts.isEmpty) {
          return _EmptyState(filter: filter, hasSearch: searchQuery.isNotEmpty);
        }

        // List
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async =>
          await Future.delayed(const Duration(milliseconds: 500)),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: alerts.length,
            itemBuilder: (_, i) => _AlertCard(
              alert: alerts[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AlertDetailScreen(alertId: alerts[i].id)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Rich alert card ──────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final MissingAlert alert;
  final VoidCallback onTap;
  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive    = alert.status == 'active';
    final bool isEmergency = alert.isEmergency;
    final Color bannerColor = isActive ? AppTheme.danger : AppTheme.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppTheme.danger.withOpacity(isEmergency ? 1 : 0.4)
                : Colors.grey.withOpacity(0.15),
            width: isEmergency ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppTheme.danger.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
              ),
              child: Row(children: [
                Icon(
                  isActive
                      ? (isEmergency ? Icons.sos_rounded : Icons.warning_rounded)
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  isActive
                      ? (isEmergency ? '🆘  EMERGENCY ALERT' : '⚠️  MISSING CHILD ALERT')
                      : '✅  CHILD FOUND SAFELY',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5),
                ),
                const Spacer(),
                Text(alert.timeAgo,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 11)),
              ]),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Photo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppTheme.primary.withOpacity(0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: alert.childPhotoUrl != null
                        ? Image.network(
                      alert.childPhotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) =>
                      prog == null
                          ? child
                          : const Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary),
                        ),
                      ),
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.child_care_rounded,
                          color: AppTheme.primary, size: 32),
                    )
                        : const Icon(Icons.child_care_rounded,
                        color: AppTheme.primary, size: 32),
                  ),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              alert.childName,
                              style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(alert.status),
                        ],
                      ),
                      const SizedBox(height: 5),

                      Row(children: [
                        const Icon(Icons.cake_rounded,
                            size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text('Age ${alert.childAge}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppTheme.textMid)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppTheme.danger),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            alert.lastSeenLocation,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppTheme.textMid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),

                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'By ${alert.reporterName}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text('${alert.sightingCount}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textLight)),
                        const SizedBox(width: 2),
                        Text('sightings',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textLight)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppTheme.textLight),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),

            // Description preview
            if (alert.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  alert.description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Clothing chip
            if (alert.clothingDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(children: [
                  const Icon(Icons.checkroom_rounded,
                      size: 13, color: AppTheme.textLight),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      alert.clothingDescription,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final bool hasSearch;
  const _EmptyState({required this.filter, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    if (hasSearch) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('No results found',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppTheme.textMid)),
          const SizedBox(height: 6),
          Text('Try a different name or location',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textLight)),
        ]),
      );
    }

    if (filter == 'active') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 64),
            ),
            const SizedBox(height: 20),
            Text('All Children Are Safe!',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppTheme.success)),
            const SizedBox(height: 8),
            Text('No active missing child alerts right now.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateAlertScreen())),
              icon: const Icon(Icons.warning_rounded, color: AppTheme.danger),
              label: Text('Report a Missing Child',
                  style: GoogleFonts.poppins(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      );
    }

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          filter == 'found'
              ? Icons.emoji_events_rounded
              : Icons.notifications_none_rounded,
          size: 72,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 14),
        Text(
          filter == 'found' ? 'No Resolved Cases Yet' : 'No Alerts Yet',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: AppTheme.textMid),
        ),
        const SizedBox(height: 6),
        Text(
          filter == 'found'
              ? 'Found children will appear here'
              : 'Community alerts will appear here',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        ),
      ]),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final bool isIndex = error.contains('index') ||
        error.contains('FAILED_PRECONDITION') ||
        error.contains('requires an index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppTheme.danger, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            isIndex ? 'Firestore Index Required' : 'Could Not Load Alerts',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isIndex
                ? 'A composite Firestore index is missing.\n\n'
                'Go to Firebase Console → Firestore → Indexes\n'
                'and add:\n\n'
                'Collection : missing_alerts\n'
                'Fields     : status ASC  +  reportedAt DESC\n\n'
                'Firebase also prints the direct creation link\n'
                'in your debug console — just click it.'
                : 'Check your internet connection.\n\nError: $error',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppTheme.textMid, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AlertsScreen())),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}