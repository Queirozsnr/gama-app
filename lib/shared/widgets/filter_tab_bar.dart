import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FilterTabBar extends StatelessWidget {
  const FilterTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
