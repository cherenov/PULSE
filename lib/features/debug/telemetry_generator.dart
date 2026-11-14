import 'dart:math';

import 'package:drift/drift.dart';
import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/metrics_registory.dart';

class TelemetryGenerator {
  final Random _random = Random();

  Future<int> generateForAllMetrics({
    required Db db,
    required int profileId,
    int days = 30,
    int frequencyHours = 6,
    double warningChance = 0.15,
    double criticalChance = 0.05,
    bool clearExisting = false,
  }) async {
    if (clearExisting) {
      await db.deleteAllData(profileId);
    }

    final now = DateTime.now().toUtc();
    final startDate = now.subtract(Duration(days: days));
    final count = (days * 24 / frequencyHours).floor();
    final companions = <MeasurementsCompanion>[];

    for (final metric in metrics) {
      final series = _generateMetricSeries(
        metric: metric,
        count: count,
        startDate: startDate,
        frequencyHours: frequencyHours,
        warningChance: warningChance,
        criticalChance: criticalChance,
      );

      for (final entry in series.entries) {
        final vals = entry.value;
        companions.add(
          MeasurementsCompanion.insert(
            profileId: profileId,
            metricId: metric.id,
            takenAt: entry.key,
            v0: vals[0],
            v1: Value(vals.length > 1 ? vals[1] : null),
            v2: Value(vals.length > 2 ? vals[2] : null),
            v3: Value(vals.length > 3 ? vals[3] : null),
          ),
        );
      }
    }

    await db.batch((batch) {
      batch.insertAll(db.measurements, companions);
    });

    return companions.length;
  }

  Map<DateTime, List<double>> _generateMetricSeries({
    required MetricDef metric,
    required int count,
    required DateTime startDate,
    required int frequencyHours,
    required double warningChance,
    required double criticalChance,
  }) {
    final result = <DateTime, List<double>>{};
    final fieldCount = metric.fields.length;

    // Текущие значения для плавного движения
    final currentValues = List<double>.generate(fieldCount, (i) {
      final nMin = metric.normal[i][0] ?? metric.limits[i][0];
      final nMax = metric.normal[i][1] ?? metric.limits[i][1];
      return (nMin + nMax) / 2;
    });

    // Текущая фаза (эпизод) длится несколько замеров подряд, чтобы не было одиночных "иголок"
    MetricStatus episodeStatus = MetricStatus.ok;
    int episodeStepsLeft = 0;
    int anomalyFieldIdx = 0;
    bool goHigh = true;

    for (int step = 0; step < count; step++) {
      if (episodeStepsLeft <= 0) {
        final roll = _random.nextDouble();
        if (roll < criticalChance) {
          episodeStatus = MetricStatus.critical;
          episodeStepsLeft = 2 + _random.nextInt(3); // 2-4 точки подряд
        } else if (roll < criticalChance + warningChance) {
          episodeStatus = MetricStatus.warning;
          episodeStepsLeft = 3 + _random.nextInt(4); // 3-6 точек подряд
        } else {
          episodeStatus = MetricStatus.ok;
          episodeStepsLeft = 4 + _random.nextInt(8); // 4-11 точек нормы
        }
        anomalyFieldIdx = _random.nextInt(fieldCount);
        goHigh = _random.nextBool();
      }
      episodeStepsLeft--;

      final values = <double>[];
      for (int f = 0; f < fieldCount; f++) {
        final targetStatus = (f == anomalyFieldIdx)
            ? episodeStatus
            : MetricStatus.ok;

        final targetValue = _pickTargetValue(
          metric: metric,
          fieldIdx: f,
          targetStatus: targetStatus,
          preferHigh: goHigh,
        );

        // Плавная инерция (60% старого значения + 40% нового целевого + лёгкий шум)
        final smoothed = currentValues[f] * 0.55 + targetValue * 0.45;
        final finalValue = _clampAndRound(metric, f, smoothed);

        currentValues[f] = finalValue;
        values.add(finalValue);
      }

      final timestamp = startDate.add(Duration(hours: step * frequencyHours));
      result[timestamp] = values;
    }

    return result;
  }

  double _pickTargetValue({
    required MetricDef metric,
    required int fieldIdx,
    required MetricStatus targetStatus,
    required bool preferHigh,
  }) {
    final limitMin = metric.limits[fieldIdx][0];
    final limitMax = metric.limits[fieldIdx][1];
    final normMin = metric.normal[fieldIdx][0] ?? limitMin;
    final normMax = metric.normal[fieldIdx][1] ?? limitMax;
    final critMin = metric.critical[fieldIdx][0];
    final critMax = metric.critical[fieldIdx][1];
    final normSpan = max((normMax - normMin).abs(), 0.001);

    if (targetStatus == MetricStatus.ok) {
      // Колебания в центральной части нормы (с отступом 10% от краёв)
      final innerMin = normMin + normSpan * 0.1;
      final innerMax = normMax - normSpan * 0.1;
      return _lerp(innerMin, innerMax);
    }

    if (targetStatus == MetricStatus.warning) {
      final hasLowWarn = critMin != null && normMin > critMin;
      final hasHighWarn = critMax != null && critMax > normMax;

      if (hasHighWarn && (!hasLowWarn || preferHigh)) {
        return _lerp(normMax + (critMax - normMax) * 0.15, critMax);
      }
      if (hasLowWarn) {
        return _lerp(critMin, normMin - (normMin - critMin) * 0.15);
      }
      // Если отдельной warning-зоны нет (как у Troponin 0..0.04 -> crit > 0.04),
      // держим значение у самой верхней границы нормы без улёта в critical
      return _lerp(normMin + normSpan * 0.75, normMax);
    }

    // MetricStatus.critical — ограничиваем потолок выброса (макс +60% от ширины нормы),
    // чтобы не улетать в 10.0 при норме 0.04 и не сплющивать график
    final hasLowCrit = critMin != null && critMin > limitMin;
    final hasHighCrit = critMax != null && limitMax > critMax;

    if (hasHighCrit && (!hasLowCrit || preferHigh)) {
      final softCeiling = min(limitMax, critMax + normSpan * 0.6);
      return _lerp(critMax + normSpan * 0.05, softCeiling);
    }
    if (hasLowCrit) {
      final softFloor = max(limitMin, critMin - normSpan * 0.6);
      return _lerp(softFloor, critMin - normSpan * 0.05);
    }

    return _lerp(normMin, normMax);
  }

  double _clampAndRound(MetricDef metric, int fieldIdx, double value) {
    final minVal = metric.limits[fieldIdx][0];
    final maxVal = metric.limits[fieldIdx][1];
    final clamped = value.clamp(minVal, maxVal);
    final factor = pow(10, metric.decimals);
    return (clamped * factor).round() / factor;
  }

  double _lerp(double min, double max) {
    if (max <= min) return min;
    return min + _random.nextDouble() * (max - min);
  }
}
