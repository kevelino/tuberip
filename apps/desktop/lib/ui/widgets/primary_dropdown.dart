import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PrimaryDropdown<T> extends StatelessWidget {
  const PrimaryDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leading,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.gray400,
              ),
        ),
        SizedBox(height: tokens.spacingXs),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray900 : Colors.white,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.gray700 : AppColors.gray300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                items: items,
                onChanged: onChanged,
                icon: const Icon(Icons.expand_more),
                dropdownColor: isDark ? AppColors.gray900 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
