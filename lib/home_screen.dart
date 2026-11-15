import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/common/models/nav_item.dart';
import 'package:pulse/common/widgets/floating_bottom_nav_bar.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/core/risk_detector/risk_providers.dart';
import 'package:pulse/core/tts/status_announcer.dart';
import 'package:pulse/core/tts/tts_provider.dart';
import 'package:pulse/features/add_metrics/add_record_screen.dart';
import 'package:pulse/features/dashboard/dashboard_screen.dart';
import 'package:pulse/features/debug/debug_screen.dart';
import 'package:pulse/features/indicators/indicator_group_screen.dart';
import 'package:pulse/features/settings/settings_screen.dart';

class SelectedIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final selectedIndexProvider = NotifierProvider<SelectedIndexNotifier, int>(
  SelectedIndexNotifier.new,
);

class SelectedMetricGroupNotifier extends Notifier<MetricGroup> {
  @override
  MetricGroup build() => MetricGroup.blood;

  void setGroup(MetricGroup group) => state = group;
}

final selectedMetricGroupProvider =
    NotifierProvider<SelectedMetricGroupNotifier, MetricGroup>(
      SelectedMetricGroupNotifier.new,
    );

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _settingsIndex = 3;
  static const _unlockTapCount = 5;

  late final PageController _pageController;
  bool _isAnimatingByTap = false;
  bool _debugUnlocked = false;
  bool _didWelcome = false;
  int _settingsTaps = 0;
  Timer? _settingsTapReset;

  List<NavItem> get _mainItems => [
    const NavItem(
      screen: DashboardScreen(),
      icon: Icons.dashboard,
      label: 'Dashboard',
    ),
    const NavItem(
      screen: IndicatorsGroupScreen(),
      icon: Icons.bar_chart_rounded,
      label: 'Metrics',
    ),
    const NavItem(
      screen: AddRecordScreen(),
      icon: Icons.add_circle_outline,
      label: 'Add record',
    ),
    const NavItem(
      screen: SettingsScreen(),
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const _debugItem = NavItem(
    screen: DebugScreen(),
    icon: Icons.developer_mode_outlined,
    selectedIcon: Icons.developer_mode,
    label: 'Debug',
  );

  List<NavItem> get _navItems =>
      _debugUnlocked ? [..._mainItems, _debugItem] : _mainItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(selectedIndexProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _speakWelcomeIfNeeded(),
    );
  }

  void _speakWelcomeIfNeeded() {
    if (!mounted || _didWelcome) return;
    final latestAsync = ref.read(latestAllProvider);
    final latest = latestAsync.asData?.value;
    if (latest == null && !latestAsync.hasError) return;

    _didWelcome = true;
    final risks = ref.read(riskProvider);
    ref
        .read(ttsServiceProvider)
        .speak(
          StatusAnnouncer.welcome(latest: latest ?? const [], risks: risks),
        );
  }

  @override
  void dispose() {
    _settingsTapReset?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _unlockDebug() {
    if (_debugUnlocked) return;
    _settingsTaps = 0;
    _settingsTapReset?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _debugUnlocked = true);
    ref.read(ttsServiceProvider).speak('Debug mode enabled');
    final debugIndex = _mainItems.length;
    ref.read(selectedIndexProvider.notifier).setIndex(debugIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(debugIndex);
      }
    });
  }

  void _lockDebug() {
    if (!_debugUnlocked) return;
    final current = ref.read(selectedIndexProvider);
    if (current >= _mainItems.length) {
      ref.read(selectedIndexProvider.notifier).setIndex(_settingsIndex);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_settingsIndex);
      }
    }
    setState(() => _debugUnlocked = false);
    ref.read(ttsServiceProvider).speak('Debug mode hidden');
  }

  Future<void> _onDestinationSelected(int index) async {
    if (index == _settingsIndex && !_debugUnlocked) {
      _settingsTaps++;
      _settingsTapReset?.cancel();
      _settingsTapReset = Timer(const Duration(seconds: 2), () {
        _settingsTaps = 0;
      });
      if (_settingsTaps >= _unlockTapCount) {
        _unlockDebug();
        return;
      }
    } else {
      _settingsTaps = 0;
    }

    final currentIndex = ref.read(selectedIndexProvider);
    if (currentIndex == index) return;

    ref.read(selectedIndexProvider.notifier).setIndex(index);

    if (_pageController.hasClients) {
      _isAnimatingByTap = true;
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      _isAnimatingByTap = false;
    }
  }

  void _onDestinationLongPress(int index) {
    if (index != _settingsIndex) return;
    if (_debugUnlocked) {
      _lockDebug();
    } else {
      _unlockDebug();
    }
  }

  void _onPageChanged(int index) {
    if (_isAnimatingByTap) return;
    if (index >= _navItems.length) return;
    ref.read(selectedIndexProvider.notifier).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final mediaQuery = MediaQuery.of(context);
    final navItems = _navItems;
    final safeIndex = selectedIndex.clamp(0, navItems.length - 1);

    ref.listen(latestAllProvider, (previous, next) {
      _speakWelcomeIfNeeded();
    });

    ref.listen<int>(selectedIndexProvider, (prev, next) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != next &&
          !_isAnimatingByTap &&
          next < navItems.length) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
        );
      }
    });

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          MediaQuery(
            data: mediaQuery.copyWith(
              gestureSettings: DeviceGestureSettings(
                touchSlop:
                    (mediaQuery.gestureSettings.touchSlop ?? kTouchSlop) * 3,
              ),
            ),
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                for (final item in navItems)
                  _KeepAlivePage(
                    key: ValueKey<String>('nav:${item.label}'),
                    child: MediaQuery(data: mediaQuery, child: item.screen),
                  ),
              ],
            ),
          ),
          FloatingBottomNavBar(
            items: navItems,
            selectedIndex: safeIndex,
            width: navItems.length > 4 ? 320 : 280,
            onDestinationSelected: _onDestinationSelected,
            onDestinationLongPress: _onDestinationLongPress,
          ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required Key key, required this.child})
    : super(key: key);

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
