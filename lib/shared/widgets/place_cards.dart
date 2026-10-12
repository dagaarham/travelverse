import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import 'common.dart';
import 'place_image.dart';
import 'rating.dart';

/// Large card used in horizontal carousels. Long-press toggles "Want to
/// visit" (touch listener) and a tap opens the place page.
class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place, this.width = 220, this.height = 250, this.caption});

  final Place place;
  final double width;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(ratingOfProvider)(place);
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => context.push('/place/${place.id}'),
        onLongPress: () => toggleSave(context, ref, place),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PlaceImage(place: place, height: height * 0.58, width: width, radius: 0),
                  Positioned(top: 10, left: 10, child: RatingBadge(rating: rating, light: true)),
                  Positioned(top: 4, right: 4, child: SaveIconButton(place: place, light: true)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        place.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: caption == null
                    ? TagChip(label: place.category.label, icon: place.category.icon, color: place.category.color)
                    : Text(
                        caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row-style card for lists (explore results, saved places...).
class PlaceTile extends ConsumerWidget {
  const PlaceTile({super.key, required this.place, this.distanceKm, this.trailing, this.onTap});

  final Place place;
  final double? distanceKm;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(ratingOfProvider)(place);
    final reviews = (ref.watch(placeStatsProvider).value?[place.id] ?? const PlaceStats()).totalReviewsFor(place);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/place/${place.id}'),
        onLongPress: () => toggleSave(context, ref, place),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlaceImage(place: place, width: 88, height: 88, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingStars(rating: rating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} (${reviews >= 1000 ? '${(reviews / 1000).toStringAsFixed(1)}k' : reviews})',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TagChip(label: place.category.label, icon: place.category.icon, color: place.category.color),
                        TagChip(label: place.budgetLabel, color: Colors.green.shade700),
                        if (distanceKm != null) TagChip(label: Geo.format(distanceKm!), icon: Icons.near_me, color: Colors.blueGrey),
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Heart button reflecting whether the place is on the user's wish list.
class SaveIconButton extends ConsumerWidget {
  const SaveIconButton({super.key, required this.place, this.light = false});

  final Place place;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(profileProvider).value?.savedPlaceIds.contains(place.id) ?? false;
    final button = IconButton(
      tooltip: saved ? 'Remove from Want to visit' : 'Save to Want to visit',
      onPressed: () => toggleSave(context, ref, place),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? Colors.redAccent : (light ? Colors.white : null)),
    );
    if (!light) return button;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
      child: button,
    );
  }
}

Future<void> toggleSave(BuildContext context, WidgetRef ref, Place place) async {
  final profile = ref.read(profileProvider).value;
  if (profile == null) return;
  final saved = profile.savedPlaceIds.contains(place.id);
  try {
    final nowSaved = await ref.read(userRepositoryProvider).toggleSaved(profile.uid, place.id, saved);
    showToast(nowSaved ? '${place.name} saved to Want to visit' : 'Removed from Want to visit');
  } catch (_) {
    if (context.mounted) showSnack(context, 'Could not update your list. Check your connection.', error: true);
  }
}
