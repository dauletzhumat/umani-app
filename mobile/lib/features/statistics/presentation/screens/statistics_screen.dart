import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/report.dart';
import '../widgets/category_pie_chart.dart';

typedef _DateRange = ({String dateFrom, String dateTo});

/// Expense transactions for the report's own date range, fetched once
/// per period — filtering by the tapped category then happens
/// client-side (see _StatisticsScreenState._visibleTransactions),
/// since GET /transactions has no way to ask for "categoryId IS NULL"
/// specifically (only "filter by this id" or "don't filter").
final _statisticsTransactionsProvider =
    FutureProvider.family<List<Transaction>, _DateRange>((ref, range) async {
      final page = await ref
          .watch(transactionRepositoryProvider)
          .fetchAll(
            type: TransactionType.expense,
            dateFrom: range.dateFrom,
            dateTo: range.dateTo,
            limit: 100,
          );
      return page.items;
    });

/// Statistics screen (T9.2, docs/05_UX.md §6): period switcher + pie
/// chart by category + a real period-comparison insight line. Tapping
/// a slice (or its legend row) filters the transaction list below.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'month';
  bool _categorySelected = false;
  String? _selectedCategoryId;

  void _onSliceTap(ChartSlice slice) {
    if (slice.isOther) return;
    setState(() {
      if (_categorySelected && _selectedCategoryId == slice.categoryId) {
        _categorySelected = false;
        _selectedCategoryId = null;
      } else {
        _categorySelected = true;
        _selectedCategoryId = slice.categoryId;
      }
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _period = period;
      _categorySelected = false;
      _selectedCategoryId = null;
    });
  }

  List<Transaction> _visibleTransactions(List<Transaction> all) {
    if (!_categorySelected) return all;
    return all
        .where((transaction) => transaction.categoryId == _selectedCategoryId)
        .toList();
  }

  // previousPeriodTotalExpense == 0 can't produce a meaningful percent
  // change (division by zero), so no insight is shown for that case —
  // same for an exact 0% change, which isn't worth a line of text.
  String? _insightText(AppLocalizations l10n, ReportsSummary summary) {
    final previous = double.parse(summary.previousPeriodTotalExpense);
    if (previous <= 0) return null;

    final current = double.parse(summary.totalExpense);
    final changePercent = ((current - previous) / previous * 100).round();
    if (changePercent == 0) return null;

    return changePercent > 0
        ? l10n.statisticsInsightMore(changePercent.toString())
        : l10n.statisticsInsightLess(changePercent.abs().toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byCategoryAsync = ref.watch(byCategoryReportProvider(_period));
    final summaryAsync = ref.watch(reportsSummaryProvider(_period));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsScreenTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'week',
                  label: Text(l10n.statisticsPeriodWeek),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text(l10n.statisticsPeriodMonth),
                ),
                ButtonSegment(
                  value: 'year',
                  label: Text(l10n.statisticsPeriodYear),
                ),
              ],
              selected: {_period},
              onSelectionChanged:
                  (selection) => _changePeriod(selection.first),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) {
                final insight = _insightText(l10n, summary);
                if (insight == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => const SizedBox.shrink(),
            ),
            byCategoryAsync.when(
              data: (report) {
                final slices = prepareChartSlices(
                  report.categories,
                  l10n.statisticsOtherCategoryLabel,
                );
                final categoryNames = {
                  for (final category in report.categories)
                    category.categoryId: category.categoryName,
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CategoryPieChart(
                      slices: slices,
                      isSelected:
                          (slice) =>
                              !slice.isOther &&
                              _categorySelected &&
                              slice.categoryId == _selectedCategoryId,
                      onSliceTap: _onSliceTap,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.statisticsTransactionsSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final transactionsAsync = ref.watch(
                          _statisticsTransactionsProvider((
                            dateFrom: report.dateFrom,
                            dateTo: report.dateTo,
                          )),
                        );
                        return transactionsAsync.when(
                          data: (all) {
                            final visible = _visibleTransactions(all);
                            if (visible.isEmpty) {
                              return Text(l10n.statisticsEmptyMessage);
                            }
                            return Column(
                              children: [
                                for (final transaction in visible)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      categoryNames[transaction.categoryId] ??
                                          l10n.transactionTileNoCategory,
                                    ),
                                    subtitle: Text(transaction.occurredAt),
                                    trailing: Text(
                                      '-${transaction.amount} ${transaction.currency}',
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error: (error, _) => Text(l10n.errorNetwork),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(l10n.errorNetwork)),
            ),
          ],
        ),
      ),
    );
  }
}
