import 'package:flutter/material.dart';
import 'package:pulse/common/widgets/pulse_logo.dart';
import 'package:pulse/features/settings/about_pulse_screen.dart';
import 'package:pulse/features/settings/orbital_run_screen.dart';
import 'package:pulse/theme/app_colors.dart';
import 'package:pulse/theme/sizes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PulseLogo(height: 30),

                  const SizedBox(height: 42),

                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  const Text(
                    'Profile, baselines, off-duty and app preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  const _ProfileCard(),

                  const SizedBox(height: AppSizes.md),

                  const _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Baseline values',
                        subtitle: 'Personal reference ranges for indicators',
                      ),
                      _SettingsDivider(),
                      _SettingsRow(
                        icon: Icons.storage_outlined,
                        title: 'Data & sync',
                        subtitle: 'Offline mode, export and data sharing',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  const Text(
                    'Off-duty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSizes.sm),

                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.sports_esports_outlined,
                        title: 'Orbital Run',
                        subtitle: 'A short deep-space arcade break',
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Play',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: AppSizes.xs),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrbitalRunScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  const Text(
                    'App settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSizes.sm),

                  _SettingsCard(
                    children: [
                      const _SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        trailing: NotificationSwitch(),
                      ),
                      const _SettingsDivider(),
                      const _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Appearance',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dark',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            SizedBox(width: AppSizes.sm),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About PULSE',
                        subtitle: 'Mission, health focus and credits',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutPulseScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 52,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: AppSizes.md),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Astronaut 01',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  'Mission: ISS-73',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  'ID: A01',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 26),
                SizedBox(height: AppSizes.xs),
                Text(
                  'Switch\nprofile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Icon(
              icon,
              size: AppSizes.xxl,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          trailing ??
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: AppSizes.lg,
      color: AppColors.border,
    );
  }
}

class NotificationSwitch extends StatefulWidget {
  const NotificationSwitch({super.key});

  @override
  State<NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<NotificationSwitch> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: notificationsEnabled,

      activeTrackColor: AppColors.accent,
      activeThumbColor: AppColors.onAccent,

      inactiveTrackColor: AppColors.border,
      inactiveThumbColor: AppColors.textSecondary,

      onChanged: (bool value) {
        setState(() {
          notificationsEnabled = value;
        });
      },
    );
  }
}
