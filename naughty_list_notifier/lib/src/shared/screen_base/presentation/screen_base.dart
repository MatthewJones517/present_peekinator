import 'package:flutter/material.dart';

class ScreenBase extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const ScreenBase({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar:
          appBar ??
          AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 4,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            automaticallyImplyLeading: false,
            title: const Text(
              'North Pole Network',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFFDAA520), // Goldenrod (lighter gold)
                    Color(0xFFB8860B), // Dark goldenrod (medium gold)
                    Color(0xFF8B6914), // Darker gold
                  ],
                ),
              ),
            ),
          ),
      body: Stack(
        children: [
          // Background with striped border - extends to full screen
          Positioned.fill(
            child: Image.asset('assets/background.png', fit: BoxFit.cover),
          ),
          // SafeArea for header and beige box content
          SafeArea(
            child: Stack(
              children: [
                // Beige center area with dotted border
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 140, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5DC), // Beige/off-white color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Dotted border using CustomPaint
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DottedBorderPainter(
                                borderColor: const Color(
                                  0xFF8B0000,
                                ), // Dark red
                                borderWidth: 2,
                                dashWidth: 8,
                                dashSpace: 4,
                                radius: 12,
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Header at the top - slightly overlapping the border
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset('assets/header.png', fit: BoxFit.fitWidth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DottedBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            borderWidth / 2,
            borderWidth / 2,
            size.width - borderWidth,
            size.height - borderWidth,
          ),
          Radius.circular(radius),
        ),
      );

    // Draw dashed border along the path
    final dashLength = dashWidth;
    final dashSpace = this.dashSpace;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < pathMetric.length) {
        if (draw) {
          final extractPath = pathMetric.extractPath(
            distance,
            distance + dashLength,
          );
          canvas.drawPath(extractPath, paint);
        }
        distance += draw ? dashLength : dashSpace;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
