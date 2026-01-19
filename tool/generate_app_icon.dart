// This script generates app icon PNG files for flutter_launcher_icons
// Run with: dart run tool/generate_app_icon.dart
//
// After running, execute: dart run flutter_launcher_icons

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image/image.dart' as img;

// Colors from logo guidelines (RGB values)
const int inkBlueR = 0x1A;
const int inkBlueG = 0x4B;
const int inkBlueB = 0x7C;

const int beigeR = 0xF5;
const int beigeG = 0xF0;
const int beigeB = 0xE8;

void main() {
  print('Generating app icons...');

  // Generate main app icon (1024x1024 for highest quality)
  generateAppIcon(1024, 'assets/app_icon.png');

  // Generate adaptive foreground (1024x1024 with transparent background)
  generateAdaptiveForeground(1024, 'assets/app_icon_foreground.png');

  print('');
  print('Done! App icons generated in assets/');
  print('');
  print('Now run: dart run flutter_launcher_icons');
}

void generateAppIcon(int size, String path) {
  final image = img.Image(width: size, height: size);

  // Fill with beige background
  final beigeColor = img.ColorRgba8(beigeR, beigeG, beigeB, 255);
  img.fill(image, color: beigeColor);

  // Draw logo elements
  drawLogoIcon(image, size);

  // Save PNG
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('Created: $path');
}

void generateAdaptiveForeground(int size, String path) {
  final image = img.Image(width: size, height: size);

  // Transparent background (already default)

  // Draw logo elements
  drawLogoIcon(image, size);

  // Save PNG
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('Created: $path');
}

void drawLogoIcon(img.Image image, int size) {
  final inkBlue = img.ColorRgba8(inkBlueR, inkBlueG, inkBlueB, 255);
  final inkBlueLight = img.ColorRgba8(inkBlueR, inkBlueG, inkBlueB, 77); // ~30%
  final inkBlueFaint = img.ColorRgba8(inkBlueR, inkBlueG, inkBlueB, 38); // ~15%

  final double center = size / 2;
  final double iconSize = size * 0.5;
  final int strokeWidth = (size * 0.04).round();

  // Draw margin line (left side, vertical) - 30% opacity
  final int marginX = (center - iconSize * 0.35).round();
  final int marginTop = (center - iconSize * 0.35).round();
  final int marginBottom = (center + iconSize * 0.35).round();

  drawThickLine(
    image,
    marginX,
    marginTop,
    marginX,
    marginBottom,
    strokeWidth,
    inkBlueLight,
  );

  // Draw C-shaped bracket using thick lines
  final double bracketStartX = center + iconSize * 0.25;
  final double bracketStartY = center - iconSize * 0.3;
  final double bracketEndY = center + iconSize * 0.3;
  final double bracketCurveX = center - iconSize * 0.15;

  // Upper half of bracket
  drawThickBezierCurve(
    image,
    bracketStartX,
    bracketStartY,
    center,
    bracketStartY,
    bracketCurveX,
    center - iconSize * 0.15,
    bracketCurveX,
    center,
    strokeWidth,
    inkBlue,
  );

  // Lower half of bracket
  drawThickBezierCurve(
    image,
    bracketCurveX,
    center,
    bracketCurveX,
    center + iconSize * 0.15,
    center,
    bracketEndY,
    bracketStartX,
    bracketEndY,
    strokeWidth,
    inkBlue,
  );

  // Draw page corner fold (top right) - filled triangle with 15% opacity
  final int cornerSize = (iconSize * 0.18).round();
  final int cornerX = (center + iconSize * 0.32).round();
  final int cornerY = (center - iconSize * 0.32).round();

  fillTriangle(
    image,
    cornerX - cornerSize,
    cornerY,
    cornerX,
    cornerY,
    cornerX,
    cornerY + cornerSize,
    inkBlueFaint,
  );

  // Draw corner fold line
  final int thinStroke = (size * 0.02).round();
  drawThickLine(
    image,
    cornerX - cornerSize,
    cornerY,
    cornerX,
    cornerY + cornerSize,
    thinStroke,
    inkBlue,
  );

  // Draw accent dot (annotation mark)
  final int dotRadius = (size * 0.03).round();
  final int dotX = (center + iconSize * 0.1).round();
  final int dotY = center.round();

  fillCircle(image, dotX, dotY, dotRadius, inkBlue);
}

