import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/badges.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_cards.dart';
import '../place/place_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'Trips and journal entries stay saved on this phone.',
      confirmLabel: 'Log out',
    );
    if (ok) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final byId = ref.watch(placeByIdProvider);
    final visited = profile.visitedPlaceIds.map((id) => byId[id]).whereType<Place>().toList();
    final saved = profile.savedPlaceIds.map((id) => byId[id]).whereType<Place>().toList();
    final reviews = ref.watch(myReviewsProvider).value ?? const [];
    final trips = ref.watch(tripsProvider).value ?? const [];
    final journal = ref.watch(journalProvider(null)).value ?? const [];
    final badges = computeBadges(visited: visited, reviewCount: reviews.length, tripCount: trips.length, journalCount: journal.length);
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            PopupMenuButton<String>(
              key: const Key('profile_menu'),
              tooltip: 'Menu',
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    context.push('/profile/edit');
                  case 'prefs':
                    context.push('/profile/preferences');
                  case 'journal':
                    context.push('/journal');
                  case 'sos':
                    context.push('/sos');
                  case 'about':
                    context.push('/about');
                  case 'logout':
                    _logout(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.person_outline), title: Text('Edit profile')),
                ),
                PopupMenuItem(
                  value: 'prefs',
                  child: ListTile(leading: Icon(Icons.tune), title: Text('Travel preferences')),
                ),
                PopupMenuItem(
                  value: 'journal',
                  child: ListTile(leading: Icon(Icons.menu_book_outlined), title: Text('Travel journal')),
                ),
                PopupMenuItem(
                  value: 'sos',
                  child: ListTile(leading: Icon(Icons.sos_outlined), title: Text('Travel assistance')),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: ListTile(leading: Icon(Icons.info_outline), title: Text('About')),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Log out'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: scheme.primary,
                          child: Text(
                            profile.initials,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              if (profile.homeCity.isNotEmpty)
                                Text('🏠 ${profile.homeCity}', style: TextStyle(color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              TagChip(label: travelPersonality(visited, profile.interests)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (profile.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(profile.bio)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Stat('${visited.length}', 'Places'),
                            _Stat('${visited.map((p) => p.city).toSet().length}', 'Cities'),
                            _Stat('${visited.map((p) => p.state).toSet().length}', 'States'),
                            _Stat('${reviews.length}', 'Reviews'),
                            _Stat('${trips.length}', 'Trips'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Badges', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: badges.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _BadgeTile(badge: badges[i]),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabHeader(
                TabBar(
                  tabs: [
                    Tab(text: 'Want to visit (${saved.length})'),
                    Tab(text: 'Visited (${visited.length})'),
                    Tab(text: 'Reviews (${reviews.length})'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _PlaceList(places: saved, empty: 'Tap the ♡ on any place, or long-press a card, to save it here.'),
              _PlaceList(places: visited, empty: 'Open a place and tap "Mark visited" to build your travel history.'),
              reviews.isEmpty
                  ? const EmptyState(
                      icon: Icons.rate_review_outlined,
                      title: 'No reviews yet',
                      message: 'Share your experiences to help other travellers.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => context.push('/place/${reviews[i].placeId}'),
                        child: ReviewCard(review: reviews[i], showPlace: byId[reviews[i].placeId]?.name),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    ],
  );
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final TravelBadge badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: badge.description,
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(value: badge.progress, strokeWidth: 3, backgroundColor: Colors.grey.shade200),
                ),
                CircleAvatar(
                  radius: 23,
                  backgroundColor: badge.earned ? scheme.primary : Colors.grey.shade200,
                  child: Icon(badge.icon, color: badge.earned ? Colors.white : Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badge.earned ? null : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({required this.places, required this.empty});

  final List<Place> places;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return EmptyState(icon: Icons.place_outlined, title: 'Nothing here yet', message: empty);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => PlaceTile(place: places[i]),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  _TabHeader(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);

  @override
  bool shouldRebuild(_TabHeader oldDelegate) => oldDelegate.tabBar != tabBar;
}
