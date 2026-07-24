import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

/// Bottom Sheet for picking how to add a transaction (docs/04_User_Flows.md
/// §6, Экран 6.0). Only the three variants named in this task's own
/// description are offered — "Вручную"/"Фото чека"/"Из шаблона". "Голосом"
/// is documented in §6 too, but has neither a file in this task's list nor
/// a backend Voice module built yet, so it's left out here.
///
/// The sheet only captures the choice and closes — it doesn't navigate
/// itself, since the manual-entry (T4.7) and photo-scan (T4.8) screens
/// don't exist yet, and no task anywhere builds a "from template" screen
/// at all (another documented-but-unbuilt gap, like /auth/otp/resend).
/// Callers wire real navigation once those destinations exist.
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({
    super.key,
    required this.onManualTap,
    required this.onPhotoTap,
    required this.onTemplateTap,
  });

  final VoidCallback onManualTap;
  final VoidCallback onPhotoTap;
  final VoidCallback onTemplateTap;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onManualTap,
    required VoidCallback onPhotoTap,
    required VoidCallback onTemplateTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder:
          (_) => AddTransactionSheet(
            onManualTap: onManualTap,
            onPhotoTap: onPhotoTap,
            onTemplateTap: onTemplateTap,
          ),
    );
  }

  void _select(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addTransactionSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.addTransactionManual),
              onTap: () => _select(context, onManualTap),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.addTransactionPhoto),
              onTap: () => _select(context, onPhotoTap),
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(l10n.addTransactionTemplate),
              onTap: () => _select(context, onTemplateTap),
            ),
          ],
        ),
      ),
    );
  }
}
