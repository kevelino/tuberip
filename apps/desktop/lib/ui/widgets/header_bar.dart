import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.onSettings,
    required this.onHelp,
  });

  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingLg,
        vertical: tokens.spacingMd,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AppConstants.logoAsset,
            width: 32,
            height: 32,
          ),
          SizedBox(width: tokens.spacingSm),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: onHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
    );
  }
}
