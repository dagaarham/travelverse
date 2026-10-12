import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geo.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/osm_map.dart';
import '../../shared/widgets/place_cards.dart';

enum MapLayer { all, saved, visited }

/// Explore map: every place as a marker, current location, "near me"
/// radius search and saved/visited layers.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  Place? _selected;
  MapLayer _layer = MapLayer.all;
  double _radiusKm = 50;

  Future<void> _locate({bool openNearby = false}) async {
    await ref.read(positionProvider.notifier).locate();
    final state = ref.read(positionProvider);
    if (!mounted) return;
    if (state.hasError) {
      showSnack(context, state.error.toString(), error: true);
      return;
    }
    final pos = state.value;
    if (pos == null) return;
    _map.move(LatLng(pos.latitude, pos.longitude), 10);
    if (openNearby) _showNearby();
  }

  List<Place> _visiblePlaces() {
    final places = ref.watch(placesProvider);
    final profile = ref.watch(profileProvider).value;
    switch (_layer) {
      case MapLayer.all:
        return places;
      case MapLayer.saved:
        return places.where((p) => profile?.savedPlaceIds.contains(p.id) ?? false).toList();
      case MapLayer.visited:
        return places.where((p) => profile?.visitedPlaceIds.contains(p.id) ?? false).toList();
    }
  }

  void _showNearby() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          final pos = ref.read(positionProvider).value!;
          final nearby = [
            for (final p in ref.read(placesProvider)) (p, Geo.distanceKm(pos.latitude, pos.longitude, p.lat, p.lng)),
          ].where((e) => e.$2 <= _radiusKm).toList()..sort((a, b) => a.$2.compareTo(b.$2));
          final counts = <PlaceCategory, int>{};
          for (final n in nearby) {
            counts[n.$1.category] = (counts[n.$1.category] ?? 0) + 1;
          }
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            builder: (context, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  'Places within ${_radiusKm.round()} km',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: _radiusKm,
                  min: 5,
                  max: 500,
                  divisions: 99,
                  label: '${_radiusKm.round()} km',
                  onChanged: (v) {
                    setSheet(() {});
                    setState(() => _radiusKm = v);
                  },
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final e in counts.entries) TagChip(label: '${e.value} ${e.key.label}', icon: e.key.icon, color: e.key.color),
                  ],
                ),
                const SizedBox(height: 12),
                if (nearby.isEmpty)
                  const EmptyState(
                    icon: Icons.explore_off,
                    title: 'Nothing nearby',
                    message: 'Increase the radius to discover more places.',
                  )
                else
                  for (final n in nearby)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PlaceTile(place: n.$1, distanceKm: n.$2),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(positionProvider);
    final places = _visiblePlaces();
    final me = pos.value == null ? null : LatLng(pos.value!.latitude, pos.value!.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          PopupMenuButton<MapLayer>(
            tooltip: 'Map layers',
            icon: const Icon(Icons.layers_outlined),
            initialValue: _layer,
            onSelected: (l) => setState(() {
              _layer = l;
              _selected = null;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: MapLayer.all, child: Text('All places')),
              PopupMenuItem(value: MapLayer.saved, child: Text('Want to visit')),
              PopupMenuItem(value: MapLayer.visited, child: Text('Visited')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: const LatLng(22.5, 79.0),
              initialZoom: 4.3,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              ...osmBaseLayers(),
              if (me != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: me,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.07),
                      borderColor: Colors.blue.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final p in places)
                    Marker(
                      point: LatLng(p.lat, p.lng),
                      width: _selected?.id == p.id ? 40 : 32,
                      height: _selected?.id == p.id ? 40 : 32,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = p),
                        child: MapPin(color: p.category.color, icon: p.category.icon, selected: _selected?.id == p.id),
                      ),
                    ),
                  if (me != null)
                    Marker(
                      point: me,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: pos.isLoading ? null : () => me == null ? _locate(openNearby: true) : _showNearby(),
                    icon: pos.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.near_me),
                    label: const Text('Explore nearby'),
                  ),
                ),
              ],
            ),
          ),
          if (_layer != MapLayer.all && places.isEmpty)
            Positioned(
              top: 70,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _layer == MapLayer.saved ? 'You have not saved any places yet.' : 'You have not marked any places as visited yet.',
                  ),
                ),
              ),
            ),
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: PlaceTile(
                place: _selected!,
                distanceKm: me == null ? null : Geo.distanceKm(me.latitude, me.longitude, _selected!.lat, _selected!.lng),
                onTap: () => context.push('/place/${_selected!.id}'),
              ),
            ),
        ],
      ),
      floatingActionButton: _selected != null
          ? null
          : FloatingActionButton(tooltip: 'My location', onPressed: pos.isLoading ? null : _locate, child: const Icon(Icons.my_location)),
    );
  }
}
