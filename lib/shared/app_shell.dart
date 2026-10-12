import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import 'widgets/common.dart';

/// Bottom navigation shell with an offline banner. When connectivity comes
/// back (an OS broadcast), pending offline changes are synced automatically.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(onlineProvider, (prev, next) {
      final was = prev?.value;
      final now = next.value;
      if (was == false && now == true) {
        ref.read(dataSyncProvider).refresh();
        showToast('Back online. Syncing your trips…');
      }
    });
    final online = ref.watch(onlineProvider).value ?? true;

    return Scaffold(
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: online
                ? const SizedBox(width: double.infinity)
                : Material(
                    color: Colors.grey.shade800,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'You are offline. Trips and journal still work and will sync later.',
                                style: TextStyle(color: Colors.grey.shade100, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: !online, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.luggage_outlined), selectedIcon: Icon(Icons.luggage), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
