import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/geo.dart';
import '../../data/models/place.dart';
import '../../data/models/review.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/place_cards.dart';
import '../../shared/widgets/place_image.dart';
import '../../shared/widgets/rating.dart';
import '../trips/add_to_trip_sheet.dart';

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  /// Opens turn-by-turn directions in the phone's maps app (implicit intent).
  Future<void> _directions(BuildContext context, Place p) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'No maps app found on this device.', error: true);
  }

  Future<void> _toggleVisited(BuildContext context, WidgetRef ref, Place p, bool visited) async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    if (visited) {
      final ok = await confirmDialog(
        context,
        title: 'Remove from visited?',
        message: 'Your review of ${p.name} will no longer show the Verified Visit badge.',
        confirmLabel: 'Remove',
      );
      if (!ok) return;
    }
    try {
      final now = await ref.read(userRepositoryProvider).toggleVisited(uid, p.id, visited);
      showToast(now ? 'Marked ${p.name} as visited ✓' : 'Removed from visited');
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not update. Check your connection.', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeByIdProvider)[placeId];
    if (place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.location_off, title: 'Place not found', message: 'This place may have been removed.'),
      );
    }
    final stats = ref.watch(placeStatsProvider).value?[place.id] ?? const PlaceStats();
    final rating = stats.ratingFor(place);
    final profile = ref.watch(profileProvider).value;
    final visited = profile?.visitedPlaceIds.contains(place.id) ?? false;
    final reviews = ref.watch(placeReviewsProvider(place.id));
    final uid = ref.watch(uidProvider);
    final myReview = reviews.value?.where((r) => r.userId == uid).firstOrNull;
    final pos = ref.watch(positionProvider).value;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.white,
            actions: [
              SaveIconButton(place: place),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${place.name}, ${place.location} — rated ${Fmt.rating(rating)}★ on TouchGrass.\n'
                        'https://www.openstreetmap.org/?mlat=${place.lat}&mlon=${place.lng}#map=15/${place.lat}/${place.lng}',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: PlaceImage(place: place, radius: 0)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(place.location, style: TextStyle(color: Colors.grey.shade700)),
                      if (pos != null) ...[
                        Text('  ·  ', style: TextStyle(color: Colors.grey.shade500)),
                        Text(
                          '${Geo.format(Geo.distanceKm(pos.latitude, pos.longitude, place.lat, place.lng))} away',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TagChip(label: place.category.label, icon: place.category.icon, color: place.category.color),
                      TagChip(label: place.budgetLabel, color: Colors.green.shade700),
                      for (final f in place.idealFor) TagChip(label: f[0].toUpperCase() + f.substring(1), color: Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RatingSummary(place: place, stats: stats, rating: rating),
                  const SizedBox(height: 16),
                  _ActionRow(
                    visited: visited,
                    onVisited: () => _toggleVisited(context, ref, place, visited),
                    onAddToTrip: () => showAddToTripSheet(context, ref, place),
                    onDirections: () => _directions(context, place),
                    onReview: () => context.push('/place/${place.id}/review'),
                    hasReview: myReview != null,
                  ),
                  const SizedBox(height: 24),
                  Text('About', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(place.description, style: const TextStyle(height: 1.45)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text('Best time to visit: ', style: TextStyle(color: Colors.grey.shade700)),
                      Expanded(
                        child: Text(place.bestTime, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Traveller reviews', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/place/${place.id}/review'),
                        icon: Icon(myReview == null ? Icons.rate_review_outlined : Icons.edit_outlined),
                        label: Text(myReview == null ? 'Write a review' : 'Edit my review'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          reviews.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Reviews are unavailable offline.', style: TextStyle(color: Colors.grey.shade600)),
              ),
            ),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Text(
                        'No app reviews yet. Be the first to share your experience!',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ReviewCard(review: list[i]),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.place, required this.stats, required this.rating});

  final Place place;
  final PlaceStats stats;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final rec = stats.recommendPercent;
    Widget bar(String label, double? v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: v == null ? 0 : v / 5, minHeight: 7, backgroundColor: Colors.grey.shade200),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(v == null ? '–' : v.toStringAsFixed(1), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Text(Fmt.rating(rating), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    RatingStars(rating: rating),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.compact(stats.totalReviewsFor(place))} ratings',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      bar('Value', stats.average(stats.valueSum)),
                      bar('Cleanliness', stats.average(stats.cleanlinessSum)),
                      bar('Accessibility', stats.average(stats.accessibilitySum)),
                    ],
                  ),
                ),
              ],
            ),
            if (rec != null || stats.visitedCount > 0 || stats.savedCount > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (rec != null) _Stat(icon: Icons.thumb_up_alt_outlined, value: '$rec%', label: 'recommend'),
                  _Stat(icon: Icons.check_circle_outline, value: '${stats.visitedCount}', label: 'visited'),
                  _Stat(icon: Icons.favorite_border, value: '${stats.savedCount}', label: 'want to go'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    ],
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.visited,
    required this.onVisited,
    required this.onAddToTrip,
    required this.onDirections,
    required this.onReview,
    required this.hasReview,
  });

  final bool visited;
  final bool hasReview;
  final VoidCallback onVisited;
  final VoidCallback onAddToTrip;
  final VoidCallback onDirections;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget action(IconData icon, String label, VoidCallback onTap, {bool active = false}) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: active ? scheme.primary : scheme.primaryContainer,
                child: Icon(icon, color: active ? Colors.white : scheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        action(visited ? Icons.check_circle : Icons.check_circle_outline, visited ? 'Visited' : 'Mark visited', onVisited, active: visited),
        action(Icons.playlist_add, 'Add to trip', onAddToTrip),
        action(Icons.directions, 'Directions', onDirections),
        action(hasReview ? Icons.edit_note : Icons.rate_review_outlined, hasReview ? 'Edit review' : 'Review', onReview, active: hasReview),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.showPlace});

  final Review review;
  final String? showPlace;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, child: Text(review.userName.isEmpty ? '?' : review.userName[0].toUpperCase())),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              showPlace ?? review.userName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.verifiedVisit) ...[
                            const SizedBox(width: 6),
                            const TagChip(label: 'Verified visit', icon: Icons.verified, color: Colors.teal),
                          ],
                        ],
                      ),
                      Text(Fmt.timeAgo(review.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating, size: 15),
              ],
            ),
            const SizedBox(height: 10),
            Text(review.text, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                TagChip(
                  label: review.recommend ? 'Recommends' : 'Does not recommend',
                  icon: review.recommend ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                  color: review.recommend ? Colors.green.shade700 : Colors.red.shade700,
                ),
                if (review.bestTime.isNotEmpty) TagChip(label: 'Best: ${review.bestTime}', icon: Icons.schedule, color: Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