// Helper: Draw a thick line using Bresenham's with circles at each point
void drawThickLine(
  img.Image image,
  int x0,
  int y0,
  int x1,
  int y1,
  int thickness,
  img.Color color,
) {
  final int dx = (x1 - x0).abs();
  final int dy = (y1 - y0).abs();
  final int sx = x0 < x1 ? 1 : -1;
  final int sy = y0 < y1 ? 1 : -1;
  int err = dx - dy;

  int x = x0;
  int y = y0;

  while (true) {
    // Draw a filled circle at each point for thickness
    fillCircle(image, x, y, thickness ~/ 2, color);

    if (x == x1 && y == y1) break;
    final int e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x += sx;
    }
    if (e2 < dx) {
      err += dx;
      y += sy;
    }
  }
}

// Helper: Draw a thick cubic Bezier curve
void drawThickBezierCurve(
  img.Image image,
  double x0,
  double y0,
  double x1,
  double y1,
  double x2,
  double y2,
  double x3,
  double y3,
  int thickness,
  img.Color color,
) {
  const int steps = 60;
  int prevX = x0.round();
  int prevY = y0.round();

  for (int i = 1; i <= steps; i++) {
    final double t = i / steps;
    final double mt = 1 - t;

    // Cubic Bezier formula
    final double x =
        mt * mt * mt * x0 +
        3 * mt * mt * t * x1 +
        3 * mt * t * t * x2 +
        t * t * t * x3;
    final double y =
        mt * mt * mt * y0 +
        3 * mt * mt * t * y1 +
        3 * mt * t * t * y2 +
        t * t * t * y3;

    drawThickLine(image, prevX, prevY, x.round(), y.round(), thickness, color);

    prevX = x.round();
    prevY = y.round();
  }
}

// Helper: Fill a triangle using scanline algorithm
void fillTriangle(
  img.Image image,
  int x0,
  int y0,
  int x1,
  int y1,
  int x2,
  int y2,
  img.Color color,
) {
  // Sort vertices by y coordinate
  List<List<int>> vertices = [
    [x0, y0],
    [x1, y1],
    [x2, y2],
  ];
  vertices.sort((a, b) => a[1].compareTo(b[1]));

  final int ax = vertices[0][0], ay = vertices[0][1];
  final int bx = vertices[1][0], by = vertices[1][1];
  final int cx = vertices[2][0], cy = vertices[2][1];

  // Scanline fill
  for (int y = ay; y <= cy; y++) {
    double xStart, xEnd;

    if (y < by) {
      // Upper part of triangle
      if (by != ay) {
        xStart = ax + (bx - ax) * (y - ay) / (by - ay);
      } else {
        xStart = ax.toDouble();
      }
      if (cy != ay) {
        xEnd = ax + (cx - ax) * (y - ay) / (cy - ay);
      } else {
        xEnd = ax.toDouble();
      }
    } else {
      // Lower part of triangle
      if (cy != by) {
        xStart = bx + (cx - bx) * (y - by) / (cy - by);
      } else {
        xStart = bx.toDouble();
      }
      if (cy != ay) {
        xEnd = ax + (cx - ax) * (y - ay) / (cy - ay);
      } else {
        xEnd = cx.toDouble();
      }
    }

    if (xStart > xEnd) {
      final double temp = xStart;
      xStart = xEnd;
      xEnd = temp;
    }

    for (int x = xStart.round(); x <= xEnd.round(); x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }
}

// Helper: Fill a circle
void fillCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}
