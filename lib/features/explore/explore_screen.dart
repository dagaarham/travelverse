import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_cards.dart';

enum SortOption {
  recommended('Recommended'),
  rating('Highest rated'),
  popularity('Most popular'),
  distance('Nearest first'),
  name('Name (A-Z)');

  const SortOption(this.label);
  final String label;
}

/// Search + filters: category chips, sort spinner (dropdown), minimum rating,
/// budget and travel-companion filters.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();
  final Set<PlaceCategory> _categories = {};
  SortOption _sort = SortOption.recommended;
  double _minRating = 0;
  int? _maxBudget;
  String? _companion;
  double? _maxDistanceKm;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _activeFilters =>
      (_minRating > 0 ? 1 : 0) + (_maxBudget != null ? 1 : 0) + (_companion != null ? 1 : 0) + (_maxDistanceKm != null ? 1 : 0);

  List<(Place, double?)> _results() {
    final places = ref.watch(placesProvider);
    final ratingOf = ref.watch(ratingOfProvider);
    final pos = ref.watch(positionProvider).value;
    final recScore = {for (final r in ref.watch(recommendationsProvider)) r.place.id: r.score};
    final q = _search.text.trim().toLowerCase();

    final list = <(Place, double?)>[];
    for (final p in places) {
      final km = pos == null ? null : Geo.distanceKm(pos.latitude, pos.longitude, p.lat, p.lng);
      if (q.isNotEmpty && !('${p.name} ${p.city} ${p.state} ${p.category.label} ${p.description}'.toLowerCase().contains(q))) {
        continue;
      }
      if (_categories.isNotEmpty && !_categories.contains(p.category)) continue;
      if (ratingOf(p) < _minRating) continue;
      if (_maxBudget != null && p.budget > _maxBudget!) continue;
      if (_companion != null && !p.idealFor.contains(_companion)) continue;
      if (_maxDistanceKm != null && (km == null || km > _maxDistanceKm!)) continue;
      list.add((p, km));
    }
    int cmp((Place, double?) a, (Place, double?) b) {
      switch (_sort) {
        case SortOption.rating:
          return ratingOf(b.$1).compareTo(ratingOf(a.$1));
        case SortOption.popularity:
          return b.$1.popularity.compareTo(a.$1.popularity);
        case SortOption.distance:
          return (a.$2 ?? double.infinity).compareTo(b.$2 ?? double.infinity);
        case SortOption.name:
          return a.$1.name.compareTo(b.$1.name);
        case SortOption.recommended:
          return (recScore[b.$1.id] ?? -99).compareTo(recScore[a.$1.id] ?? -99) != 0
              ? (recScore[b.$1.id] ?? -99).compareTo(recScore[a.$1.id] ?? -99)
              : ratingOf(b.$1).compareTo(ratingOf(a.$1));
      }
    }

    return list..sort(cmp);
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterSheet(
        minRating: _minRating,
        maxBudget: _maxBudget,
        companion: _companion,
        maxDistanceKm: _maxDistanceKm,
        hasLocation: ref.read(positionProvider).value != null,
        onApply: (minRating, maxBudget, companion, maxDistance) => setState(() {
          _minRating = minRating;
          _maxBudget = maxBudget;
          _companion = companion;
          _maxDistanceKm = maxDistance;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('explore_search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by place, city, state or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final c in PlaceCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(c.icon, size: 18, color: c.color),
                      label: Text(c.label),
                      selected: _categories.contains(c),
                      onSelected: (v) => setState(() => v ? _categories.add(c) : _categories.remove(c)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SortOption>(
                    key: const Key('explore_sort'),
                    initialValue: _sort,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      prefixIcon: Icon(Icons.sort),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [for (final s in SortOption.values) DropdownMenuItem(value: s, child: Text(s.label))],
                    onChanged: (v) async {
                      if (v == SortOption.distance && ref.read(positionProvider).value == null) {
                        await ref.read(positionProvider.notifier).locate();
                        final err = ref.read(positionProvider).error;
                        if (err != null && context.mounted) showSnack(context, err.toString(), error: true);
                      }
                      setState(() => _sort = v ?? SortOption.recommended);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _activeFilters > 0,
                  label: Text('$_activeFilters'),
                  child: OutlinedButton.icon(onPressed: _openFilters, icon: const Icon(Icons.tune), label: const Text('Filters')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${results.length} place${results.length == 1 ? '' : 's'} found', style: TextStyle(color: Colors.grey.shade600)),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'No places match',
                    message: 'Try a different search or clear some filters.',
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _categories.clear();
                        _minRating = 0;
                        _maxBudget = null;
                        _companion = null;
                        _maxDistanceKm = null;
                      }),
                      child: const Text('Clear all'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => PlaceTile(place: results[i].$1, distanceKm: results[i].$2),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.minRating,
    required this.maxBudget,
    required this.companion,
    required this.maxDistanceKm,
    required this.hasLocation,
    required this.onApply,
  });

  final double minRating;
  final int? maxBudget;
  final String? companion;
  final double? maxDistanceKm;
  final bool hasLocation;
  final void Function(double, int?, String?, double?) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minRating = widget.minRating;
  late int? _maxBudget = widget.maxBudget;
  late String? _companion = widget.companion;
  late double? _maxDistance = widget.maxDistanceKm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text('Minimum rating: ${_minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}★ and above'}', style: t),
            Slider(
              value: _minRating,
              min: 0,
              max: 4.5,
              divisions: 9,
              label: _minRating.toStringAsFixed(1),
              onChanged: (v) => setState(() => _minRating = v),
            ),
            Text('Budget', style: t),
            const SizedBox(height: 8),
            SegmentedButton<int?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Any')),
                ButtonSegment(value: 1, label: Text('₹')),
                ButtonSegment(value: 2, label: Text('₹₹')),
                ButtonSegment(value: 3, label: Text('₹₹₹')),
              ],
              selected: {_maxBudget},
              onSelectionChanged: (s) => setState(() => _maxBudget = s.first),
            ),
            const SizedBox(height: 16),
            Text('Travelling with', style: t),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in const ['solo', 'couple', 'family', 'friends'])
                  ChoiceChip(
                    label: Text(c[0].toUpperCase() + c.substring(1)),
                    selected: _companion == c,
                    onSelected: (v) => setState(() => _companion = v ? c : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Distance from me', style: t),
            if (!widget.hasLocation)
              Text('Turn on location from the Map tab to filter by distance.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [null, 5.0, 25.0, 100.0, 500.0])
                  ChoiceChip(
                    label: Text(d == null ? 'Any' : '< ${d.round()} km'),
                    selected: _maxDistance == d,
                    onSelected: widget.hasLocation || d == null ? (_) => setState(() => _maxDistance = d) : null,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _minRating = 0;
                      _maxBudget = null;
                      _companion = null;
                      _maxDistance = null;
                    }),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () {
                      widget.onApply(_minRating, _maxBudget, _companion, _maxDistance);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
