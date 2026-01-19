import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo size variants
enum LogoSize { sm, md, lg }

/// Logo variant types
enum LogoVariant { icon, horizontal }

/// Contexta Logo Widget
/// A minimalist, scholarly mark combining book page and annotation marks
class Logo extends StatelessWidget {
  final LogoVariant variant;
  final LogoSize size;
  final Color? color;

  const Logo({
    super.key,
    this.variant = LogoVariant.horizontal,
    this.size = LogoSize.md,
    this.color,
  });

  /// Get icon dimensions based on size
  double get _iconSize {
    switch (size) {
      case LogoSize.sm:
        return 32;
      case LogoSize.md:
        return 48;
      case LogoSize.lg:
        return 64;
    }
  }

  /// Get text size based on logo size
  double get _textSize {
    switch (size) {
      case LogoSize.sm:
        return 18;
      case LogoSize.md:
        return 24;
      case LogoSize.lg:
        return 32;
    }
  }

  /// Get spacing between icon and text
  double get _spacing {
    switch (size) {
      case LogoSize.sm:
        return 8;
      case LogoSize.md:
        return 12;
      case LogoSize.lg:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppTheme.getInkBlue(context);

    if (variant == LogoVariant.icon) {
      return _LogoIcon(size: _iconSize, color: logoColor);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoIcon(size: _iconSize, color: logoColor),
        SizedBox(width: _spacing),
        Text(
          'Contexta',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: _textSize,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.02 * _textSize,
            color: logoColor,
          ),
        ),
      ],
    );
  }
}

/// The logo icon/symbol
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
          ..strokeWidth = size.width * 0.06
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
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.15, h * 0.15),
      Offset(w * 0.15, h * 0.85),
      marginPaint,
    );

    // Annotation bracket (C shape) - the main symbol
    final bracketPath = Path();

    // Draw a stylized C/bracket shape
    bracketPath.moveTo(w * 0.65, h * 0.2);
    bracketPath.quadraticBezierTo(w * 0.25, h * 0.2, w * 0.25, h * 0.5);
    bracketPath.quadraticBezierTo(w * 0.25, h * 0.8, w * 0.65, h * 0.8);

    canvas.drawPath(bracketPath, paint);

    // Page corner (top right)
    final cornerPath = Path();
    cornerPath.moveTo(w * 0.7, h * 0.12);
    cornerPath.lineTo(w * 0.88, h * 0.12);
    cornerPath.lineTo(w * 0.88, h * 0.3);
    cornerPath.close();

    // Draw corner outline
    canvas.drawPath(cornerPath, paint..style = PaintingStyle.stroke);

    // Fill corner with lighter shade
    canvas.drawPath(
      cornerPath,
      fillPaint..color = color.withValues(alpha: 0.15),
    );

    // Small accent dot (like a period or annotation mark)
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.5),
      w * 0.04,
      fillPaint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// App Icon version with background
/// For use in app icon generation and splash screens
class LogoAppIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const LogoAppIcon({super.key, this.size = 192, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.beige;
    final iconColor = isDark ? AppTheme.darkInkBlue : AppTheme.inkBlue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.22), // iOS-style rounding
      ),
      child: Center(child: _LogoIcon(size: size * 0.6, color: iconColor)),
    );
  }
}

/// Splash screen logo with animation support
class SplashLogo extends StatelessWidget {
  final LogoSize size;

  const SplashLogo({super.key, this.size = LogoSize.lg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(variant: LogoVariant.icon, size: size),
        SizedBox(height: size == LogoSize.lg ? 24 : 16),
        Text(
          'Contexta',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: size == LogoSize.lg ? 36 : 28,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            color: AppTheme.getInkBlue(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your reading companion',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size == LogoSize.lg ? 14 : 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}
