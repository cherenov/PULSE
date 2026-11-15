import 'package:flutter/material.dart';

import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/theme/app_colors.dart';
import 'package:pulse/theme/sizes.dart';

class AboutPulseScreen extends StatelessWidget {
  const AboutPulseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'About PULSE',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.sm,
            AppSizes.lg,
            AppSizes.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroCard(),
                  const SizedBox(height: AppSizes.lg),
                  const _StatsStrip(),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'Your health, in orbit',
                    subtitle:
                        'One clear view of the signals that matter most in '
                        'microgravity.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _BodyText(
                    'PULSE brings your vital signs and lab results together '
                    'into a calm, readable health console. It follows how your '
                    'numbers change over time, highlights values that drift '
                    'outside their reference range, and gives you a spoken '
                    'heads-up when something deserves attention.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _BodyText(
                    'Everything runs on your device. No connection is needed, '
                    'so PULSE keeps working during communication gaps, '
                    'blackouts or the quiet stretches between mission tasks.',
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'What PULSE watches',
                    subtitle:
                        'Four body systems shaped by the spaceflight '
                        'environment.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _FeatureGrid(),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'How it helps',
                    subtitle: 'A simple loop: collect, review, respond.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _Card(
                    child: Column(
                      children: [
                        _AlphaNotice(),
                        SizedBox(height: AppSizes.sm),
                        _StepRow(
                          number: '1',
                          icon: Icons.sensors_rounded,
                          title: 'Collect',
                          body:
                              'PULSE is designed to receive vital signs from '
                              'connected sensors as they stream in. Readings '
                              'can also be entered manually when a sensor is '
                              'unavailable.',
                        ),
                        _StepDivider(),
                        _StepRow(
                          number: '2',
                          icon: Icons.dashboard_outlined,
                          title: 'Review',
                          body:
                              'The dashboard shows the latest status across '
                              'blood, urine, non-invasive trackers and eye '
                              'health.',
                        ),
                        _StepDivider(),
                        _StepRow(
                          number: '3',
                          icon: Icons.insights_rounded,
                          title: 'Respond',
                          body:
                              'Open any metric to see its trend, reference '
                              'thresholds and recent readings. Use the spoken '
                              'feedback when your hands are busy.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'Reading the colors',
                    subtitle:
                        'Colors help you decide how urgently to act — they '
                        'are not a diagnosis.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _Card(
                    child: Column(
                      children: [
                        _StatusRow(
                          color: AppColors.ok,
                          title: 'Within range',
                          body:
                              'The reading sits inside its reference range. '
                              'Continue routine monitoring.',
                        ),
                        _StatusDivider(),
                        _StatusRow(
                          color: AppColors.caution,
                          title: 'Caution',
                          body:
                              'The reading is outside its usual range. '
                              'Recheck it and review the recent trend.',
                        ),
                        _StatusDivider(),
                        _StatusRow(
                          color: AppColors.critical,
                          title: 'Critical',
                          body:
                              'The reading is outside the safety range. Act '
                              'promptly and inform your flight surgeon or crew '
                              'medical officer.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'Built for the environment',
                    subtitle:
                        'Designed around the constraints of living and '
                        'working in microgravity.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _Card(
                    child: Column(
                      children: [
                        _BenefitRow(
                          icon: Icons.wifi_off_rounded,
                          title: 'No connection required',
                          body:
                              'PULSE runs entirely on your device, even when '
                              'the link to the ground is unavailable.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.record_voice_over_outlined,
                          title: 'Spoken feedback',
                          body:
                              'Alerts and summaries are read aloud, so you can '
                              'stay hands-free when your attention is needed '
                              'elsewhere.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.touch_app_outlined,
                          title: 'Made for microgravity',
                          body:
                              'A portrait-first layout, large touch targets and '
                              'short task flows keep interaction simple while '
                              'floating.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Private by design',
                          body:
                              'Measurements stay on this device. Nothing is '
                              'uploaded to a cloud service.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'Testing & demo',
                    subtitle:
                        'A hidden toolkit for validating PULSE on the ground.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _Card(
                    child: Column(
                      children: [
                        _BenefitRow(
                          icon: Icons.developer_mode_outlined,
                          title: 'Hidden debug mode',
                          body:
                              'Tap Settings five times quickly to reveal the '
                              'Debug tab, or long-press Settings to show or hide '
                              'it. Debug mode is intended for testing and '
                              'demonstration only.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.casino_outlined,
                          title: 'Random telemetry',
                          body:
                              'Generate synthetic readings for every metric '
                              'over a 7–60 day period, sampled every six hours. '
                              'Adjust the caution and critical rates, and choose '
                              'whether to clear existing measurements first.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Clear measurements',
                          body:
                              'Remove all measurement records for the active '
                              'profile after a confirmation step. Profiles and '
                              'settings are not deleted.',
                        ),
                        _BenefitDivider(),
                        _BenefitRow(
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.caution,
                          title: 'Test data only',
                          body:
                              'Generated readings are simulated. Never use them '
                              'for health decisions or mission planning.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const _SectionTitle(
                    title: 'Important to know',
                    subtitle:
                        'PULSE supports awareness; it does not replace care.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  const _Card(
                    accent: AppColors.caution,
                    child: _BodyText(
                      'PULSE is a monitoring and awareness tool, not a medical '
                      'diagnosis. Reference ranges are general, and your flight '
                      'surgeon’s guidance always comes first. If a reading '
                      'seems wrong, repeat the measurement and confirm it with '
                      'your crew medical officer.',
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxxl),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceHigh, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.accent,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PULSE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      'Personal Unit for Health and Life Evaluation',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            'A calm, offline health companion for the journey beyond Earth.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          const Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              _Pill(icon: Icons.wifi_off_rounded, label: 'Works offline'),
              _Pill(
                icon: Icons.record_voice_over_outlined,
                label: 'Voice feedback',
              ),
              _Pill(icon: Icons.shield_outlined, label: 'On-device data'),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'CREATED FOR THE NASA SPACE APPS CHALLENGE',
            style: TextStyle(
              color: AppColors.accent.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Stat(value: '${metrics.length}', label: 'health markers'),
          const _StatDivider(),
          _Stat(value: '${MetricGroup.values.length}', label: 'body systems'),
          const _StatDivider(),
          const _Stat(value: '0', label: 'cloud links'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _features = [
    (
      icon: Icons.favorite_border_rounded,
      color: AppColors.heartRate,
      title: 'Cardiovascular',
      body: 'Heart rhythm, blood pressure and circulation signals.',
    ),
    (
      icon: Icons.accessibility_new_rounded,
      color: AppColors.caution,
      title: 'Bone & muscle',
      body: 'Bone turnover, muscle stress and recovery signals.',
    ),
    (
      icon: Icons.visibility_outlined,
      color: AppColors.info,
      title: 'Neuro-ocular',
      body: 'Optic nerve and eye pressure changes linked to SANS.',
    ),
    (
      icon: Icons.science_outlined,
      color: AppColors.respiration,
      title: 'Metabolism & inflammation',
      body: 'Electrolytes, liver, kidney and inflammatory markers.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final width = twoColumns
            ? (constraints.maxWidth - AppSizes.md) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.md,
          children: [
            for (final feature in _features)
              SizedBox(
                width: width,
                child: _FeatureTile(
                  icon: feature.icon,
                  color: feature.color,
                  title: feature.title,
                  body: feature.body,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? accent;

  const _Card({required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent?.withValues(alpha: 0.35) ?? AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _AlphaNotice extends StatelessWidget {
  const _AlphaNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.caution.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.caution.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.science_outlined,
              color: AppColors.caution,
              size: 17,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'ALPHA  ',
                    style: TextStyle(
                      color: AppColors.caution,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Sensor collection is under testing. Manual entry '
                        'remains available as a fallback.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String body;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.textSecondary, size: 17),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color color;
  final String title;
  final String body;

  const _StatusRow({
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 7),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? color;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.body,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Icon(icon, color: color ?? AppColors.accent, size: 21),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSizes.lg),
        const Text(
          'Created for the NASA Space Apps Challenge.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        const Text(
          'Independent project. Not affiliated with or endorsed by NASA.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
            ),
            const SizedBox(width: AppSizes.sm),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const Text(
              'Apache 2.0',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 46, color: AppColors.border);
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 22, color: AppColors.border);
  }
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 46, color: AppColors.border);
  }
}
