import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../data/models/review.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/rating.dart';

const bestTimeOptions = ['Early morning', 'Morning', 'Afternoon', 'Sunset', 'Evening', 'Night', 'Any time'];

/// Structured review: overall + three sub-ratings, written review,
/// best time (spinner) and "would you recommend" (radio buttons).
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  double _overall = 0, _value = 0, _clean = 0, _access = 0;
  bool? _recommend;
  String? _bestTime;
  bool _submitted = false;
  bool _loading = false;
  Review? _existing;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(uidProvider);
    _existing = ref.read(placeReviewsProvider(widget.placeId)).value?.where((r) => r.userId == uid).firstOrNull;
    final e = _existing;
    if (e != null) {
      _overall = e.rating;
      _value = e.valueRating;
      _clean = e.cleanlinessRating;
      _access = e.accessibilityRating;
      _recommend = e.recommend;
      _bestTime = bestTimeOptions.contains(e.bestTime) ? e.bestTime : null;
      _text.text = e.text;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ratingsValid =>
      Validators.rating(_overall, 'overall') == null &&
      Validators.rating(_value, 'value') == null &&
      Validators.rating(_clean, 'cleanliness') == null &&
      Validators.rating(_access, 'accessibility') == null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || !_ratingsValid || _recommend == null) {
      showSnack(context, 'Please complete the highlighted fields', error: true);
      return;
    }
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(placeRepositoryProvider)
          .submitReview(
            Review(
              placeId: widget.placeId,
              userId: profile.uid,
              userName: profile.name,
              rating: _overall,
              valueRating: _value,
              cleanlinessRating: _clean,
              accessibilityRating: _access,
              text: _text.text.trim(),
              recommend: _recommend!,
              bestTime: _bestTime ?? '',
              verifiedVisit: profile.visitedPlaceIds.contains(widget.placeId),
              createdAt: DateTime.now(),
            ),
          );
      showToast(_existing == null ? 'Review posted. Thanks for helping other travellers!' : 'Review updated');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final e = _existing;
    if (e == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Delete review?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(placeRepositoryProvider).deleteReview(e);
      showToast('Review deleted');
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (mounted) showSnack(context, friendlyError(err), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(placeByIdProvider)[widget.placeId];
    final visited = ref.watch(profileProvider).value?.visitedPlaceIds.contains(widget.placeId) ?? false;
    final t = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    String? err(double v, String f) => _submitted ? Validators.rating(v, f) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Write a review' : 'Edit review'),
        actions: [if (_existing != null) IconButton(tooltip: 'Delete review', onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(place?.name ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (visited)
                const TagChip(label: 'Your review will carry a Verified Visit badge', icon: Icons.verified, color: Colors.teal)
              else
                Text(
                  'Tip: mark the place as visited first to earn a Verified Visit badge.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              const SizedBox(height: 20),
              Text('Overall experience', style: t),
              const SizedBox(height: 4),
              StarRatingInput(
                key: const Key('review_overall'),
                value: _overall,
                size: 44,
                onChanged: (v) => setState(() => _overall = v),
                errorText: err(_overall, 'your overall experience'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _SubRating(
                        label: 'Value for money',
                        value: _value,
                        onChanged: (v) => setState(() => _value = v),
                        error: err(_value, 'value for money'),
                      ),
                      _SubRating(
                        label: 'Cleanliness',
                        value: _clean,
                        onChanged: (v) => setState(() => _clean = v),
                        error: err(_clean, 'cleanliness'),
                      ),
                      _SubRating(
                        label: 'Accessibility',
                        value: _access,
                        onChanged: (v) => setState(() => _access = v),
                        error: err(_access, 'accessibility'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('review_text'),
                controller: _text,
                minLines: 4,
                maxLines: 8,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your review',
                  hintText: 'What was it like? Tips for other travellers (min 20 characters)',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.text(v, 'Review', min: 20, max: 500),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bestTime,
                decoration: const InputDecoration(labelText: 'Best time to visit (optional)', prefixIcon: Icon(Icons.schedule)),
                hint: const Text('Select a time of day'),
                items: [for (final o in bestTimeOptions) DropdownMenuItem(value: o, child: Text(o))],
                onChanged: (v) => setState(() => _bestTime = v),
              ),
              const SizedBox(height: 20),
              Text('Would you recommend this place?', style: t),
              RadioGroup<bool>(
                groupValue: _recommend,
                onChanged: (v) => setState(() => _recommend = v),
                child: const Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        key: Key('recommend_yes'),
                        value: true,
                        title: Text('👍 Yes'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        key: Key('recommend_no'),
                        value: false,
                        title: Text('👎 No'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              if (_submitted && _recommend == null)
                Text('Please choose Yes or No', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              const SizedBox(height: 24),
              LoadingButton(
                key: const Key('review_submit'),
                label: _existing == null ? 'Post review' : 'Update review',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubRating extends StatelessWidget {
  const _SubRating({required this.label, required this.value, required this.onChanged, this.error});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(label)),
        ),
        StarRatingInput(value: value, onChanged: onChanged, size: 28, errorText: error == null ? null : 'Required'),
      ],
    ),
  );
}
