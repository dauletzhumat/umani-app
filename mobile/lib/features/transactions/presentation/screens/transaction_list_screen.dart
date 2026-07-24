import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../wallet/data/repositories/account_repository_impl.dart';
import '../../../wallet/domain/entities/account.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/transaction_tile.dart';

/// Transaction feed with account/category/period filters and cursor
/// pagination (T4.9, docs/04_User_Flows.md §5, docs/08_API.md §4/§10).
/// Not yet wired into app navigation — its intended entry point,
/// Dashboard (M8), doesn't exist yet.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();
  final List<Transaction> _items = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _initialLoading = true;
  bool _hasError = false;

  String? _accountId;
  String? _categoryId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? get _dateFrom =>
      _dateRange == null ? null : _formatDate(_dateRange!.start);
  String? get _dateTo =>
      _dateRange == null ? null : _formatDate(_dateRange!.end);

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _hasError = false;
    });
    try {
      final page = await ref
          .read(transactionRepositoryProvider)
          .fetchAll(
            accountId: _accountId,
            categoryId: _categoryId,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await ref
          .read(transactionRepositoryProvider)
          .fetchAll(
            accountId: _accountId,
            categoryId: _categoryId,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            cursor: _nextCursor,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked == null) return;
    setState(() => _dateRange = picked);
    _loadFirstPage();
  }

  Category? _categoryById(List<Category> categories, String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accounts = ref.watch(accountListProvider).value ?? const [];
    final categories =
        ref.watch(categoryListProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionListTitle)),
      body: Column(
        children: [
          _FilterBar(
            l10n: l10n,
            accounts: accounts,
            categories: categories,
            accountId: _accountId,
            categoryId: _categoryId,
            onAccountChanged: (value) {
              setState(() => _accountId = value);
              _loadFirstPage();
            },
            onCategoryChanged: (value) {
              setState(() => _categoryId = value);
              _loadFirstPage();
            },
            onPeriodTap: _pickDateRange,
          ),
          Expanded(child: _buildBody(l10n, categories)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<Category> categories) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(child: Text(l10n.errorNetwork));
    }
    if (_items.isEmpty) {
      return Center(child: Text(l10n.transactionListEmptyMessage));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final transaction = _items[index];
        return TransactionTile(
          key: ValueKey(transaction.id),
          transaction: transaction,
          category: _categoryById(categories, transaction.categoryId),
          onCategoryChanged: (category) {
            setState(() {
              _items[index] = Transaction(
                id: transaction.id,
                accountId: transaction.accountId,
                categoryId: category.id,
                amount: transaction.amount,
                currency: transaction.currency,
                type: transaction.type,
                occurredAt: transaction.occurredAt,
                note: transaction.note,
              );
            });
          },
          onDeleted: () => setState(() => _items.removeAt(index)),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.l10n,
    required this.accounts,
    required this.categories,
    required this.accountId,
    required this.categoryId,
    required this.onAccountChanged,
    required this.onCategoryChanged,
    required this.onPeriodTap,
  });

  final AppLocalizations l10n;
  final List<Account> accounts;
  final List<Category> categories;
  final String? accountId;
  final String? categoryId;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPeriodTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: accountId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: [
                DropdownMenuItem(
                  child: Text(l10n.transactionListFilterAllAccounts),
                ),
                ...accounts.map(
                  (account) => DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
                ),
              ],
              onChanged: onAccountChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: [
                DropdownMenuItem(
                  child: Text(l10n.transactionListFilterAllCategories),
                ),
                ...categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: onCategoryChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: l10n.transactionListFilterPeriodLabel,
            onPressed: onPeriodTap,
          ),
        ],
      ),
    );
  }
}
