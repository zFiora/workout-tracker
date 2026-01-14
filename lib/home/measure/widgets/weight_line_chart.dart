import 'package:flutter/material.dart';
import '../models/measurement_entry.dart';

class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.entries,
    required this.minY,
    required this.maxY,
  });

  final List<MeasurementEntry> entries;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(
        child: Text('Add at least 2 entries to see the graph'),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        return CustomPaint(
          size: Size(double.infinity, c.maxHeight),
          painter: _LinePainter(
            entries: entries,
            minY: minY,
            maxY: maxY,
            lineColor: Theme.of(context).colorScheme.primary,
            gridColor: Theme.of(context).dividerColor,
            textStyle: Theme.of(context).textTheme.bodySmall!,
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.entries,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    required this.gridColor,
    required this.textStyle,
  });

  final List<MeasurementEntry> entries;
  final double minY;
  final double maxY;
  final Color lineColor;
  final Color gridColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(12, 12, 12, 24);
    final w = size.width - padding.left - padding.right;
    final h = size.height - padding.top - padding.bottom;

    final rect = Rect.fromLTWH(padding.left, padding.top, w, h);

    // Grid (3 horizontal lines)
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = rect.top + (h * i / 3);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    // Points
    final points = <Offset>[];
    for (int i = 0; i < entries.length; i++) {
      final x = rect.left + (w * i / (entries.length - 1));
      final yVal = entries[i].weightKg;
      final t = ((yVal - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final y = rect.bottom - (h * t);
      points.add(Offset(x, y));
    }

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }

    // Min/Max labels (simple)
    _drawText(canvas, '${maxY.toStringAsFixed(1)} kg',
        Offset(rect.left, rect.top - 2));
    _drawText(canvas, '${minY.toStringAsFixed(1)} kg',
        Offset(rect.left, rect.bottom - 14));
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
