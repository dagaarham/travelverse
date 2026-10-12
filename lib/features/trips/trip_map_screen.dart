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

const _dayColors = [Color(0xFF0B7A75), Color(0xFFFF7A45), Color(0xFF6A1B9A), Color(0xFF1565C0), Color(0xFFC62828), Color(0xFF2E7D32)];

/// The itinerary on a map: numbered stops joined by a route line per day.
class TripMapScreen extends ConsumerStatefulWidget {
  const TripMapScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  int? _day;

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripProvider(widget.tripId)).value;
    final byId = ref.watch(placeByIdProvider);
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final days = [
      for (var d = 1; d <= trip.dayCount; d++)
        if (_day == null || _day == d) d,
    ];
    final stops = <(int, int, Place)>[];
    for (final d in days) {
      final items = trip.itemsForDay(d);
      for (var k = 0; k < items.length; k++) {
        final p = byId[items[k].placeId];
        if (p != null) stops.add((d, k + 1, p));
      }
    }
    var totalKm = 0.0;
    final lines = <Polyline>[];
    for (final d in days) {
      final pts = stops.where((s) => s.$1 == d).map((s) => LatLng(s.$3.lat, s.$3.lng)).toList();
      for (var i = 1; i < pts.length; i++) {
        totalKm += Geo.distanceKm(pts[i - 1].latitude, pts[i - 1].longitude, pts[i].latitude, pts[i].longitude);
      }
      if (pts.length > 1) {
        lines.add(
          Polyline(
            points: pts,
            strokeWidth: 4,
            color: _dayColors[(d - 1) % _dayColors.length],
            pattern: StrokePattern.dashed(segments: const [12, 6]),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('${trip.name} map')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('All days'), selected: _day == null, onSelected: (_) => setState(() => _day = null)),
                ),
                for (var d = 1; d <= trip.dayCount; d++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: _dayColors[(d - 1) % _dayColors.length], radius: 6),
                      label: Text('Day $d'),
                      selected: _day == d,
                      onSelected: (_) => setState(() => _day = d),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: stops.isEmpty
                ? const EmptyState(
                    icon: Icons.map_outlined,
                    title: 'No places to show',
                    message: 'Add places to this trip to see them on the map.',
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        key: ValueKey(_day),
                        options: fittedOptions([for (final s in stops) LatLng(s.$3.lat, s.$3.lng)], padding: 60),
                        children: [
                          ...osmBaseLayers(),
                          PolylineLayer(polylines: lines),
                          MarkerLayer(
                            markers: [
                              for (final s in stops)
                                Marker(
                                  point: LatLng(s.$3.lat, s.$3.lng),
                                  width: 34,
                                  height: 34,
                                  child: GestureDetector(
                                    onTap: () => context.push('/place/${s.$3.id}'),
                                    child: Tooltip(
                                      message: 'Day ${s.$1} · ${s.$3.name}',
                                      child: MapPin(color: _dayColors[(s.$1 - 1) % _dayColors.length], icon: Icons.place, label: '${s.$2}'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Text(
                              '${stops.length} stops · ${Geo.format(totalKm)} straight-line',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
