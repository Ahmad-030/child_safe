// lib/HomeScreen/HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared.dart';
import '../firebase_service.dart';
import '../app_models.dart';

import '../EmergencyScreen/EmergencyAlert.dart';
import 'AlertsScreens/AlertDetailScreen.dart';
import 'AlertsScreens/AlertsScreen.dart';
import 'ChildScreens/ChildrenScreen.dart';
import 'NotificationsScreen.dart';
import 'ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseService.currentUid;
    if (uid != null) {
      final user = await FirebaseService.getUserProfile(uid);
      if (mounted) setState(() => _user = user);
    }
  }

  List<Widget> get _screens => [
    _HomeDashboard(user: _user),
    const AlertsScreen(),
    _user?.role == 'parent' ? const ChildrenScreen() : const AlertsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Alerts',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: _user?.role == 'parent'
                      ? Icons.child_care_rounded
                      : Icons.search_rounded,
                  label:
                  _user?.role == 'parent' ? 'Children' : 'Search',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                StreamBuilder<int>(
                  stream: FirebaseService.currentUid != null
                      ? FirebaseService.unreadCountStream(
                      FirebaseService.currentUid!)
                      : const Stream.empty(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return _NavItem(
                      icon: Icons.notifications_rounded,
                      label: 'Alerts',
                      isActive: _currentIndex == 3,
                      badge: count > 0 ? count.toString() : null,
                      onTap: () => setState(() => _currentIndex = 3),
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color:
                  isActive ? AppTheme.primary : AppTheme.textLight,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOME DASHBOARD ────────────────────────────────────────────────────────────
class _HomeDashboard extends StatelessWidget {
  final AppUser? user;

  const _HomeDashboard({this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('ChildSafe',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                      'Welcome, ${user?.name.split(' ').first ?? 'User'}!',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withOpacity(0.8),
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user?.roleLabel ?? '',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Together we protect every child',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    FutureBuilder<Map<String, int>>(
                      future: FirebaseService.getStats(),
                      builder: (context, snap) {
                        final stats = snap.data ??
                            {
                              'active': 0,
                              'found': 0,
                              'users': 0,
                              'children': 0
                            };
                        return Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Active Alerts',
                                value: '${stats['active']}',
                                icon: Icons.warning_rounded,
                                color: AppTheme.danger,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // FIX: "Children Found" card is now tappable
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AlertsScreen(),
                                  ),
                                ),
                                child: StatCard(
                                  title: 'Children Found',
                                  value: '${stats['found']}',
                                  icon: Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Volunteers',
                                value: '${stats['users']}',
                                icon: Icons.people_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Emergency button
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EmergencyScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626)
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.danger.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emergency_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMERGENCY REPORT',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5)),
                                Text(
                                    'Report a missing child immediately',
                                    style: GoogleFonts.poppins(
                                        color:
                                        Colors.white.withOpacity(0.85),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 18),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent alerts header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active Alerts',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        // FIX: "See all" now navigates to AlertsScreen
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AlertsScreen()),
                          ),
                          child: Text('See all',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<MissingAlert>>(
              stream: FirebaseService.activeMissingAlertsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        )),
                  );
                }
                final alerts = snap.data ?? [];
                if (alerts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Column(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success, size: 48),
                          const SizedBox(height: 12),
                          Text('No Active Alerts',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success)),
                          Text('All children are safe right now',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textMid)),
                        ]),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      final alert = alerts[i];
                      return AlertCard(
                        alert: alert,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AlertDetailScreen(alertId: alert.id),
                          ),
                        ),
                      );
                    },
                    childCount:
                    alerts.length > 5 ? 5 : alerts.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}