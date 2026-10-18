import 'package:flutter/material.dart';

import '../../shared/widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: AppLogo(size: 80)),
          const SizedBox(height: 12),
          Center(
            child: Text('TouchGrass', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const Center(child: Text('Discover. Plan. Remember.  ·  Version 1.0.0')),
          const SizedBox(height: 24),
          const Text(
            'TouchGrass is a community-driven travel companion. Discover places through honest, structured reviews from '
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
              'Maps © OpenStreetMap contributors. Place photos from Wikimedia Commons contributors under CC licences (full list in assets/places/CREDITS.md).',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => showLicensePage(context: context, applicationName: 'TouchGrass', applicationVersion: '1.0.0'),
              child: const Text('Open-source licences'),
            ),
          ),
        ],
      ),
    );
  }
}
