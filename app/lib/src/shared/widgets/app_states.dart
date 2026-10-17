import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Status async yang konsisten: loading / kosong / error.
class LoadingList extends StatelessWidget {
  final int rows;
  const LoadingList({super.key, this.rows = 4});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(
        rows,
        (i) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecoration(dark: dark),
          child: const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5))),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? AppTheme.darkCard2 : AppTheme.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 30,
              color: dark ? AppTheme.darkPrimary : AppTheme.primary),
        ),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(dark: dark, radius: AppTheme.rLg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_off_rounded,
              color: AppTheme.danger, size: 24),
        ),
        const SizedBox(height: 12),
        const Text('Gagal memuat data',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: dark ? AppTheme.darkMuted : AppTheme.textMuted)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Coba lagi'),
        ),
      ]),
    );
  }
}

Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
        const SizedBox(width: 8),
        Flexible(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16))),
      ]),
      content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.5)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rLg)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

void showAppMessage(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: isError ? AppTheme.danger : null,
  ));
}
