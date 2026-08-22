import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 160;
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact)
                  Opacity(
                    opacity: 0.35,
                    child: SvgPicture.asset(
                      AppConstants.logoAsset,
                      width: 72,
                      height: 72,
                    ),
                  ),
                if (!compact) SizedBox(height: tokens.spacingLg),
                Text(
                  'No downloads yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: tokens.spacingSm),
                Text(
                  'Enter a YouTube URL and click download to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray400,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
