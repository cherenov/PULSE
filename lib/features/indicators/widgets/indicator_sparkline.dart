import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/features/indicators/indicator_info.dart';
import 'package:pulse/theme/app_colors.dart';

class IndicatorSparkline extends StatelessWidget {
  final MetricDef metric;
  final List<Measurement> records;

  const IndicatorSparkline({
    super.key,
    required this.metric,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final values = records
        .where((r) => r.values[0] != null)
        .map((r) => r.values[0]!)
        .toList();
    if (values.length < 2) return const SizedBox.shrink();

    final recent = values.length > 16
        ? values.sublist(values.length - 16)
        : values;

    return CustomPaint(
      painter: SparklinePainter(
        values: recent,
        metric: metric,
      ),
      size: Size.infinite,
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> values;
  final MetricDef metric;

  SparklinePainter({
    required this.values,
    required this.metric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    final normalMin = metric.normal[0][0];
    final normalMax = metric.normal[0][1];
    final allY = <double>[...values, ?normalMin, ?normalMax];
    final minY = allY.reduce(min);
    final maxY = allY.reduce(max);
    final span = maxY - minY;
    final pad = span > 0 ? span * 0.15 : 1.0;
    final lo = minY - pad;
    final hi = maxY + pad;
    final range = hi - lo;

    Offset point(int i, double y) {
      final x = i / (values.length - 1) * size.width;
      final py = size.height - ((y - lo) / range) * size.height;
      return Offset(x, py);
    }

    if (normalMin != null) {
      _drawDashedHLine(canvas, size, point(0, normalMin).dy);
    }
    if (normalMax != null) {
      _drawDashedHLine(canvas, size, point(0, normalMax).dy);
    }

    final cuts = <double>{
      ...[?metric.critical[0][0], ?metric.critical[0][1]],
      ...[?normalMin, ?normalMax],
    }.toList()..sort();

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    var piece = <Offset>[];
    MetricStatus? pieceStatus;

    void flush() {
      if (piece.length > 1 && pieceStatus != null) {
        paint.color = statusColor(pieceStatus!);
        final path = Path()..moveTo(piece.first.dx, piece.first.dy);
        for (var i = 1; i < piece.length; i++) {
          path.lineTo(piece[i].dx, piece[i].dy);
        }
        canvas.drawPath(path, paint);
      }
      piece = [];
    }

    void addSegment(Offset a, Offset b, double ya, double yb) {
      final status = metric.fieldStatus(0, (ya + yb) / 2);
      if (status != pieceStatus) {
        flush();
        pieceStatus = status;
        piece = [a];
      }
      piece.add(b);
    }

    for (var i = 0; i < values.length - 1; i++) {
      final ya = values[i];
      final yb = values[i + 1];
      final a = point(i, ya);
      final b = point(i + 1, yb);
      final loY = min(ya, yb);
      final hiY = max(ya, yb);
      final inside = cuts.where((c) => c > loY && c < hiY).toList();
      final crossings = ya < yb ? inside : inside.reversed.toList();

      var from = a;
      var fromY = ya;
      for (final c in crossings) {
        final t = (c - ya) / (yb - ya);
        final mid = Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        );
        addSegment(from, mid, fromY, c);
        from = mid;
        fromY = c;
      }
      addSegment(from, b, fromY, yb);
    }
    flush();
  }

  void _drawDashedHLine(Canvas canvas, Size size, double y) {
    final paint = Paint()
      ..color = AppColors.ok.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.metric.id != metric.id ||
        oldDelegate.values.length != values.length ||
        !_listEquals(oldDelegate.values, values);
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
