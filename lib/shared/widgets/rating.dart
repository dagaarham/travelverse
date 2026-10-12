import 'package:flutter/material.dart';

/// Read-only star row.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16, this.color});

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFFFB300);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = rating - i;
        final icon = v >= 0.75 ? Icons.star_rounded : (v >= 0.25 ? Icons.star_half_rounded : Icons.star_outline_rounded);
        return Icon(icon, size: size, color: c);
      }),
    );
  }
}

/// Compact "★ 4.7" badge.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.light = false});

  final double rating;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.92) : const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFA000)),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

/// Interactive star input. Uses a touch listener so the user can tap a star
/// or drag a finger across the row to set the rating.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.value, required this.onChanged, this.size = 36, this.errorText});

  final double value;
  final ValueChanged<double> onChanged;
  final double size;
  final String? errorText;

  void _fromDx(double dx) {
    final v = (dx / size).ceil().clamp(1, 5).toDouble();
    if (v != value) onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _fromDx(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => _fromDx(d.localPosition.dx),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: const Color(0xFFFFB300),
                semanticLabel: '${i + 1} star',
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
