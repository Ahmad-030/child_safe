// lib/Splash&Onboarding/OnboardingScreen.dart
import 'package:child_safe/Authentication/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Instant Missing\nChild Alerts',
      description:
      'Stay informed with real-time notifications to help locate and respond quickly.',
      icon: Icons.notification_important_rounded,
      color: const Color(0xFF2563EB),
      gradientStart: const Color(0xFF3B82F6),
      gradientEnd: const Color(0xFF60A5FA),
    ),
    OnboardingData(
      title: 'Community-Powered\nSearch',
      description:
      'Parents, volunteers, and authorities work together to report and track missing children.',
      icon: Icons.people_rounded,
      color: const Color(0xFF0EA5E9),
      gradientStart: const Color(0xFF06B6D4),
      gradientEnd: const Color(0xFF22D3EE),
    ),
    OnboardingData(
      title: 'GPS Location\nTracking',
      description:
      'Real-time GPS tracking keeps parents informed of their child\'s whereabouts 24/7.',
      icon: Icons.location_on_rounded,
      color: const Color(0xFF8B5CF6),
      gradientStart: const Color(0xFF7C3AED),
      gradientEnd: const Color(0xFFA78BFA),
    ),
    OnboardingData(
      title: 'Secure Case\nManagement',
      description:
      'Verified information ensures safe, trusted communication and faster recoveries.',
      icon: Icons.shield_rounded,
      color: const Color(0xFF2563EB),
      gradientStart: const Color(0xFF3B82F6),
      gradientEnd: const Color(0xFF60A5FA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage].gradientStart.withOpacity(0.06),
                  _pages[_currentPage].gradientEnd.withOpacity(0.02),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < _pages.length - 1)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _pageController.animateToPage(
                                _pages.length - 1,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _pages[_currentPage]
                                    .color
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _pages[_currentPage]
                                      .color
                                      .withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Skip',
                                    style: GoogleFonts.poppins(
                                      color: _pages[_currentPage].color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: _pages[_currentPage].color,
                                      size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: _OnboardingPage(
                          data: _pages[i], isActive: _currentPage == i),
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                        List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 36 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == i
                                  ? _pages[_currentPage].color
                                  : Colors.grey.shade300,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      if (_currentPage < _pages.length - 1)
                        _buildNextButton()
                      else
                        SwipeToLogin(
                          onSwipeComplete: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          color: _pages[_currentPage].color,
                          gradientStart:
                          _pages[_currentPage].gradientStart,
                          gradientEnd: _pages[_currentPage].gradientEnd,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [
          _pages[_currentPage].gradientStart,
          _pages[_currentPage].gradientEnd,
        ]),
        boxShadow: [
          BoxShadow(
            color: _pages[_currentPage].color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Next',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ONBOARDING DATA ──────────────────────────────────────────────────────────
class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// ─── ONBOARDING PAGE ──────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const _OnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.7, end: 1.0),
            curve: Curves.easeOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.gradientStart.withOpacity(0.15),
                    data.gradientEnd.withOpacity(0.08),
                  ],
                ),
                border: Border.all(
                    color: data.color.withOpacity(0.15), width: 2),
              ),
              child: Icon(data.icon, size: 100, color: data.color),
            ),
          ),
          const SizedBox(height: 44),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)), child: child)),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF64748B),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SWIPE TO LOGIN ───────────────────────────────────────────────────────────
class SwipeToLogin extends StatefulWidget {
  final VoidCallback onSwipeComplete;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  const SwipeToLogin({
    Key? key,
    required this.onSwipeComplete,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  }) : super(key: key);

  @override
  State<SwipeToLogin> createState() => _SwipeToLoginState();
}

class _SwipeToLoginState extends State<SwipeToLogin>
    with TickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isComplete = false;
  late AnimationController _shimmerController;

  static const double buttonWidth = 70.0;
  static const double containerHeight = 64.0;
  static const double borderRadius = 20.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxDrag = constraints.maxWidth - buttonWidth;
      return Container(
        width: double.infinity,
        height: containerHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: widget.color.withOpacity(0.06),
          border: Border.all(color: widget.color.withOpacity(0.15), width: 2),
        ),
        child: Stack(children: [
          // Fill
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: _dragPosition + buttonWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isComplete
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [widget.gradientStart, widget.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(borderRadius - 2),
            ),
          ),

          // Label
          Center(
            child: AnimatedOpacity(
              opacity: _dragPosition < 80 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Swipe to Get Started',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ),
          ),

          // Success
          if (_isComplete)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Text('Welcome!',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),

          // Drag handle
          Positioned(
            left: _dragPosition,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                if (!_isComplete) {
                  setState(() {
                    _dragPosition =
                        (_dragPosition + d.delta.dx).clamp(0.0, maxDrag);
                  });
                }
              },
              onHorizontalDragEnd: (d) {
                if (_dragPosition > maxDrag * 0.75) {
                  setState(() {
                    _isComplete = true;
                    _dragPosition = maxDrag;
                  });
                  Future.delayed(const Duration(milliseconds: 400),
                      widget.onSwipeComplete);
                } else {
                  setState(() => _dragPosition = 0);
                }
              },
              child: Container(
                width: buttonWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                      color: widget.color.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _isComplete
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      key: ValueKey(_isComplete),
                      color: _isComplete
                          ? const Color(0xFF10B981)
                          : widget.color,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}