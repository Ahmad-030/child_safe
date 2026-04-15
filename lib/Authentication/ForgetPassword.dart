// lib/Authentication/ForgetPassword.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firebase_service.dart';
import '../shared.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  late AnimationController _fadeController;
  bool _emailSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white))),
        ]),
        backgroundColor:
        isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', isError: true);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseService.sendPasswordReset(email);
      setState(() => _emailSent = true);
      _showSnackBar('Password reset link sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send reset email. Check address and try again.',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2563EB).withOpacity(0.08),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              color: Colors.white, size: 46),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Center(
                        child: Text(
                          _emailSent
                              ? 'Check Your Email'
                              : 'Forgot Password?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _emailSent
                              ? 'We\'ve sent a reset link to\n${_emailController.text}'
                              : 'Enter your email and we\'ll send\nyou a link to reset your password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF64748B),
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      if (!_emailSent) ...[
                        // Email field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF2563EB).withOpacity(0.15),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                const Color(0xFF2563EB).withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: const Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Color(0xFF2563EB)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Send button
                        GradientButton(
                          label: 'Send Reset Link',
                          onTap: _sendResetEmail,
                          isLoading: _isLoading,
                          icon: Icons.send_rounded,
                        ),
                      ] else ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mark_email_read_rounded,
                                color: Color(0xFF10B981), size: 64),
                          ),
                        ),
                        const SizedBox(height: 36),
                        GradientButton(
                          label: 'Back to Login',
                          onTap: () => Navigator.pop(context),
                          icon: Icons.arrow_back_rounded,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() => _emailSent = false);
                            },
                            child: Text('Didn\'t receive email? Resend',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}