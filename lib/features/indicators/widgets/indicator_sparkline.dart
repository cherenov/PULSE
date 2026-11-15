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
    if (records.isEmpty) return const SizedBox.shrink();

    final recent = records.length > 16
        ? records.sublist(records.length - 16)
        : records;
    if (recent.length < 2) return const SizedBox.shrink();

    final hasLine = List.generate(metric.fields.length, (index) {
      var count = 0;
      for (final record in recent) {
        if (record.values[index] != null) count++;
      }
      return count >= 2;
    }).any((hasLine) => hasLine);

    if (!hasLine) return const SizedBox.shrink();

    return CustomPaint(
      painter: SparklinePainter(metric: metric, records: recent),
      size: Size.infinite,
    );
  }
}

class SparklinePainter extends CustomPainter {
  final MetricDef metric;
  final List<Measurement> records;

  SparklinePainter({required this.metric, required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.length < 2 || size.width <= 0 || size.height <= 0) return;

    final activeField = _activeField();

    final allValues = <double>[
      for (var field = 0; field < metric.fields.length; field++)
        for (final record in records)
          if (record.values[field] != null) record.values[field]!,
    ];
    final normalMin = metric.normal[activeField][0];
    final normalMax = metric.normal[activeField][1];
    final allY = <double>[...allValues, ?normalMin, ?normalMax];
    if (allY.isEmpty) return;

    final minY = allY.reduce(min);
    final maxY = allY.reduce(max);
    final span = maxY - minY;
    final pad = span > 0 ? span * 0.15 : 1.0;
    final lo = minY - pad;
    final hi = maxY + pad;
    final range = hi - lo;
    final stepX = 1 / (records.length - 1);

    Offset point(int recordIndex, double value) {
      final x = recordIndex * stepX * size.width;
      final y = size.height - ((value - lo) / range) * size.height;
      return Offset(x, y);
    }

    if (normalMin != null) {
      _drawDashedHLine(canvas, size, point(0, normalMin).dy);
    }
    if (normalMax != null) {
      _drawDashedHLine(canvas, size, point(0, normalMax).dy);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (var field = 0; field < metric.fields.length; field++) {
      if (field == activeField) continue;

      paint
        ..color = AppColors.metricFields[field % AppColors.metricFields.length]
            .withValues(alpha: 0.35)
        ..strokeWidth = 1.1;
      _drawPlainLine(canvas, field, point, paint);
    }

    paint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawZonedLine(canvas, activeField, size, point, paint);

    final singlePoint = _singlePoint(activeField);
    if (singlePoint != null) {
      canvas.drawCircle(
        point(singlePoint.index, singlePoint.value),
        1.8,
        Paint()
          ..color = statusColor(
            metric.fieldStatus(activeField, singlePoint.value),
          )
          ..isAntiAlias = true,
      );
    }
  }

  int _activeField() {
    var bestIndex = 0;
    var bestStatus = MetricStatus.ok;
    var found = false;

    for (var field = 0; field < metric.fields.length; field++) {
      final value = _latestValue(field);
      if (value == null) continue;

      final status = metric.fieldStatus(field, value);
      if (!found || status.index > bestStatus.index) {
        bestIndex = field;
        bestStatus = status;
        found = true;
      }
    }

    return bestIndex;
  }

  double? _latestValue(int field) {
    double? value;
    DateTime? latest;

    for (final record in records) {
      final next = record.values[field];
      if (next == null) continue;

      if (latest == null || record.takenAt.isAfter(latest)) {
        value = next;
        latest = record.takenAt;
      }
    }

    return value;
  }

  _SparkPoint? _singlePoint(int field) {
    _SparkPoint? result;
    var count = 0;

    for (var index = 0; index < records.length; index++) {
      final value = records[index].values[field];
      if (value == null) continue;

      count++;
      result = _SparkPoint(index: index, value: value);
    }

    return count == 1 ? result : null;
  }

  void _drawPlainLine(
    Canvas canvas,
    int field,
    Offset Function(int, double) point,
    Paint paint,
  ) {
    Path? path;
    int? previousIndex;

    void flush() {
      if (path != null) canvas.drawPath(path!, paint);
      path = null;
    }

    for (var index = 0; index < records.length; index++) {
      final value = records[index].values[field];
      if (value == null) {
        flush();
        previousIndex = null;
        continue;
      }

      final next = point(index, value);
      if (path == null || previousIndex == null || index - previousIndex != 1) {
        flush();
        path = Path()..moveTo(next.dx, next.dy);
      } else {
        path!.lineTo(next.dx, next.dy);
      }
      previousIndex = index;
    }
    flush();
  }

  void _drawZonedLine(
    Canvas canvas,
    int field,
    Size size,
    Offset Function(int, double) point,
    Paint paint,
  ) {
    final cuts = <double>{
      ...[?metric.critical[field][0], ?metric.critical[field][1]],
      ...[?metric.normal[field][0], ?metric.normal[field][1]],
    }.toList()..sort();

    var piece = <Offset>[];
    MetricStatus? pieceStatus;

    void flush() {
      if (piece.length > 1 && pieceStatus != null) {
        final status = pieceStatus!;
        final color = statusColor(status);
        final path = Path()..moveTo(piece.first.dx, piece.first.dy);
        for (var i = 1; i < piece.length; i++) {
          path.lineTo(piece[i].dx, piece[i].dy);
        }

        if (status != MetricStatus.ok) {
          final area = Path.from(path)
            ..lineTo(piece.last.dx, size.height)
            ..lineTo(piece.first.dx, size.height)
            ..close();
          canvas.drawPath(
            area,
            Paint()
              ..color = color.withValues(
                alpha: status == MetricStatus.critical ? 0.16 : 0.10,
              )
              ..style = PaintingStyle.fill
              ..isAntiAlias = true,
          );
        }

        final strokeWidth = switch (status) {
          MetricStatus.ok => 2.0,
          MetricStatus.warning => 2.6,
          MetricStatus.critical => 3.0,
        };

        if (status != MetricStatus.ok) {
          final isCritical = status == MetricStatus.critical;
          canvas.drawPath(
            path,
            Paint()
              ..color = color.withValues(alpha: isCritical ? 0.75 : 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 1.6
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                isCritical ? 5.0 : 3.5,
              )
              ..isAntiAlias = true,
          );
        }

        paint
          ..color = color
          ..strokeWidth = strokeWidth
          ..maskFilter = null;
        canvas.drawPath(path, paint);
      }
      piece = [];
    }

    void add(Offset a, double ya, Offset b, double yb) {
      final status = metric.fieldStatus(field, (ya + yb) / 2);
      if (status != pieceStatus) {
        flush();
        pieceStatus = status;
        piece = [a];
      }
      piece.add(b);
    }

    double? previousValue;
    int? previousIndex;

    for (var index = 0; index < records.length; index++) {
      final value = records[index].values[field];
      if (value == null) {
        flush();
        previousValue = null;
        previousIndex = null;
        continue;
      }

      if (previousValue == null ||
          previousIndex == null ||
          index - previousIndex != 1) {
        flush();
      } else {
        final a = point(previousIndex, previousValue);
        final b = point(index, value);
        final loY = min(previousValue, value);
        final hiY = max(previousValue, value);
        final inside = cuts.where((c) => c > loY && c < hiY).toList();
        final crossings = previousValue < value
            ? inside
            : inside.reversed.toList();

        var from = a;
        var fromY = previousValue;
        for (final cut in crossings) {
          final t = (cut - previousValue) / (value - previousValue);
          final mid = Offset(
            a.dx + (b.dx - a.dx) * t,
            a.dy + (b.dy - a.dy) * t,
          );
          add(from, fromY, mid, cut);
          from = mid;
          fromY = cut;
        }
        add(from, fromY, b, value);
      }

      previousValue = value;
      previousIndex = index;
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
        !_recordsEqual(oldDelegate.records, records);
  }

  bool _recordsEqual(List<Measurement> a, List<Measurement> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i].takenAt != b[i].takenAt) return false;

      final av = a[i].values;
      final bv = b[i].values;
      for (var j = 0; j < av.length; j++) {
        if (av[j] != bv[j]) return false;
      }
    }

    return true;
  }
}

class _SparkPoint {
  const _SparkPoint({required this.index, required this.value});

  final int index;
  final double value;
}
