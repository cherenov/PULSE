import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/features/debug/telemetry_generator.dart';
import 'package:pulse/features/debug/widgets/debug_metrics_list.dart';
import 'package:pulse/features/debug/widgets/debug_risks_list.dart';
import 'package:pulse/theme/app_colors.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isGenerating = false;
  double _warningChance = 0.15;
  double _criticalChance = 0.05;
  int _days = 30;
  bool _clearExisting = true;

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear database'),
        content: const Text(
          'Delete all measurements for the active profile? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final profileId = ref.read(activeProfileIdProvider);
    await ref.read(dbProvider).deleteAllData(profileId);
  }

  Future<void> _openRandomGeneratorDialog() async {
    double tempWarning = _warningChance;
    double tempCritical = _criticalChance;
    int tempDays = _days;
    bool tempClear = _clearExisting;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate random telemetry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Period: $tempDays days (every 6h)'),
              Slider(
                value: tempDays.toDouble(),
                min: 7,
                max: 60,
                divisions: 53,
                label: '$tempDays d',
                onChanged: (v) => setDialogState(() => tempDays = v.round()),
              ),
              const SizedBox(height: 8),
              Text('Review (Warning) chance: ${(tempWarning * 100).round()}%'),
              Slider(
                value: tempWarning,
                min: 0.0,
                max: 0.6,
                divisions: 12,
                label: '${(tempWarning * 100).round()}%',
                onChanged: (v) => setDialogState(() => tempWarning = v),
              ),
              const SizedBox(height: 8),
              Text('Critical chance: ${(tempCritical * 100).round()}%'),
              Slider(
                value: tempCritical,
                min: 0.0,
                max: 0.4,
                divisions: 8,
                activeColor: AppColors.critical,
                label: '${(tempCritical * 100).round()}%',
                onChanged: (v) => setDialogState(() => tempCritical = v),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Clear existing data first'),
                value: tempClear,
                onChanged: (v) =>
                    setDialogState(() => tempClear = v ?? tempClear),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _warningChance = tempWarning;
      _criticalChance = tempCritical;
      _days = tempDays;
      _clearExisting = tempClear;
      _isGenerating = true;
    });

    try {
      final db = ref.read(dbProvider);
      final profileId = ref.read(activeProfileIdProvider);

      final count = await TelemetryGenerator().generateForAllMetrics(
        db: db,
        profileId: profileId,
        days: _days,
        frequencyHours: 6,
        warningChance: _warningChance,
        criticalChance: _criticalChance,
        clearExisting: _clearExisting,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $count measurements across all metrics'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isGenerating
                        ? null
                        : _openRandomGeneratorDialog,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.casino_outlined),
                    label: Text(_isGenerating ? 'Generating...' : 'Random'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _clearDatabase,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear database'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.critical,
                      side: const BorderSide(color: AppColors.critical),
                    ),
                  ),
                ],
              ),
            ),
            const DebugRisksList(),
            const Expanded(child: DebugMetricsList()),
          ],
        ),
      ),
    );
  }
}
