import 'package:flutter/material.dart';

import '../../data/models/place.dart';

/// Photo of a place, bundled with the app (`assets/places/<id>.jpg`) so it
/// shows instantly and offline. Category artwork is the fallback.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.place, this.height, this.width, this.radius = 16});

  final Place place;
  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width,
        child: Image.asset(
          place.photoAsset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => CategoryArt(category: place.category),
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
