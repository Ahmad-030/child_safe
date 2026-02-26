// lib/Profile/LeaderboardScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared.dart';
import '../firebase_service.dart';
import '../app_models.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppTheme.warning,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService.leaderboardStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 60, color: Colors.white),
                      const SizedBox(height: 12),
                      Text('Community Heroes',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text(
                          'People who helped find missing children',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),
                      // Top 3 podium
                      if (users.length >= 3)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _podiumItem(
                                users[1], 2, 80, const Color(0xFFC0C0C0)),
                            const SizedBox(width: 12),
                            _podiumItem(
                                users[0], 1, 100, const Color(0xFFFFD700)),
                            const SizedBox(width: 12),
                            _podiumItem(
                                users[2], 3, 70, const Color(0xFFCD7F32)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      final user = users[i];
                      final rank = i + 1;
                      final isCurrentUser =
                          user.uid == FirebaseService.currentUid;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? AppTheme.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isCurrentUser
                              ? Border.all(
                              color: AppTheme.primary.withOpacity(0.3))
                              : null,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(children: [
                          // Rank
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: rank <= 3
                                  ? _rankColor(rank)
                                  : AppTheme.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                rank <= 3 ? _rankEmoji(rank) : '#$rank',
                                style: GoogleFonts.poppins(
                                    fontSize: rank <= 3 ? 18 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: rank <= 3
                                        ? Colors.white
                                        : AppTheme.textMid),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                            AppTheme.primary.withOpacity(0.1),
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                    user.name +
                                        (isCurrentUser ? ' (You)' : ''),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                ]),
                                Row(children: [
                                  Text(user.roleLabel,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.textLight)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                      AppTheme.warning.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: Text(user.badge,
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppTheme.warning,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${user.points}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.warning)),
                              Text('pts',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppTheme.textLight)),
                            ],
                          ),
                        ]),
                      );
                    },
                    childCount: users.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _podiumItem(AppUser user, int rank, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 28 : 22,
          backgroundColor: color.withOpacity(0.3),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
                fontSize: rank == 1 ? 22 : 18,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(user.name.split(' ').first,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        Text('${user.points} pts',
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(_rankEmoji(rank),
                style: const TextStyle(fontSize: 22)),
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.primary;
    }
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}