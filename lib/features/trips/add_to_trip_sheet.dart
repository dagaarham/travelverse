import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';

/// Bottom sheet: pick a trip, a day and an optional note, then add the place.
Future<void> showAddToTripSheet(BuildContext context, WidgetRef ref, Place place) async {
  final trips = await ref.read(tripsProvider.future);
  if (!context.mounted) return;
  final today = DateTime.now();
  final open = trips.where((t) => !t.endDate.isBefore(DateTime(today.year, today.month, today.day))).toList();
  if (open.isEmpty) {
    final create = await confirmDialog(
      context,
      title: 'No upcoming trips',
      message: 'Create a trip first, then add ${place.name} to it.',
      confirmLabel: 'Create trip',
    );
    if (create && context.mounted) context.push('/trips/new');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddToTripForm(place: place, trips: open),
    ),
  );
}

class _AddToTripForm extends ConsumerStatefulWidget {
  const _AddToTripForm({required this.place, required this.trips});

  final Place place;
  final List<Trip> trips;

  @override
  ConsumerState<_AddToTripForm> createState() => _AddToTripFormState();
}

class _AddToTripFormState extends ConsumerState<_AddToTripForm> with SubmitValidation<_AddToTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late Trip _trip = widget.trips.first;
  int _day = 1;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!validateForm(_formKey)) return;
    if (_trip.items.any((i) => i.placeId == widget.place.id && i.day == _day)) {
      showSnack(context, '${widget.place.name} is already on Day $_day', error: true);
      return;
    }
    setState(() => _saving = true);
    await ref.read(tripRepositoryProvider).addPlace(_trip, placeId: widget.place.id, day: _day, note: _note.text);
    await ref.read(dataSyncProvider).refresh();
    showToast('Added to ${_trip.name}, Day $_day');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add ${widget.place.name} to a trip',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Trip>(
                initialValue: _trip,
                decoration: const InputDecoration(labelText: 'Trip', prefixIcon: Icon(Icons.luggage_outlined)),
                items: [
                  for (final t in widget.trips)
                    DropdownMenuItem(
                      value: t,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (t) => setState(() {
                  _trip = t!;
                  _day = 1;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(_trip.id),
                initialValue: _day,
                decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.today_outlined)),
                items: [
                  for (var d = 1; d <= _trip.dayCount; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text('Day $d · ${Fmt.date(_trip.startDate.add(Duration(days: d - 1)))}'),
                    ),
                ],
                onChanged: (d) => setState(() => _day = d ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Reach before 7 AM'),
                validator: (v) => Validators.optionalText(v, 'Note', max: 100),
              ),
              const SizedBox(height: 8),
              LoadingButton(label: 'Add to trip', loading: _saving, onPressed: _add),
            ],
          ),
        ),
      ),
    );
  }
}
