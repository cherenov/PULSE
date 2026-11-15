import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/core/risk_detector/risk_detector.dart';

class StatusAnnouncer {
  const StatusAnnouncer._();

  static String welcome({
    required List<Measurement> latest,
    required List<HealthRisk> risks,
  }) {
    if (latest.isEmpty) {
      return 'Welcome to PULSE. No measurements recorded.';
    }

    final latestById = {for (final m in latest) m.metricId: m};
    var critical = 0;
    var warning = 0;

    for (final metric in metrics) {
      final measurement = latestById[metric.id];
      if (measurement == null) continue;
      switch (metric.status(measurement.values)) {
        case MetricStatus.critical:
          critical++;
        case MetricStatus.warning:
          warning++;
        case MetricStatus.ok:
          break;
      }
    }

    final parts = <String>['Welcome to PULSE, dear Astronaut.'];

    // if (critical == 0 && warning == 0) {
    //   parts.add('All indicators are within normal range.');
    // } else {
    if (critical > 0) {
      parts.add(
        'Warning. $critical critical ${critical == 1 ? 'indicator' : 'indicators'}.',
      );
    }
    if (warning > 0) {
      parts.add(
        'Caution. $warning ${warning == 1 ? 'indicator needs' : 'indicators need'} review.',
      );
    }
    // }

    final confirmed = risks
        .where((r) => r.severity == RiskSeverity.confirmed)
        .map((r) => r.title)
        .take(3)
        .toList();
    final suspected = risks
        .where((r) => r.severity == RiskSeverity.suspicion)
        .map((r) => r.title)
        .take(3)
        .toList();

    if (confirmed.isNotEmpty) {
      parts.add('Confirmed risks: ${confirmed.join(', ')}.');
    }
    if (suspected.isNotEmpty) {
      parts.add('Possible risks: ${suspected.join(', ')}.');
    }

    return parts.join(' ');
  }

  static String? forAssessment({
    required String metricTitle,
    required String label,
    required String message,
    required bool showWarning,
  }) {
    if (!showWarning) return null;
    return '$metricTitle. $label. $message.';
  }

  static String forSavedRecord({
    required String metricTitle,
    required MetricStatus status,
  }) {
    return switch (status) {
      MetricStatus.ok => 'Saved. $metricTitle is normal.',
      MetricStatus.warning =>
        'Saved. Caution. $metricTitle is outside the normal range.',
      MetricStatus.critical => 'Saved. Warning. $metricTitle is critical.',
    };
  }
}
