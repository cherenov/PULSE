import 'package:flutter/material.dart';
import 'package:pulse/theme/app_colors.dart';

/// Horizontal PULSE brand lockup: infinity mark │ P U L S E.
///
/// [height] is the height of the mark; the divider and wordmark scale from it.
class PulseLogo extends StatelessWidget {
  const PulseLogo({super.key, this.height = 26});

  final double height;

  static const markAsset = 'assets/brand/pulse_mark.png';
  static const wordmarkAsset = 'assets/brand/pulse_wordmark.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PULSE',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            markAsset,
            height: height,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: height * 0.6),
          Container(width: 1, height: height * 1.25, color: AppColors.border),
          SizedBox(width: height * 0.6),
          Image.asset(
            wordmarkAsset,
            height: height * 0.42,
            filterQuality: FilterQuality.medium,
          ),
        ],
      ),
    );
  }
}
