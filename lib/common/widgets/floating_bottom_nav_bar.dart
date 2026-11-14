import 'package:flutter/material.dart';
import 'package:pulse/common/models/nav_item.dart';
import 'package:pulse/theme/app_colors.dart';
import 'package:pulse/theme/sizes.dart';

class FloatingBottomNavBar extends StatelessWidget {
  const FloatingBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onDestinationLongPress,
    this.backgroundColor,
    this.selectedIconColor = AppColors.accent,
    this.unselectedIconColor = Colors.grey,
    this.width = 280,
    this.height = 64,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<int>? onDestinationLongPress;
  final Color? backgroundColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          width: width,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF262727),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: selectedIndex == i,
                    selectedIconColor: selectedIconColor,
                    unselectedIconColor: unselectedIconColor,
                    onTap: () => onDestinationSelected(i),
                    onLongPress: onDestinationLongPress == null
                        ? null
                        : () => onDestinationLongPress!(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.onTap,
    this.onLongPress,
  });

  final NavItem item;
  final bool selected;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Center(
          child: Icon(
            selected ? (item.selectedIcon ?? item.icon) : item.icon,
            color: selected ? selectedIconColor : unselectedIconColor,
            size: AppSizes.xxl,
          ),
        ),
      ),
    );
  }
}
