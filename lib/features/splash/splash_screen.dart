import 'package:flutter/material.dart';
import 'package:pulse/home_screen.dart';
import 'package:pulse/theme/app_colors.dart';

/// Branded launch screen shown right after the native splash.
///
/// The centered lockup matches the native splash icon (154dp wide) so the
/// hand-off is seamless; the planet horizon then rises from the bottom.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const lockupAsset = 'assets/brand/pulse_lockup.png';
  static const horizonAsset = 'assets/brand/splash_horizon.jpg';

  /// Width of the lockup inside the native splash icon
  /// (965px of a 1800px canvas rendered at 288dp).
  static const lockupWidth = 154.0;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2000);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );

  late final Animation<double> _horizon = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.6, curve: Curves.easeOutCubic),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(
      const AssetImage(SplashScreen.horizonAsset),
      context,
    ).whenComplete(() {
      if (!mounted) return;
      _controller.forward().whenComplete(_openHome);
    });
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _horizon,
              builder: (context, child) => Opacity(
                opacity: _horizon.value,
                child: Transform.translate(
                  offset: Offset(0, 60 * (1 - _horizon.value)),
                  child: child,
                ),
              ),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.35],
                ).createShader(rect),
                child: Image.asset(
                  SplashScreen.horizonAsset,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: Image.asset(
              SplashScreen.lockupAsset,
              width: SplashScreen.lockupWidth,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'PULSE',
            ),
          ),
        ],
      ),
    );
  }
}
