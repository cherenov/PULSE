import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/core/risk_detector/risk_detector.dart';

class StatusSpeech {
  static String welcome({
    required List<Measurement> latest,
    required List<HealthRisk> risks,
  }) {
    final parts = <String>['Welcome to PULSE.'];

    if (latest.isEmpty) {
      parts.add('No measurements recorded yet.');
      return parts.join(' ');
    }

    final latestById = {for (final m in latest) m.metricId: m};
    var criticalCount = 0;
    var warningCount = 0;
    final criticalTitles = <String>[];

    for (final metric in metrics) {
      final measurement = latestById[metric.id];
      if (measurement == null) continue;

      switch (metric.status(measurement.values)) {
        case MetricStatus.critical:
          criticalCount++;
          if (criticalTitles.length < 3) {
            criticalTitles.add(metric.title);
          }
        case MetricStatus.warning:
          warningCount++;
        case MetricStatus.ok:
          break;
      }
    }

    final confirmed = risks
        .where((r) => r.severity == RiskSeverity.confirmed)
        .toList();
    final suspicions = risks
        .where((r) => r.severity == RiskSeverity.suspicion)
        .toList();

    if (criticalCount == 0 && warningCount == 0 && risks.isEmpty) {
      parts.add('All recorded indicators are within normal range.');
      return parts.join(' ');
    }

    if (criticalCount > 0) {
      final noun = criticalCount == 1 ? 'indicator is' : 'indicators are';
      final titles = criticalTitles.isEmpty
          ? ''
          : ': ${criticalTitles.join(', ')}';
      parts.add('Warning: $criticalCount $noun critical$titles.');
    } else if (warningCount > 0) {
      final noun = warningCount == 1 ? 'indicator needs' : 'indicators need';
      parts.add('Caution: $warningCount $noun review.');
    }

    if (confirmed.isNotEmpty) {
      parts.add(
        'Confirmed risks: ${confirmed.map((r) => r.title).join(', ')}.',
      );
    } else if (suspicions.isNotEmpty) {
      parts.add(
        'Possible risks: ${suspicions.map((r) => r.title).join(', ')}.',
      );
    }

    return parts.join(' ');
  }

  static String savedRecord(MetricDef metric, List<double> values) {
    return switch (metric.status(values)) {
      MetricStatus.ok => 'Saved ${metric.title}. Value is normal.',
      MetricStatus.warning =>
        'Saved ${metric.title}. Caution: value is outside the normal range.',
      MetricStatus.critical =>
        'Saved ${metric.title}. Warning: value is critical.',
    };
  }
}
