import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Kartu statistik modern: ikon dalam tile + label + nilai besar.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(dark: dark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_forward_rounded,
                    size: 16,
                    color: dark ? AppTheme.darkMuted : AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: dark ? AppTheme.darkText : AppTheme.textDark)),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  color: dark ? AppTheme.darkMuted : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.3)),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        child: card);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.subtitle, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: dark ? AppTheme.darkText : AppTheme.textDark)),
              if (subtitle != null)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppTheme.primary),
              ],
            ),
          ),
      ],
    );
  }
}
