import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_records.dart';
import 'profit_labels.dart';
import 'profit_providers.dart';

/// Income, expenses and work sessions, newest first, each in its own tab.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({this.initialTab = RecordsTab.income, super.key});

  final RecordsTab initialTab;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: RecordsTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  )..addListener(_onTabChanged);

  RecordsTab get _tab => RecordsTab.values[_tabs.index];

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (String addLabel, String addRoute) = switch (_tab) {
      RecordsTab.income => (l10n.incomeAdd, Routes.incomeNew),
      RecordsTab.expenses => (l10n.expenseAdd, Routes.expenseNew),
      RecordsTab.sessions => (l10n.sessionAdd, Routes.workSessionNew),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(key: const Key('records.tab.income'), text: l10n.incomeTitle),
            Tab(
              key: const Key('records.tab.expenses'),
              text: l10n.expenseTitle,
            ),
            Tab(
              key: const Key('records.tab.sessions'),
              text: l10n.sessionTitle,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('records.add'),
        onPressed: () => context.push(addRoute),
        icon: const Icon(Icons.add_rounded),
        label: Text(addLabel),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          PagedListView<Income>(
            provider: incomeListProvider,
            empty: StatusView(
              icon: Icons.inbox_outlined,
              title: l10n.incomeEmptyTitle,
              message: l10n.incomeEmptyMessage,
              actionLabel: l10n.incomeAdd,
              onAction: () => context.push(Routes.incomeNew),
            ),
            itemBuilder: (income) => _IncomeTile(income: income),
          ),
          PagedListView<Expense>(
            provider: expenseListProvider,
            empty: StatusView(
              icon: Icons.inbox_outlined,
              title: l10n.expenseEmptyTitle,
              message: l10n.expenseEmptyMessage,
              actionLabel: l10n.expenseAdd,
              onAction: () => context.push(Routes.expenseNew),
            ),
            itemBuilder: (expense) => _ExpenseTile(expense: expense),
          ),
          PagedListView<WorkSession>(
            provider: workSessionListProvider,
            empty: StatusView(
              icon: Icons.inbox_outlined,
              title: l10n.sessionEmptyTitle,
              message: l10n.sessionEmptyMessage,
              actionLabel: l10n.sessionAdd,
              onAction: () => context.push(Routes.workSessionNew),
            ),
            itemBuilder: (session) => _SessionTile(session: session),
          ),
        ],
      ),
    );
  }
}

/// Record row on the surface colour (the list sits on the app background).
class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDemo,
    required this.onTap,
    this.subtitleLines = 1,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDemo;
  final VoidCallback onTap;
  final int subtitleLines;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Theme.of(context).colorScheme.surface,
    leading: RoundIcon(icon),
    title: Text(title),
    subtitle: Text(
      subtitle,
      maxLines: subtitleLines,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDemo) AppBadge.demo(context),
        const SizedBox(width: AppSpacing.xs),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
    onTap: onTap,
  );
}

String _join(Iterable<String?> parts) =>
    parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income});

  final Income income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _RecordTile(
      key: Key('income.${income.id}'),
      icon: Icons.payments_outlined,
      title: Formats.money(income.amount),
      subtitle: _join([
        Formats.date(income.occurredOn, l10n.localeName),
        income.sourceLabel,
        if (income.orderCount != null) l10n.ordersValue(income.orderCount!),
      ]),
      isDemo: income.isDemo,
      onTap: () => context.push(Routes.incomeEdit(income.id)),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  static IconData _icon(ExpenseCategory category) => switch (category) {
    ExpenseCategory.fuel => Icons.local_gas_station_outlined,
    ExpenseCategory.maintenance => Icons.build_outlined,
    ExpenseCategory.depreciation => Icons.trending_down_rounded,
    ExpenseCategory.other => Icons.receipt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _RecordTile(
      key: Key('expense.${expense.id}'),
      icon: _icon(expense.category),
      title: Formats.money(expense.amount),
      subtitle: _join([
        expenseCategoryLabel(l10n, expense.category),
        Formats.date(expense.occurredOn, l10n.localeName),
        expense.description,
      ]),
      subtitleLines: 2,
      isDemo: expense.isDemo,
      onTap: () => context.push(Routes.expenseEdit(expense.id)),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _RecordTile(
      key: Key('session.${session.id}'),
      icon: Icons.timer_outlined,
      title:
          '${Formats.date(session.startedAt, l10n.localeName)}  '
          '${sessionTimeRange(l10n, session)}',
      subtitle: _join([
        durationLabel(l10n, session.duration),
        if (session.orderCount != null) l10n.ordersValue(session.orderCount!),
        if (session.distanceKm != null)
          l10n.distanceValue(Formats.compact(session.distanceKm!)),
      ]),
      isDemo: session.isDemo,
      onTap: () => context.push(Routes.workSessionEdit(session.id)),
    );
  }
}
