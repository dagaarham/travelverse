import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/geo.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_cards.dart';
import '../../shared/widgets/rating.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final recs = ref.watch(recommendationsProvider);
    final places = ref.watch(placesProvider);
    final ratingOf = ref.watch(ratingOfProvider);
    final recommender = ref.watch(recommenderProvider);
    final gems = recommender.hiddenGems(places, ratingOf);
    final topRated = [...places]..sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    final byId = ref.watch(placeByIdProvider);

    // "Because you liked X": the user's highest-rated review drives it.
    final myReviews = ref.watch(myReviewsProvider).value ?? const [];
    final liked = ([
      ...myReviews,
    ]..sort((a, b) => b.rating.compareTo(a.rating))).where((r) => r.rating >= 4).map((r) => byId[r.placeId]).whereType<Place>().firstOrNull;
    final visited = (profile?.visitedPlaceIds ?? const []).toSet();
    final similar = liked == null ? const <Place>[] : recommender.similarTo(liked, places, exclude: visited);

    final pos = ref.watch(positionProvider).value;
    final nearby = pos == null
        ? const <(Place, double)>[]
        : ([
            for (final p in places) (p, Geo.distanceKm(pos.latitude, pos.longitude, p.lat, p.lng)),
          ]..sort((a, b) => a.$2.compareTo(b.$2))).take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dataSyncProvider).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Fmt.greeting()}, ${profile?.firstName ?? 'traveller'} 👋',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Where are you going next?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Travel assistance (SOS)',
                      onPressed: () => context.push('/sos'),
                      icon: const Icon(Icons.sos_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.go('/explore'),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade700),
                        const SizedBox(width: 12),
                        Text('Search destinations, cities, experiences', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
              SectionHeader(
                title: 'Recommended for you',
                subtitle: 'Based on your interests and reviews',
                actionLabel: 'See all',
                onAction: () => context.go('/explore'),
              ),
              _Carousel(
                children: [for (final r in recs) PlaceCard(place: r.place, caption: r.reason)],
              ),
              if (liked != null && similar.isNotEmpty) ...[
                SectionHeader(title: 'Because you liked ${liked.name}', subtitle: 'More ${liked.category.label.toLowerCase()} places'),
                _Carousel(children: [for (final p in similar) PlaceCard(place: p)]),
              ],
              SectionHeader(
                title: 'Near you',
                subtitle: pos == null ? 'Turn on location to see places around you' : 'Closest places to your location',
                actionLabel: 'Open map',
                onAction: () => context.go('/map'),
              ),
              if (pos == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(positionProvider.notifier).locate();
                      final err = ref.read(positionProvider).error;
                      if (err != null && context.mounted) showSnack(context, err.toString(), error: true);
                    },
                    icon: ref.watch(positionProvider).isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text('Use my location'),
                  ),
                )
              else
                _Carousel(
                  children: [for (final n in nearby) PlaceCard(place: n.$1, caption: '${Geo.format(n.$2)} away')],
                ),
              const SectionHeader(title: 'Hidden gems', subtitle: 'Highly rated, rarely crowded'),
              _Carousel(children: [for (final p in gems) PlaceCard(place: p)]),
              const SectionHeader(title: 'Community favourites', subtitle: 'Top rated by travellers'),
              _Carousel(children: [for (final p in topRated.take(8)) PlaceCard(place: p)]),
              const SectionHeader(title: 'From the community', subtitle: 'Latest reviews by TravelVerse travellers'),
              const _CommunityFeed(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Nothing here yet.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _CommunityFeed extends ConsumerWidget {
  const _CommunityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(communityFeedProvider);
    final byId = ref.watch(placeByIdProvider);
    return feed.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Community feed is unavailable offline.', style: TextStyle(color: Colors.grey.shade600)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No reviews yet. Visit a place and be the first to review it!', style: TextStyle(color: Colors.grey.shade600)),
          );
        }
        return Column(
          children: [
            for (final r in reviews)
              if (byId[r.placeId] != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => context.push('/place/${r.placeId}'),
                      leading: CircleAvatar(child: Text(r.userName.isEmpty ? '?' : r.userName[0].toUpperCase())),
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: r.userName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' reviewed '),
                            TextSpan(
                              text: byId[r.placeId]!.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              RatingStars(rating: r.rating, size: 14),
                              const SizedBox(width: 6),
                              Text(Fmt.timeAgo(r.createdAt), style: const TextStyle(fontSize: 12)),
                              if (r.verifiedVisit) ...[const SizedBox(width: 6), const Icon(Icons.verified, size: 14, color: Colors.teal)],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(r.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
