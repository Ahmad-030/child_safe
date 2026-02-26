// lib/Alerts/AlertsScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Missing Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateAlertScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or location...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Found'),
                  Tab(text: 'All'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'alerts_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAlertScreen()),
        ),
        backgroundColor: AppTheme.danger,
        icon: const Icon(Icons.add_rounded),
        label: Text('Report Missing',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertList(filter: 'active', searchQuery: _searchQuery),
          _AlertList(filter: 'found', searchQuery: _searchQuery),
          _AlertList(filter: 'all', searchQuery: _searchQuery),
        ],
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final String filter;
  final String searchQuery;

  const _AlertList({required this.filter, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final stream = filter == 'active'
        ? FirebaseService.activeMissingAlertsStream()
        : filter == 'found'
        ? FirebaseService.allAlertsStream().map((list) =>
        list.where((a) => a.status == 'found').toList())
        : FirebaseService.allAlertsStream();

    return StreamBuilder<List<MissingAlert>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var alerts = snap.data ?? [];
        if (searchQuery.isNotEmpty) {
          alerts = alerts
              .where((a) =>
          a.childName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
              a.lastSeenLocation
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
              .toList();
        }

        if (alerts.isEmpty) {
          return EmptyState(
            icon: filter == 'active'
                ? Icons.check_circle_rounded
                : Icons.search_off_rounded,
            title: filter == 'active'
                ? 'No Active Alerts'
                : 'No Results',
            subtitle: filter == 'active'
                ? 'All children are safe right now'
                : 'Try adjusting your search',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: alerts.length,
          itemBuilder: (ctx, i) => AlertCard(
            alert: alerts[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlertDetailScreen(alertId: alerts[i].id),
              ),
            ),
          ),
        );
      },
    );
  }
}