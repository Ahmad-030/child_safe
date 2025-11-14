import 'package:child_safe/Authentication/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      imagePath: 'assets/images/onboardinga.png',
      title: 'Instant Missing\nChild Alerts',
      description: 'Stay informed with real-time notifications to help locate and respond quickly.',
      color: Color(0xFF2563EB),
      gradientStart: Color(0xFF3B82F6),
      gradientEnd: Color(0xFF60A5FA),
    ),
    OnboardingData(
      imagePath: 'assets/images/onboardingb.png',
      title: 'Community-Powered\nSearch',
      description: 'Parents, volunteers, and authorities work together to report and track missing children.',
      color: Color(0xFF0EA5E9),
      gradientStart: Color(0xFF06B6D4),
      gradientEnd: Color(0xFF22D3EE),
    ),
    OnboardingData(
      imagePath: 'assets/images/onboardingc.png',
      title: 'Secure Case\nManagement',
      description: 'Verified information ensures safe, trusted communication and faster recoveries.',
      color: Color(0xFF2563EB),
      gradientStart: Color(0xFF3B82F6),
      gradientEnd: Color(0xFF60A5FA),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage].gradientStart.withOpacity(0.05),
                  _pages[_currentPage].gradientEnd.withOpacity(0.02),
                  Colors.white,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar with skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Enhanced Skip button
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _pages[_currentPage].color.withOpacity(0.08),
                                    _pages[_currentPage].color.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _pages[_currentPage].color.withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Skip',
                                    style: GoogleFonts.poppins(
                                      color: _pages[_currentPage].color,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _pages[_currentPage].color,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: OnboardingPage(
                          data: _pages[index],
                          isActive: _currentPage == index,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section with button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 40 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _currentPage == index
                                  ? _pages[_currentPage].color
                                  : Colors.grey.shade300,
                              boxShadow: _currentPage == index
                                  ? [
                                BoxShadow(
                                  color: _pages[_currentPage].color.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      if (_currentPage < _pages.length - 1)
                      // Next button
                        _buildModernButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          label: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          color: _pages[_currentPage].color,
                        )
                      else
                      // Swipe to Login with matching theme
                        SwipeToLogin(
                          onSwipeComplete: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );

                            print('Navigating to login...');
                          },
                          color: _pages[_currentPage].color,
                          gradientStart: _pages[_currentPage].gradientStart,
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

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String imagePath;
  final String title;
  final String description;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const OnboardingPage({
    Key? key,
    required this.data,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image container with modern design
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.8, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              height: 320,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: data.color.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            data.gradientStart.withOpacity(0.2),
                            data.gradientEnd.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: data.color.withOpacity(0.4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Title with modern typography
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  height: 1.7,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Swipe to Login Widget with matching theme
// Enhanced Swipe to Login Widget with proper fixes
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

class _SwipeToLoginState extends State<SwipeToLogin> with TickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isComplete = false;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;

  // Button and container dimensions
  static const double buttonWidth = 70.0;
  static const double containerHeight = 64.0;
  static const double borderRadius = 20.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!_isComplete) {
      setState(() {
        _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_dragPosition > maxDrag * 0.75) {
      setState(() {
        _isComplete = true;
        _dragPosition = maxDrag;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onSwipeComplete();
      });
    } else {
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - buttonWidth;

        return Container(
          width: double.infinity,
          height: containerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.08),
                widget.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: widget.color.withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress fill with gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _dragPosition + buttonWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isComplete
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [widget.gradientStart, widget.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  boxShadow: [
                    BoxShadow(
                      color: (_isComplete ? const Color(0xFF10B981) : widget.color).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // Animated glow effect
              if (!_isComplete && _dragPosition < 80)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius - 2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.2 * _glowController.value),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Enhanced shimmer effect
              if (!_isComplete && _dragPosition < 80)
                ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            left: -150 + (_shimmerController.value * (constraints.maxWidth + 300)),
                            child: Transform.rotate(
                              angle: 0.3,
                              child: Container(
                                width: 150,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      widget.color.withOpacity(0.15),
                                      Colors.white.withOpacity(0.25),
                                      widget.color.withOpacity(0.15),
                                      Colors.white.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Text with better visibility
              Center(
                child: AnimatedOpacity(
                  opacity: _dragPosition < 100 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'Swipe to Get Started',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Success text
              if (_isComplete)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Welcome!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Draggable button with enhanced design
              Positioned(
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: buttonWidth,
                    height: containerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isComplete
                            ? [Colors.white, Colors.white]
                            : [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: _isComplete
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : widget.color.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isComplete ? const Color(0xFF10B981) : widget.color).withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _isComplete ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          key: ValueKey(_isComplete),
                          color: _isComplete ? const Color(0xFF10B981) : widget.color,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}