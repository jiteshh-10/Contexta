import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Splash screen with fade-in animation
/// Duration: 2.5 seconds total, 700ms fade-in
/// Branding reinforcement and emotional pacing
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.fadeInDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation after a brief delay for smooth appearance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 400;
    final iconSize = isLargeScreen ? 100.0 : 80.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Icon
                        _LogoIcon(
                          size: iconSize,
                          color: AppTheme.getInkBlue(context),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Contexta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: isLargeScreen ? 48 : 40,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.getInkBlue(context),
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tagline
                        Text(
                          'Your reading companion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The logo icon/symbol for splash screen
/// Combines: page corner, annotation bracket (C shape), and margin line
class _LogoIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _LogoIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoIconPainter(color: color),
    );
  }
}

/// Custom painter for the logo icon
class _LogoIconPainter extends CustomPainter {
  final Color color;

  _LogoIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.05
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Margin line (left side, subtle)
    final marginPaint =
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.02
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.18, h * 0.15),
      Offset(w * 0.18, h * 0.85),
      marginPaint,
    );

    // Annotation bracket (C shape) - the main symbol
    final bracketPath = Path();

    // Draw a stylized C/bracket shape
    bracketPath.moveTo(w * 0.65, h * 0.18);
    bracketPath.cubicTo(
      w * 0.35,
      h * 0.18,
      w * 0.28,
      h * 0.35,
      w * 0.28,
      h * 0.5,
    );
    bracketPath.cubicTo(
      w * 0.28,
      h * 0.65,
      w * 0.35,
      h * 0.82,
      w * 0.65,
      h * 0.82,
    );

    canvas.drawPath(bracketPath, paint);

    // Page corner (top right) - folded page effect
    final cornerPath = Path();
    cornerPath.moveTo(w * 0.68, h * 0.1);
    cornerPath.lineTo(w * 0.88, h * 0.1);
    cornerPath.lineTo(w * 0.88, h * 0.3);
    cornerPath.lineTo(w * 0.68, h * 0.1);

    // Draw corner with fill
    canvas.drawPath(
      cornerPath,
      fillPaint..color = color.withValues(alpha: 0.12),
    );

    // Corner fold line
    canvas.drawLine(
      Offset(w * 0.68, h * 0.1),
      Offset(w * 0.88, h * 0.3),
      paint..strokeWidth = size.width * 0.03,
    );

    // Small accent dot (annotation mark)
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.5),
      w * 0.035,
      fillPaint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
