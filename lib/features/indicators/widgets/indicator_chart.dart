import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/features/indicators/indicator_info.dart';
import 'package:pulse/theme/app_colors.dart';

const _fieldPalette = AppColors.metricFields;

class IndicatorChart extends ConsumerStatefulWidget {
  final MetricDef metric;

  const IndicatorChart({super.key, required this.metric});

  @override
  ConsumerState<IndicatorChart> createState() => _IndicatorChartState();
}

class _IndicatorChartState extends ConsumerState<IndicatorChart> {
  int selectedDays = 7;
  bool smooth = true;
  int selectedField = 0;
  late DateTime periodEnd;

  @override
  void initState() {
    super.initState();
    periodEnd = DateTime.now();
  }

  @override
  void didUpdateWidget(covariant IndicatorChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric.id != widget.metric.id) {
      selectedField = 0;
      selectedDays = 7;
      periodEnd = DateTime.now();
    }
  }

  void selectPeriod(int days) {
    setState(() {
      selectedDays = days;
      periodEnd = DateTime.now();
    });
  }

  Color _fieldColor(int index) => _fieldPalette[index % _fieldPalette.length];

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final from = periodEnd.subtract(Duration(days: selectedDays));
    final query = (metricId: metric.id, from: from, to: periodEnd);
    final measurementsAsync = ref.watch(seriesProvider(query));
    final history = ref
        .watch(indicatorHistoryProvider(metric.id))
        .asData
        ?.value;
    final latestValues = _latestValues(history, metric.fields.length);
    final interactive = metric.fields.length > 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Measurement chart',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodButton(
                  label: '7D',
                  selected: selectedDays == 7,
                  onTap: () => selectPeriod(7),
                ),
                _PeriodButton(
                  label: '30D',
                  selected: selectedDays == 30,
                  onTap: () => selectPeriod(30),
                ),
                _PeriodButton(
                  label: '90D',
                  selected: selectedDays == 90,
                  onTap: () => selectPeriod(90),
                ),
                _PeriodButton(
                  label: '1Y',
                  selected: selectedDays == 365,
                  onTap: () => selectPeriod(365),
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  color: AppColors.border,
                ),
                _PeriodButton(
                  label: 'Smooth',
                  selected: smooth,
                  onTap: () => setState(() => smooth = !smooth),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          measurementsAsync.when(
            loading: () => const SizedBox(
              height: 240,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (error, stack) => SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  'Unable to load chart data.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            data: (measurements) {
              final series = _buildSeries(metric, measurements, from);
              final hasData = series.any((s) => s.points.isNotEmpty);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 240,
                    child: _buildChart(
                      metric: metric,
                      series: series,
                      from: from,
                    ),
                  ),
                  if (!hasData) ...[
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'No measurements for this period',
                        style: TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < metric.fields.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FieldRow(
                label: metric.fields[index],
                color: _fieldColor(index),
                detail: _fieldRangeText(metric, index),
                value: _valueText(metric, latestValues[index]),
                status: latestValues[index] == null
                    ? null
                    : metric.fieldStatus(index, latestValues[index]!),
                selected: interactive && selectedField == index,
                interactive: interactive,
                onTap: () => setState(() => selectedField = index),
              ),
            ),
        ],
      ),
    );
  }

  List<_FieldSeries> _buildSeries(
    MetricDef metric,
    List<Measurement> measurements,
    DateTime from,
  ) {
    final result = <_FieldSeries>[];

    for (var index = 0; index < metric.fields.length; index++) {
      final records =
          measurements.where((m) => m.values[index] != null).toList()
            ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

      final points = <_FieldPoint>[];
      for (final measurement in records) {
        final value = measurement.values[index]!;
        final x =
            measurement.takenAt.difference(from).inSeconds /
            Duration.secondsPerDay;
        final point = _FieldPoint(
          x: x,
          y: metric.roundValue(value),
          value: value,
          time: measurement.takenAt,
        );

        if (points.isNotEmpty && (point.x - points.last.x).abs() < 1e-6) {
          points[points.length - 1] = point;
        } else {
          points.add(point);
        }
      }

      result.add(
        _FieldSeries(
          index: index,
          points: points,
          normalMin: metric.normal[index][0],
          normalMax: metric.normal[index][1],
          criticalMin: metric.critical[index][0],
          criticalMax: metric.critical[index][1],
        ),
      );
    }

    return result;
  }

  Widget _buildChart({
    required MetricDef metric,
    required List<_FieldSeries> series,
    required DateTime from,
  }) {
    final focused = series.firstWhere(
      (s) => s.index == selectedField,
      orElse: () => series.first,
    );

    final chartValues = <double>[
      for (final s in series) ...s.points.map((p) => p.y),
      if (focused.normalMin != null) focused.normalMin!,
      if (focused.normalMax != null) focused.normalMax!,
      if (focused.criticalMin != null) focused.criticalMin!,
      if (focused.criticalMax != null) focused.criticalMax!,
    ];

    if (chartValues.isEmpty) {
      chartValues.addAll(metric.limits[focused.index]);
    }
    if (chartValues.isEmpty) {
      chartValues.addAll(const [0, 1]);
    }

    final lowest = chartValues.reduce(min);
    final highest = chartValues.reduce(max);
    final span = highest - lowest;
    final padding = span > 0
        ? span * 0.20
        : (highest.abs() * 0.15).clamp(1.0, double.infinity);

    final chartMinY = lowest - padding;
    final chartMaxY = highest + padding;
    final ySpan = chartMaxY - chartMinY;
    final yTickStep = (ySpan / 80).clamp(0.0001, double.infinity);
    final thresholds = _uniqueThresholds(focused);

    final bars = <LineChartBarData>[];
    final barFields = <int>[];

    for (final s in series.where((s) => s.index != focused.index)) {
      final spots = smooth ? _smooth(s.rawSpots) : s.rawSpots;
      if (spots.isEmpty) continue;

      bars.add(_mutedLine(s, spots));
      barFields.add(s.index);
    }

    final activeSpots = smooth ? _smooth(focused.rawSpots) : focused.rawSpots;
    if (activeSpots.length > 1) {
      final zoneBars = _zoneLines(metric, focused.index, activeSpots);
      bars.addAll(zoneBars);
      barFields.addAll(List.filled(zoneBars.length, focused.index));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: selectedDays.toDouble(),
        minY: chartMinY,
        maxY: chartMaxY,
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (focused.normalMin != null || focused.normalMax != null)
              HorizontalRangeAnnotation(
                y1: focused.normalMin ?? chartMinY,
                y2: focused.normalMax ?? chartMaxY,
                color: AppColors.ok.withValues(alpha: 0.07),
              ),
            if (focused.criticalMin != null && focused.criticalMin! > chartMinY)
              HorizontalRangeAnnotation(
                y1: chartMinY,
                y2: focused.criticalMin!,
                color: AppColors.critical.withValues(alpha: 0.06),
              ),
            if (focused.criticalMax != null && focused.criticalMax! < chartMaxY)
              HorizontalRangeAnnotation(
                y1: focused.criticalMax!,
                y2: chartMaxY,
                color: AppColors.critical.withValues(alpha: 0.06),
              ),
          ],
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (focused.normalMin != null)
              HorizontalLine(
                y: focused.normalMin!,
                color: _fieldColor(focused.index).withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            if (focused.normalMax != null)
              HorizontalLine(
                y: focused.normalMax!,
                color: _fieldColor(focused.index).withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            if (focused.criticalMin != null)
              HorizontalLine(
                y: focused.criticalMin!,
                color: AppColors.critical.withValues(alpha: 0.55),
                strokeWidth: 1.2,
                dashArray: const [6, 4],
              ),
            if (focused.criticalMax != null)
              HorizontalLine(
                y: focused.criticalMax!,
                color: AppColors.critical.withValues(alpha: 0.55),
                strokeWidth: 1.2,
                dashArray: const [6, 4],
              ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchSpotThreshold: 32,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            maxContentWidth: 230,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorder: const BorderSide(color: AppColors.border),
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (touchedSpots) => _tooltipItems(
              metric: metric,
              series: series,
              barFields: barFields,
              touchedSpots: touchedSpots,
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yTickStep,
              getTitlesWidget: (value, meta) {
                final threshold = _nearestThreshold(
                  thresholds,
                  value,
                  yTickStep * 0.45,
                );
                if (threshold == null) return const SizedBox.shrink();

                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    metric.format(threshold),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: selectedDays / 4,
              getTitlesWidget: (value, meta) {
                final date = from.add(
                  Duration(seconds: (value * Duration.secondsPerDay).round()),
                );
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    _dayMonth(date),
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: bars,
      ),
    );
  }

  List<LineTooltipItem?> _tooltipItems({
    required MetricDef metric,
    required List<_FieldSeries> series,
    required List<int> barFields,
    required List<LineBarSpot> touchedSpots,
  }) {
    final seen = <int>{};

    return [
      for (final touched in touchedSpots)
        _tooltipItemFor(
          metric: metric,
          series: series,
          barFields: barFields,
          touched: touched,
          seen: seen,
        ),
    ];
  }

  LineTooltipItem? _tooltipItemFor({
    required MetricDef metric,
    required List<_FieldSeries> series,
    required List<int> barFields,
    required LineBarSpot touched,
    required Set<int> seen,
  }) {
    if (touched.barIndex < 0 || touched.barIndex >= barFields.length) {
      return null;
    }

    final fieldIndex = barFields[touched.barIndex];
    if (!seen.add(fieldIndex)) return null;

    _FieldSeries? field;
    for (final candidate in series) {
      if (candidate.index == fieldIndex) {
        field = candidate;
        break;
      }
    }

    final point = field?.nearest(touched.x);
    if (field == null || point == null) return null;

    final status = metric.fieldStatus(fieldIndex, point.value);
    final multiField = metric.fields.length > 1;

    return LineTooltipItem(
      multiField ? '${metric.fields[fieldIndex]}  ' : '',
      TextStyle(
        color: _fieldColor(fieldIndex),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      children: [
        TextSpan(
          text: '${metric.format(point.value)} ${metric.unit}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (multiField)
          TextSpan(
            text: '  ${_dayMonth(point.time)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        if (status != MetricStatus.ok)
          TextSpan(
            text:
                '  ${status == MetricStatus.critical ? 'critical' : 'caution'}',
            style: TextStyle(
              color: statusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  LineChartBarData _mutedLine(_FieldSeries series, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: _fieldColor(series.index).withValues(alpha: 0.28),
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, MetricStatus status) {
    final barWidth = switch (status) {
      MetricStatus.ok => 2.5,
      MetricStatus.warning => 3.4,
      MetricStatus.critical => 4.2,
    };
    final shadow = switch (status) {
      MetricStatus.ok => const Shadow(color: Colors.transparent),
      MetricStatus.warning => Shadow(
        color: statusColor(MetricStatus.warning).withValues(alpha: 0.55),
        blurRadius: 8,
      ),
      MetricStatus.critical => Shadow(
        color: statusColor(MetricStatus.critical).withValues(alpha: 0.75),
        blurRadius: 12,
      ),
    };

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: const FlDotData(show: false),
      shadow: shadow,
      belowBarData: status == MetricStatus.ok
          ? BarAreaData(show: false)
          : BarAreaData(
              show: true,
              color: color.withValues(
                alpha: status == MetricStatus.critical ? 0.16 : 0.10,
              ),
            ),
    );
  }

  List<LineChartBarData> _zoneLines(
    MetricDef metric,
    int field,
    List<FlSpot> spots,
  ) {
    final cuts = <double>{
      ...[?metric.critical[field][0], ?metric.critical[field][1]],
      ...[?metric.normal[field][0], ?metric.normal[field][1]],
    }.toList()..sort();

    final bars = <LineChartBarData>[];
    var piece = <FlSpot>[];
    MetricStatus? pieceStatus;

    void flush() {
      if (piece.length > 1 && pieceStatus != null) {
        bars.add(_line(piece, statusColor(pieceStatus!), pieceStatus!));
      }
      piece = [];
    }

    void add(FlSpot a, FlSpot b) {
      final status = metric.fieldStatus(field, (a.y + b.y) / 2);
      if (status != pieceStatus) {
        flush();
        pieceStatus = status;
        piece = [a];
      }
      piece.add(b);
    }

    for (var i = 0; i < spots.length - 1; i++) {
      final a = spots[i];
      final b = spots[i + 1];
      final lo = a.y < b.y ? a.y : b.y;
      final hi = a.y < b.y ? b.y : a.y;
      final inside = cuts.where((c) => c > lo && c < hi).toList();
      final crossings = a.y < b.y ? inside : inside.reversed.toList();

      var from = a;
      for (final c in crossings) {
        final t = (c - a.y) / (b.y - a.y);
        final point = FlSpot(a.x + (b.x - a.x) * t, c);
        add(from, point);
        from = point;
      }
      add(from, b);
    }
    flush();
    return bars;
  }

  List<FlSpot> _smooth(List<FlSpot> pts) {
    if (pts.length < 3) return pts;

    final xs = <double>[];
    final ys = <double>[];
    for (final p in pts) {
      if (xs.isNotEmpty && p.x - xs.last < 1e-9) {
        ys[ys.length - 1] = p.y;
      } else {
        xs.add(p.x);
        ys.add(p.y);
      }
    }

    final n = xs.length;
    if (n < 3) return pts;

    final d = List<double>.filled(n - 1, 0);
    for (var i = 0; i < n - 1; i++) {
      d[i] = (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]);
    }

    final m = List<double>.filled(n, 0);
    m[0] = d[0];
    m[n - 1] = d[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }

    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i];
      final b = m[i + 1] / d[i];
      final s = a * a + b * b;
      if (s > 9) {
        final t = 3 / sqrt(s);
        m[i] = t * a * d[i];
        m[i + 1] = t * b * d[i];
      }
    }

    final steps = (240 / (n - 1)).round().clamp(2, 16);
    final out = <FlSpot>[];
    for (var i = 0; i < n - 1; i++) {
      final h = xs[i + 1] - xs[i];
      for (var s = 0; s < steps; s++) {
        final t = s / steps;
        final t2 = t * t;
        final t3 = t2 * t;
        final y =
            (2 * t3 - 3 * t2 + 1) * ys[i] +
            (t3 - 2 * t2 + t) * h * m[i] +
            (-2 * t3 + 3 * t2) * ys[i + 1] +
            (t3 - t2) * h * m[i + 1];
        out.add(FlSpot(xs[i] + h * t, y));
      }
    }
    out.add(FlSpot(xs.last, ys.last));
    return out;
  }
}

Map<int, double> _latestValues(List<Measurement>? history, int fieldCount) {
  final values = <int, double>{};
  final times = <int, DateTime>{};

  for (final measurement in history ?? const <Measurement>[]) {
    for (var index = 0; index < fieldCount; index++) {
      final value = measurement.values[index];
      if (value == null) continue;

      final previous = times[index];
      if (previous == null || measurement.takenAt.isAfter(previous)) {
        values[index] = value;
        times[index] = measurement.takenAt;
      }
    }
  }

  return values;
}

List<double> _uniqueThresholds(_FieldSeries series) {
  final values = <double>[
    if (series.normalMin != null) series.normalMin!,
    if (series.normalMax != null) series.normalMax!,
    if (series.criticalMin != null) series.criticalMin!,
    if (series.criticalMax != null) series.criticalMax!,
  ]..sort();

  final result = <double>[];
  for (final value in values) {
    if (result.isEmpty || (value - result.last).abs() > 1e-9) {
      result.add(value);
    }
  }
  return result;
}

double? _nearestThreshold(
  List<double> thresholds,
  double value,
  double tolerance,
) {
  double? best;
  var bestDistance = tolerance;

  for (final threshold in thresholds) {
    final distance = (threshold - value).abs();
    if (distance <= bestDistance) {
      best = threshold;
      bestDistance = distance;
    }
  }

  return best;
}

String _dayMonth(DateTime value) {
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String _valueText(MetricDef metric, double? value) {
  if (value == null) return '—';
  return '${metric.format(value)} ${metric.unit}';
}

String _normalRangeText(MetricDef metric, int index) {
  final min = metric.normal[index][0];
  final max = metric.normal[index][1];

  if (min != null && max != null) {
    return '${metric.format(min)}–${metric.format(max)}';
  }
  if (min != null) return '≥${metric.format(min)}';
  if (max != null) return '≤${metric.format(max)}';
  return '—';
}

String _criticalRangeText(MetricDef metric, int index) {
  final min = metric.critical[index][0];
  final max = metric.critical[index][1];

  if (min != null && max != null) {
    return '<${metric.format(min)} / >${metric.format(max)}';
  }
  if (min != null) return '<${metric.format(min)}';
  if (max != null) return '>${metric.format(max)}';
  return '—';
}

String _fieldRangeText(MetricDef metric, int index) {
  final normal = _normalRangeText(metric, index);
  final critical = _criticalRangeText(metric, index);

  if (normal == '—' && critical == '—') {
    return 'Ranges not specified';
  }
  return 'Norm: $normal · Crit: $critical';
}

class _FieldPoint {
  const _FieldPoint({
    required this.x,
    required this.y,
    required this.value,
    required this.time,
  });

  final double x;
  final double y;
  final double value;
  final DateTime time;
}

class _FieldSeries {
  _FieldSeries({
    required this.index,
    required this.points,
    required this.normalMin,
    required this.normalMax,
    required this.criticalMin,
    required this.criticalMax,
  }) : byX = {for (final point in points) point.x: point};

  final int index;
  final List<_FieldPoint> points;
  final double? normalMin;
  final double? normalMax;
  final double? criticalMin;
  final double? criticalMax;
  final Map<double, _FieldPoint> byX;

  List<FlSpot> get rawSpots => [
    for (final point in points) FlSpot(point.x, point.y),
  ];

  _FieldPoint? nearest(double x) {
    _FieldPoint? best;
    var bestDistance = double.infinity;

    for (final point in points) {
      final distance = (point.x - x).abs();
      if (distance < bestDistance) {
        best = point;
        bestDistance = distance;
      }
    }

    return best;
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String detail;
  final String value;
  final Color color;
  final MetricStatus? status;
  final bool selected;
  final bool interactive;
  final VoidCallback onTap;

  const _FieldRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.color,
    required this.status,
    required this.selected,
    required this.interactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null && status != MetricStatus.ok;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: value == '—'
                      ? AppColors.textDisabled
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasStatus) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor(status!),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final backgroundColor = interactive && selected
        ? AppColors.surfaceHigh
        : Colors.transparent;
    final borderColor = interactive && selected
        ? color.withValues(alpha: 0.55)
        : Colors.transparent;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: interactive ? InkWell(onTap: onTap, child: content) : content,
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.accent : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
