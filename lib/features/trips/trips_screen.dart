import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../data/models/trip.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_image.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My trips'),
        actions: [
          IconButton(tooltip: 'Travel journal', onPressed: () => context.push('/journal'), icon: const Icon(Icons.menu_book_outlined)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_trip_fab'),
        onPressed: () => context.push('/trips/new'),
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: 'Could not load your trips.', onRetry: () => ref.invalidate(tripsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.luggage_outlined,
              title: 'No trips yet',
              message: 'Plan your next adventure day by day. Trips are saved on your phone and work offline.',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => context.push('/trips/new'),
                icon: const Icon(Icons.add),
                label: const Text('Plan a trip'),
              ),
            );
          }
          final today = DateTime.now();
          final upcoming = list.where((t) => !t.endDate.isBefore(DateTime(today.year, today.month, today.day))).toList();
          final past = list.where((t) => !upcoming.contains(t)).toList().reversed.toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(dataSyncProvider).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (upcoming.isNotEmpty) ...[_Label('Upcoming & ongoing'), for (final t in upcoming) _TripCard(trip: t)],
                if (past.isNotEmpty) ...[_Label('Past trips'), for (final t in past) _TripCard(trip: t)],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey.shade700),
    ),
  );
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byId = ref.watch(placeByIdProvider);
    final cover = trip.items.map((i) => byId[i.placeId]).whereType<Object>().firstOrNull;
    final days = trip.dayCount;
    final today = DateTime.now();
    final startsIn = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/trips/${trip.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover != null)
                      PlaceImage(place: byId[trip.items.first.placeId]!, radius: 0)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]),
                        ),
                        child: const Icon(Icons.luggage, color: Colors.white70, size: 48),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: TagChip(
                        label: startsIn > 0
                            ? 'In $startsIn day${startsIn == 1 ? '' : 's'}'
                            : (trip.endDate.isBefore(today) ? 'Completed' : 'Ongoing'),
                        color: Colors.white,
                      ),
                    ),
                    if (!trip.synced)
                      const Positioned(
                        right: 12,
                        top: 12,
                        child: Tooltip(
                          message: 'Saved offline, will sync',
                          child: Icon(Icons.cloud_off, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text('${trip.destination} · ${Fmt.range(trip.startDate, trip.endDate)}', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        TagChip(label: '$days day${days == 1 ? '' : 's'}', icon: Icons.calendar_today),
                        TagChip(label: '${trip.items.length} place${trip.items.length == 1 ? '' : 's'}', icon: Icons.place_outlined),
                        TagChip(label: '${trip.travellers} traveller${trip.travellers == 1 ? '' : 's'}', icon: Icons.group_outlined),
                        TagChip(label: Fmt.rupees(trip.budget), icon: Icons.account_balance_wallet_outlined, color: Colors.green.shade700),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
