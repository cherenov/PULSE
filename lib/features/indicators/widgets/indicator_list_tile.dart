import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/features/indicators/widgets/indicator_sparkline.dart';
import 'package:pulse/theme/app_colors.dart';

class IndicatorListTile extends ConsumerWidget {
  final MetricDef metric;
  final Measurement? measurement;
  final VoidCallback? onTap;

  const IndicatorListTile({
    super.key,
    required this.metric,
    required this.measurement,
    this.onTap,
  });

  MetricStatus? get status {
    if (measurement == null) return null;

    return metric.status(
      measurement!.values.take(metric.fields.length).toList(),
    );
  }

  Color _colorForStatus(MetricStatus? s) {
    switch (s) {
      case MetricStatus.ok:
        return AppColors.ok;
      case MetricStatus.warning:
        return AppColors.warning;
      case MetricStatus.critical:
        return AppColors.critical;
      case null:
        return AppColors.textDisabled;
    }
  }

  Color get statusColor => _colorForStatus(status);

  String get statusLabel {
    switch (status) {
      case MetricStatus.ok:
        return 'Normal';
      case MetricStatus.warning:
        return 'Warning';
      case MetricStatus.critical:
        return 'Critical';
      case null:
        return 'No data';
    }
  }

  String get formattedValue {
    final record = measurement;
    if (record == null) return '—';

    final values = record.values;
    final lines = <String>[];

    for (var i = 0; i < metric.fields.length; i++) {
      final value = values[i];
      if (value == null) continue;

      final formatted = metric.format(value);

      if (metric.fields.length == 1) {
        lines.add('$formatted ${metric.unit}');
      } else {
        lines.add('${metric.fields[i]}: $formatted ${metric.unit}');
      }
    }

    return lines.isEmpty ? '—' : lines.join('\n');
  }

  String get recordedTime {
    final record = measurement;
    if (record == null) return '';

    final date = record.takenAt.toLocal();
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today, $hours:$minutes';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month, $hours:$minutes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = measurement != null;
    final color = statusColor;
    final historyAsync = ref.watch(recentIndicatorHistoryProvider(metric.id));

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 51,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasData
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: hasData ? color : AppColors.textDisabled,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (hasData) ...[
                const SizedBox(width: 8),
                RepaintBoundary(
                  child: SizedBox(
                    width: 64,
                    height: 36,
                    child: historyAsync.maybeWhen(
                      // Fallback: FlChartMiniSparkline in
                      // indicator_sparkline_fl_chart.dart
                      data: (records) => IndicatorSparkline(
                        metric: metric,
                        records: records,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 10),

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      textAlign: TextAlign.end,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasData
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                        fontSize: hasData ? 13 : 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(height: 6),
                      Text(
                        recordedTime,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
