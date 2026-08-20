import 'package:flutter/material.dart';

import '../../core/theme_tokens.dart';

/// Themed dropdown used for the Format and Quality selectors. Sizes to its
/// content when no [width] is given (the menu expands to the widest item),
/// or fills a fixed [width] otherwise. [selectedBuilder] renders the compact
/// collapsed label so the control stays narrow even with two-line menu items.
class PrimaryDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Widget? leading;
  final double? width;
  final double height;
  final Widget? selectedBuilder;

  const PrimaryDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leading,
    this.width,
    this.height = 36,
    this.selectedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    final dropdown = DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      underline: const SizedBox.shrink(),
      isExpanded: width != null,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      dropdownColor: tokens.surface,
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 16,
        color: tokens.textSecondary,
      ),
      style: TextStyle(
        color: tokens.textPrimary,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      selectedItemBuilder: selectedBuilder != null
          ? (_) => List.filled(items.length, selectedBuilder!)
          : null,
    );

    final child = width != null
        ? Row(children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(child: dropdown),
          ])
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              dropdown,
            ],
          );

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: child,
    );
  }
}
