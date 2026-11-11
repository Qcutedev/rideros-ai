import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_labels.dart';
import 'pickup_providers.dart';

/// Pickup tab (S-PICKUP-SEARCH): search restaurants by name, filter by source,
/// entry points to history, own logs and the model card.
///
/// With [onSelect] it is the restaurant picker of the log form instead: tapping a
/// row returns the restaurant and the entry points are hidden.
class PickupSearchScreen extends StatefulWidget {
  const PickupSearchScreen({this.onSelect, super.key});

  final ValueChanged<Restaurant>? onSelect;

  @override
  State<PickupSearchScreen> createState() => _PickupSearchScreenState();
}

class _PickupSearchScreenState extends State<PickupSearchScreen> {
  static const _debounce = Duration(milliseconds: 350);

  final _search = TextEditingController();
  Timer? _timer;
  RestaurantQuery _query = const RestaurantQuery();

  bool get _picking => widget.onSelect != null;

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => _apply(value));
    setState(() {}); // Clear button visibility.
  }

  void _apply(String value) {
    final text = value.trim();
    final capped = text.length > PickupLimits.searchMaxLength
        ? text.substring(0, PickupLimits.searchMaxLength)
        : text;
    if (capped == _query.text) return;
    setState(
      () => _query = RestaurantQuery(text: capped, source: _query.source),
    );
  }

  void _clear() {
    _timer?.cancel();
    _search.clear();
    _apply('');
  }

  void _open(Restaurant restaurant) {
    final onSelect = widget.onSelect;
    if (onSelect != null) {
      onSelect(restaurant);
    } else {
      context.push(Routes.restaurant(restaurant.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    void addOwn() => context.push(Routes.ownRestaurantNew);
    return Scaffold(
      appBar: AppBar(
        title: Text(_picking ? l10n.pickerTitle : l10n.pickupTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('pickup.addOwn'),
        onPressed: addOwn,
        icon: const Icon(Icons.add_business_outlined),
        label: Text(l10n.pickupAddOwn),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('pickup.search'),
              controller: _search,
              onChanged: _onSearchChanged,
              onSubmitted: _apply,
              maxLength: PickupLimits.searchMaxLength,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.pickupSearchLabel,
                hintText: l10n.pickupSearchHint,
                counterText: '',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('pickup.search.clear'),
                        tooltip: l10n.pickupSearchClear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<RestaurantSourceFilter>(
              key: const Key('pickup.filter'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: RestaurantSourceFilter.all,
                  label: Text(l10n.pickupFilterAll),
                ),
                ButtonSegment(
                  value: RestaurantSourceFilter.dataset,
                  label: Text(l10n.pickupFilterDataset),
                ),
                ButtonSegment(
                  value: RestaurantSourceFilter.own,
                  label: Text(l10n.pickupFilterOwn),
                ),
              ],
              selected: {_query.source},
              onSelectionChanged: (selection) => setState(
                () => _query = RestaurantQuery(
                  text: _query.text,
                  source: selection.single,
                ),
              ),
            ),
          ),
          if (!_picking)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  _EntryChip(
                    key: const Key('pickup.history'),
                    icon: Icons.history_rounded,
                    label: l10n.pickupHistory,
                    onTap: () => context.push(Routes.predictionHistory),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _EntryChip(
                    key: const Key('pickup.logs'),
                    icon: Icons.timer_outlined,
                    label: l10n.pickupMyLogs,
                    onTap: () => context.push(Routes.pickupLogs),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _EntryChip(
                    key: const Key('pickup.model'),
                    icon: Icons.insights_outlined,
                    label: l10n.pickupModelInfo,
                    onTap: () => context.push(Routes.modelInfo),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: PagedListView<Restaurant>(
              key: ValueKey(_query),
              provider: restaurantListProvider(_query),
              keyPrefix: 'pickup',
              loading: const SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ListSkeleton(rows: 5),
              ),
              header: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  l10n.pickupDatasetNote,
                  key: const Key('pickup.datasetNote'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              empty: StatusView(
                icon: Icons.storefront_outlined,
                title: l10n.pickupEmptyTitle,
                message: l10n.pickupEmptyMessage,
                actionLabel: l10n.pickupAddOwn,
                onAction: addOwn,
              ),
              itemBuilder: (restaurant) => _RestaurantTile(
                restaurant: restaurant,
                onTap: () => _open(restaurant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: onTap,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant, required this.onTap});

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orders = restaurant.nOrders;
    return ListTile(
      key: Key('restaurant.${restaurant.id}'),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: RoundIcon(
        restaurant.isOwn ? Icons.storefront_outlined : Icons.dataset_outlined,
      ),
      title: Text(restaurant.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantBadges(restaurant: restaurant),
            if (!restaurant.isOwn && orders != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.pickupOrdersInData(Formats.count(orders))),
            ],
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
