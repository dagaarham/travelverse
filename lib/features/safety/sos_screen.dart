import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../shared/widgets/common.dart';

/// Travel assistance: one-tap emergency calls and location sharing, all via
/// implicit intents (dialler, SMS, maps).
class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  static const _numbers = [
    ('National emergency', '112', Icons.sos, Colors.red),
    ('Police', '100', Icons.local_police_outlined, Colors.indigo),
    ('Ambulance', '108', Icons.emergency_outlined, Colors.pink),
    ('Fire', '101', Icons.local_fire_department_outlined, Colors.deepOrange),
    ('Women helpline', '1091', Icons.support_agent, Colors.purple),
    ('Tourist helpline', '1363', Icons.travel_explore, Colors.teal),
  ];

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri) && context.mounted) {
      showSnack(context, 'No app available to handle this on this device.', error: true);
    }
  }

  Future<void> _shareLocation(BuildContext context, WidgetRef ref) async {
    await ref.read(positionProvider.notifier).locate();
    final state = ref.read(positionProvider);
    if (!context.mounted) return;
    if (state.hasError || state.value == null) {
      showSnack(context, state.error?.toString() ?? 'Location unavailable', error: true);
      return;
    }
    final p = state.value!;
    final msg = 'I need help. My current location: https://maps.google.com/?q=${p.latitude},${p.longitude}';
    await _launch(context, Uri(scheme: 'sms', queryParameters: {'body': msg}));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(positionProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Travel assistance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Tap a service to open the dialler. Calls are placed by your phone, not by TouchGrass.')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              for (final n in _numbers)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _launch(context, Uri(scheme: 'tel', path: n.$2)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(n.$3, color: n.$4, size: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                n.$2,
                                style: TextStyle(color: n.$4, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: loading ? null : () => _shareLocation(context, ref),
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.share_location),
            label: const Text('Share my location by SMS'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _launch(context, Uri.parse('https://www.google.com/maps/search/hospital/')),
            icon: const Icon(Icons.local_hospital_outlined),
            label: const Text('Find nearest hospital'),
          ),
        ],
      ),
    );
  }
}
