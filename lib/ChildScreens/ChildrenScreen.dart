// lib/ChildProfile/ChildrenScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';
import 'AddChildScreen.dart';
import 'ChildDetailScreen.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUid;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddChildScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddChildScreen()),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add Child',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<ChildProfile>>(
        stream: FirebaseService.childrenStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final children = snap.data ?? [];

          if (children.isEmpty) {
            return EmptyState(
              icon: Icons.child_care_rounded,
              title: 'No Children Registered',
              subtitle:
              'Add your children\'s profiles to track them and report alerts quickly.',
              actionLabel: 'Add Child',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddChildScreen()),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChildCard(
                child: children[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChildDetailScreen(child: children[i]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}