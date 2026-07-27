import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/installment_repository_impl.dart';
import '../widgets/installment_card.dart';
import '../widgets/add_installment_sheet.dart';

/// Installments summary (T7.4, docs/04_User_Flows.md §8): total debt
/// load + a card per active installment. Not yet wired into app
/// navigation — its intended entry point, Dashboard (M8), doesn't exist
/// yet.
class InstallmentsScreen extends ConsumerWidget {
  const InstallmentsScreen({super.key});

  Future<void> _openAddInstallmentSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final created = await AddInstallmentSheet.show(context);
    if (created != null) {
      ref.invalidate(installmentsOverviewProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviewAsync = ref.watch(installmentsOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.installmentsScreenTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddInstallmentSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: overviewAsync.when(
        data: (overview) {
          if (overview.installments.isEmpty) {
            return Center(child: Text(l10n.installmentsEmptyMessage));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.installmentsTotalOutstandingLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      overview.totalOutstanding,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              for (final installment in overview.installments)
                InstallmentCard(installment: installment),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorNetwork)),
      ),
    );
  }
}
