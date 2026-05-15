// lib/ProfileScreens/PrivacySecurityScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _saving         = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPwCtrl.text.trim();
    final newPw   = _newPwCtrl.text.trim();
    final confirm = _confirmPwCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all fields', AppTheme.danger);
      return;
    }
    if (newPw.length < 6) {
      _snack('New password must be at least 6 characters', AppTheme.danger);
      return;
    }
    if (newPw != confirm) {
      _snack('Passwords do not match', AppTheme.danger);
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not logged in');

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);

      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _snack('Password changed successfully', AppTheme.success);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Authentication error', AppTheme.danger);
    } catch (e) {
      _snack('Error: $e', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Privacy & Security',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Privacy info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Data is Protected',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Text(
                    'ChildSafe encrypts your personal data and never shares it with third parties.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textMid),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          Text('Change Password',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 16),

          _pwField(
            controller: _currentPwCtrl,
            label: 'Current Password',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _pwField(
            controller: _newPwCtrl,
            label: 'New Password',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _pwField(
            controller: _confirmPwCtrl,
            label: 'Confirm New Password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Update Password',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(height: 32),

          Text('Privacy Policy',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),
          _infoTile(
            icon: Icons.lock_outline_rounded,
            title: 'Data Collection',
            body:
            'We collect only the information needed to help find missing children: your name, contact details, and alert reports.',
          ),
          _infoTile(
            icon: Icons.people_outline_rounded,
            title: 'Data Sharing',
            body:
            'Your personal details are never sold or shared with third parties. Alert information is visible to all app users to maximize the chances of finding missing children.',
          ),
          _infoTile(
            icon: Icons.delete_outline_rounded,
            title: 'Account Deletion',
            body:
            'To delete your account and all associated data, please contact support at support@childsafe.app.',
          ),
        ]),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
            GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppTheme.primary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.textLight, size: 20),
              onPressed: onToggle,
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String body,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(body,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textMid, height: 1.5)),
            ]),
          ),
        ]),
      );
}