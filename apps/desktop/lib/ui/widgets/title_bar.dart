import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerPanDown: (event) => windowManager.startDragging(),
      child: Container(
        height: AppSizes.titleBarHeight,
        decoration: BoxDecoration(
          color: AppColors.titleBarBg,
          border: const Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: AppSizes.borderWidthThin,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            // App logo / icon area
            Row(
              children: [
                const SizedBox(width: 6),
                Text(
                  AppStrings.appLogo,
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Window controls
            Row(
              children: [
                _WindowButton(
                  icon: Icons.circle_outlined,
                  iconSize: 6,
                  hoverColor: AppColors.textMuted,
                  tooltip: 'Minimize',
                  onTap: () => windowManager.minimize(),
                ),
                const SizedBox(width: 8),
                _WindowButton(
                  icon: Icons.square_outlined,
                  iconSize: 8,
                  hoverColor: AppColors.textMuted,
                  tooltip: 'Maximize',
                  onTap: () => _toggleMaximize(),
                ),
                const SizedBox(width: 8),
                _WindowButton(
                  icon: Icons.close,
                  iconSize: 10,
                  hoverColor: AppColors.red,
                  isRedClose: true,
                  tooltip: 'Close',
                  onTap: () => windowManager.close(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color? hoverColor;
  final bool isRedClose;
  final String tooltip;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconSize,
    this.hoverColor,
    this.isRedClose = false,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isRedClose
                    ? AppColors.red
                    : AppColors.surfaceAlt)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered
                ? (widget.isRedClose
                    ? AppColors.textPrimary
                    : widget.hoverColor ?? AppColors.textSecondary)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
