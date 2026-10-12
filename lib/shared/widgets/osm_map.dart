import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// OpenStreetMap tile layer plus the attribution the OSM licence requires.
List<Widget> osmBaseLayers() => [
  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.travelverse.app', maxZoom: 19),
  RichAttributionWidget(
    attributions: [
      TextSourceAttribution('OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'))),
    ],
  ),
];

/// Round pin used for place markers.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color, required this.icon, this.label, this.selected = false});

  final Color color;
  final IconData icon;
  final String? label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: selected ? 3 : 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: label != null
          ? Text(
              label!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            )
          : Icon(icon, color: Colors.white, size: selected ? 20 : 16),
    );
  }
}

/// Fits the camera around [points] (or centres on a single point).
MapOptions fittedOptions(List<LatLng> points, {double padding = 48}) {
  if (points.isEmpty) return const MapOptions(initialCenter: LatLng(22.5, 79.0), initialZoom: 4.3);
  if (points.length == 1) return MapOptions(initialCenter: points.first, initialZoom: 12);
  return MapOptions(
    initialCameraFit: CameraFit.coordinates(coordinates: points, padding: EdgeInsets.all(padding), maxZoom: 14),
  );
}
