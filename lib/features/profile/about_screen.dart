import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.travel_explore, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('TravelVerse', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const Center(child: Text('Discover. Plan. Remember.  ·  Version 1.0.0')),
          const SizedBox(height: 24),
          const Text(
            'TravelVerse is a community-driven travel companion. Discover places through honest, structured reviews from '
            'fellow travellers, plan day-wise itineraries that work offline, and keep a photo journal of every trip.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('Mini project · Mobile Application Development'),
            subtitle: Text('MPSTME, NMIMS · 2026-27'),
          ),
          const ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Team'),
            subtitle: Text('Arham Daga · Manthan Bumb · Prithvi Agarwal'),
          ),
          const ListTile(
            leading: Icon(Icons.copyright),
            title: Text('Credits'),
            subtitle: Text(
              'Maps © OpenStreetMap contributors. Place photos from Wikipedia / Wikimedia Commons under their respective licences.',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => showLicensePage(context: context, applicationName: 'TravelVerse', applicationVersion: '1.0.0'),
              child: const Text('Open-source licences'),
            ),
          ),
        ],
      ),
    );
  }
}
