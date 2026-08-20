import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants.dart';
import '../../core/theme_tokens.dart';

/// Frameless window title bar: app wordmark on the left, an icon cluster
/// (queue / settings / help) and flat window controls on the right. The whole
/// bar is draggable via window_manager. Window controls follow the Linux/GTK
/// convention: flat icon buttons on the right, neutral hover, no colored
/// circles — kept DE-agnostic (GNOME/KDE/etc.).
class HeaderBar extends StatelessWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onHelp;

  const HeaderBar({super.key, this.onSettings, this.onHelp});

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () => _toggleMaximize(),
      child: Container(
        height: AppSizes.titleBarHeight,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(
            bottom: BorderSide(color: tokens.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.download_outlined, size: 18, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            _HeaderIcon(Icons.list_alt_outlined, tokens.textSecondary, null),
            _HeaderIcon(
                Icons.settings_outlined, tokens.textSecondary, onSettings),
            _HeaderIcon(Icons.help_outline, tokens.textSecondary, onHelp),
            const SizedBox(width: 10),
            _WindowButton(
              icon: Icons.remove,
              tooltip: 'Minimize',
              onTap: () => windowManager.minimize(),
            ),
            const SizedBox(width: 4),
            _WindowButton(
              icon: Icons.crop_square,
              tooltip: 'Maximize',
              onTap: () => _toggleMaximize(),
            ),
            const SizedBox(width: 4),
            _WindowButton(
              icon: Icons.close,
              tooltip: 'Close',
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HeaderIcon(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(icon, size: 16, color: color),
    );
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
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
    final tokens = TubeRipTheme.of(context);
    // Neutral, DE-agnostic hover (no red/colored circles).
    final hoverBg = _hovered ? tokens.surfaceAlt : Colors.transparent;
    final iconColor =
        _hovered ? tokens.textPrimary : tokens.textSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            color: hoverBg,
          ),
          child: Icon(widget.icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
