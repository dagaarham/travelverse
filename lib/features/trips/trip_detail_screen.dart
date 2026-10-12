import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../core/export_builder.dart';
import '../../core/formatters.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_cards.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _exportCsv(BuildContext context, WidgetRef ref, Trip trip) async {
    try {
      final csv = ExportBuilder.tripCsv(trip, ref.read(placeByIdProvider));
      await ref
          .read(exportServiceProvider)
          .saveAndShare(fileName: ExportBuilder.fileName(trip.name, 'csv'), content: csv, mimeType: 'text/csv');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Export failed: ${friendlyError(e)}', error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Trip trip) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete "${trip.name}"?',
      message: 'The itinerary will be removed from this phone and your account. Journal entries are kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(tripRepositoryProvider).deleteTrip(trip);
    await ref.read(dataSyncProvider).refresh();
    showToast('Trip deleted');
    if (context.mounted) context.pop();
  }

  Future<void> _removeItem(BuildContext context, WidgetRef ref, Trip trip, TripItem item, String name) async {
    final ok = await confirmDialog(
      context,
      title: 'Remove $name?',
      message: 'It will be removed from Day ${item.day}.',
      confirmLabel: 'Remove',
    );
    if (!ok) return;
    await ref.read(tripRepositoryProvider).removeItem(trip, item);
    await ref.read(dataSyncProvider).refresh();
  }

  Future<void> _addPlaces(BuildContext context, WidgetRef ref, Trip trip, int day) async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PlacePicker(),
    );
    if (place == null) return;
    if (trip.items.any((i) => i.placeId == place.id && i.day == day)) {
      if (context.mounted) showSnack(context, '${place.name} is already on Day $day', error: true);
      return;
    }
    await ref.read(tripRepositoryProvider).addPlace(trip, placeId: place.id, day: day);
    await ref.read(dataSyncProvider).refresh();
    showToast('${place.name} added to Day $day');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    final byId = ref.watch(placeByIdProvider);
    return tripAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: friendlyError(e)),
      ),
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.luggage, title: 'Trip not found', message: 'It may have been deleted.'),
          );
        }
        return DefaultTabController(
          length: trip.dayCount,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              actions: [
                IconButton(
                  tooltip: 'View on map',
                  onPressed: () => context.push('/trips/${trip.id}/map'),
                  icon: const Icon(Icons.map_outlined),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        context.push('/trips/${trip.id}/edit');
                      case 'journal':
                        context.push('/journal?tripId=${trip.id}');
                      case 'csv':
                        _exportCsv(context, ref, trip);
                      case 'delete':
                        _delete(context, ref, trip);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit trip')),
                    ),
                    PopupMenuItem(
                      value: 'journal',
                      child: ListTile(leading: Icon(Icons.menu_book_outlined), title: Text('Trip journal')),
                    ),
                    PopupMenuItem(
                      value: 'csv',
                      child: ListTile(leading: Icon(Icons.table_view_outlined), title: Text('Export itinerary (.csv)')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete trip'),
                      ),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(116),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${trip.destination} · ${trip.tripType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  '${Fmt.range(trip.startDate, trip.endDate)} · ${trip.travellers} travellers · ${Fmt.rupees(trip.budget)}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                                if (trip.notes.isNotEmpty)
                                  Text(
                                    trip.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: trip.synced ? 'Synced to your account' : 'Saved on this phone; will sync when online',
                            child: Icon(trip.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        for (var d = 1; d <= trip.dayCount; d++)
                          Tab(text: 'Day $d · ${Fmt.shortDate(trip.startDate.add(Duration(days: d - 1)))}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                for (var d = 1; d <= trip.dayCount; d++)
                  Builder(
                    builder: (context) {
                      final items = trip.itemsForDay(d);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: EmptyState(
                                icon: Icons.add_location_alt_outlined,
                                title: 'Nothing planned for Day $d',
                                message: 'Add places from Explore or tap the button below.',
                              ),
                            ),
                          for (var k = 0; k < items.length; k++)
                            if (byId[items[k].placeId] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 36, right: 8),
                                      child: CircleAvatar(
                                        radius: 13,
                                        child: Text('${k + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          PlaceTile(
                                            place: byId[items[k].placeId]!,
                                            trailing: IconButton(
                                              tooltip: 'Remove from day',
                                              icon: const Icon(Icons.remove_circle_outline),
                                              onPressed: () => _removeItem(context, ref, trip, items[k], byId[items[k].placeId]!.name),
                                            ),
                                          ),
                                          if (items[k].note.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                              child: Text('📝 ${items[k].note}', style: TextStyle(color: Colors.grey.shade700)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          OutlinedButton.icon(
                            onPressed: () => _addPlaces(context, ref, trip, d),
                            icon: const Icon(Icons.add),
                            label: Text('Add a place to Day $d'),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/journal/new?tripId=${trip.id}'),
              icon: const Icon(Icons.edit_note),
              label: const Text('Journal entry'),
            ),
          ),
        );
      },
    );
  }
}

class _PlacePicker extends ConsumerStatefulWidget {
  const _PlacePicker();

  @override
  ConsumerState<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<_PlacePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final places = ref
        .watch(placesProvider)
        .where((p) => '${p.name} ${p.city} ${p.state}'.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search places to add', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => PlaceTile(place: places[i], onTap: () => Navigator.pop(context, places[i])),
            ),
          ),
        ],
      ),
    );
  }
}
