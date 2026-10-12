import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/place.dart';
import '../../providers.dart';

/// Photo of a place loaded from Wikipedia, with category artwork as the
/// placeholder and offline fallback.
class PlaceImage extends ConsumerStatefulWidget {
  const PlaceImage({super.key, required this.place, this.height, this.width, this.radius = 16});

  final Place place;
  final double? height;
  final double? width;
  final double radius;

  @override
  ConsumerState<PlaceImage> createState() => _PlaceImageState();
}

class _PlaceImageState extends ConsumerState<PlaceImage> {
  late Future<String?> _url;

  @override
  void initState() {
    super.initState();
    _url = ref.read(wikiServiceProvider).imageUrl(widget.place.wikiTitle);
  }

  @override
  void didUpdateWidget(PlaceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id) {
      _url = ref.read(wikiServiceProvider).imageUrl(widget.place.wikiTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = CategoryArt(category: widget.place.category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: FutureBuilder<String?>(
          future: _url,
          builder: (context, snap) {
            final url = snap.data;
            if (url == null) return art;
            return Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : art,
              errorBuilder: (context, error, stack) => art,
            );
          },
        ),
      ),
    );
  }
}

/// Gradient tile with the category icon.
class CategoryArt extends StatelessWidget {
  const CategoryArt({super.key, required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.color.withValues(alpha: 0.85), category.color.withValues(alpha: 0.45)],
        ),
      ),
      child: Center(child: Icon(category.icon, color: Colors.white.withValues(alpha: 0.9), size: 40)),
    );
  }
}
