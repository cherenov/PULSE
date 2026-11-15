import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulse/common/widgets/pulse_logo.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/features/indicators/indicator_detail_screen.dart';
import 'package:pulse/features/indicators/widgets/indicator_list_tile.dart';
import 'package:pulse/home_screen.dart';
import 'package:pulse/theme/app_colors.dart';

class IndicatorsGroupScreen extends ConsumerWidget {
  const IndicatorsGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.watch(selectedMetricGroupProvider);
    final measurementsAsync = ref.watch(latestAllProvider);
    final canPop = Navigator.canPop(context);

    final currentMetrics = metrics
        .where((metric) => metric.group == selectedGroup)
        .toList();

    final groupTitle = switch (selectedGroup) {
      MetricGroup.blood => 'Blood indicators',
      MetricGroup.urine => 'Urine indicators',
      MetricGroup.trackers => 'Non-invasive indicators',
      MetricGroup.eyes => 'Eye health indicators',
    };

    void selectGroup(MetricGroup group) {
      if (selectedGroup == group) return;
      ref.read(selectedMetricGroupProvider.notifier).setGroup(group);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        titleSpacing: canPop ? 0 : 16,
        title: const PulseLogo(height: 24),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryTab(
                        label: 'Blood',
                        selected: selectedGroup == MetricGroup.blood,
                        onTap: () => selectGroup(MetricGroup.blood),
                      ),
                      const SizedBox(width: 9),
                      _CategoryTab(
                        label: 'Urine',
                        selected: selectedGroup == MetricGroup.urine,
                        onTap: () => selectGroup(MetricGroup.urine),
                      ),
                      const SizedBox(width: 9),
                      _CategoryTab(
                        label: 'Non-invasive',
                        selected: selectedGroup == MetricGroup.trackers,
                        onTap: () => selectGroup(MetricGroup.trackers),
                      ),
                      const SizedBox(width: 9),
                      _CategoryTab(
                        label: 'Eye health',
                        selected: selectedGroup == MetricGroup.eyes,
                        onTap: () => selectGroup(MetricGroup.eyes),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        groupTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${currentMetrics.length} total',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          Expanded(
            child: measurementsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load measurements.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              data: (latestList) {
                final latestRecords = {
                  for (final m in latestList) m.metricId: m,
                };

                return ListView.separated(
                  key: ValueKey(selectedGroup),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  itemCount: currentMetrics.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final metric = currentMetrics[index];

                    return IndicatorListTile(
                      metric: metric,
                      measurement: latestRecords[metric.id],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                IndicatorDetailScreen(metricId: metric.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onAccent : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
