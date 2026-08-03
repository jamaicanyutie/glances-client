import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Tappable navigation card that pushes a drill-down route on tap.
///
/// Used on overview screens (Network, Disks, …) to link to standalone
/// drill-down screens. The title/caption column is flexible and ellipsizes so
/// the card reflows cleanly in narrow columns (portrait) and wide grid cells
/// (landscape/tablet) — it must be placed inside a [ResponsiveCardGrid] to
/// pick up the column count on rotation.
class NavCard extends StatelessWidget {
  const NavCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.caption,
  });

  /// Card title, shown next to [icon].
  final String title;

  /// Leading icon, tinted like the other card icons.
  final IconData icon;

  /// Route push (or any other action) performed when the card is tapped.
  final VoidCallback onTap;

  /// One-line hint shown under the title, e.g. `Private and public network
  /// addressing →`.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
