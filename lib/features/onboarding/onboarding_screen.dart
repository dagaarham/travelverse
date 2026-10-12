import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../data/models/place.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';

const travelStyles = {
  'solo': ('Solo', Icons.person),
  'couple': ('Couple', Icons.favorite),
  'family': ('Family', Icons.family_restroom),
  'friends': ('Friends', Icons.groups),
};

/// Interests (checkboxes) and travel style (radio buttons). Shown once after
/// sign-up and reused from the profile menu to edit preferences.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _city = TextEditingController();
  final Set<String> _interests = {};
  String? _style;
  bool _loading = false;
  String? _interestError;
  String? _styleError;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).value;
    if (p != null) {
      _interests.addAll(p.interests);
      _style = p.travelStyle.isEmpty ? null : p.travelStyle;
      _city.text = p.homeCity;
    }
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() {
      _interestError = _interests.length < 2 ? 'Pick at least 2 interests so we can personalise suggestions' : null;
      _styleError = _style == null ? 'Choose how you usually travel' : null;
    });
    if (!valid || _interestError != null || _styleError != null) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .completeOnboarding(uid, interests: _interests.toList(), travelStyle: _style!, homeCity: _city.text);
      if (widget.editing && mounted) {
        showToast('Preferences updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.editing ? 'Travel preferences' : 'Personalise TravelVerse')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.editing)
                Text('Tell us what you enjoy and we will recommend places you will love.', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              Text('What are you interested in?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final c in PlaceCategory.values)
                      CheckboxListTile(
                        key: Key('interest_${c.name}'),
                        value: _interests.contains(c.name),
                        secondary: Icon(c.icon, color: c.color),
                        title: Text(c.label),
                        onChanged: (v) => setState(() {
                          v == true ? _interests.add(c.name) : _interests.remove(c.name);
                          _interestError = null;
                        }),
                      ),
                  ],
                ),
              ),
              if (_interestError != null) _ErrorLine(_interestError!),
              const SizedBox(height: 24),
              Text('How do you usually travel?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: RadioGroup<String>(
                  groupValue: _style,
                  onChanged: (v) => setState(() {
                    _style = v;
                    _styleError = null;
                  }),
                  child: Column(
                    children: [
                      for (final e in travelStyles.entries)
                        RadioListTile<String>(
                          key: Key('style_${e.key}'),
                          value: e.key,
                          title: Text(e.value.$1),
                          secondary: Icon(e.value.$2),
                        ),
                    ],
                  ),
                ),
              ),
              if (_styleError != null) _ErrorLine(_styleError!),
              const SizedBox(height: 24),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Home city', hintText: 'e.g. Mumbai', prefixIcon: Icon(Icons.home_outlined)),
                validator: (v) => Validators.text(v, 'Home city', min: 2, max: 40),
              ),
              const SizedBox(height: 28),
              LoadingButton(label: widget.editing ? 'Save preferences' : 'Start exploring', loading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
  );
}
