import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/models/trip.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';

const tripTypes = ['Leisure', 'Adventure', 'Pilgrimage', 'Business', 'Backpacking', 'Honeymoon'];

/// Create or edit a trip: name, destination, start/end date pickers,
/// travellers, budget, trip type (spinner) and notes.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.tripId});

  final String? tripId;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> with SubmitValidation<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _destination = TextEditingController();
  final _travellers = TextEditingController(text: '2');
  final _budget = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String _type = tripTypes.first;
  String? _dateError;
  bool _loading = false;
  Trip? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) _load();
  }

  Future<void> _load() async {
    final t = await ref.read(tripRepositoryProvider).trip(widget.tripId!);
    if (t == null || !mounted) return;
    setState(() {
      _existing = t;
      _name.text = t.name;
      _destination.text = t.destination;
      _travellers.text = '${t.travellers}';
      _budget.text = '${t.budget}';
      _notes.text = t.notes;
      _start = t.startDate;
      _end = t.endDate;
      _type = tripTypes.contains(t.tripType) ? t.tripType : tripTypes.first;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _destination, _travellers, _budget, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = start ? (_start ?? today) : (_end ?? _start ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: start ? today : (_start ?? today),
      lastDate: today.add(const Duration(days: 730)),
      helpText: start ? 'Trip starts on' : 'Trip ends on',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
      _dateError = null;
    });
  }

  Future<void> _save() async {
    final valid = validateForm(_formKey);
    // Past dates are allowed only when editing a trip that has already begun.
    final dateErr = _existing != null && _start == _existing!.startDate
        ? (_end == null ? 'Select an end date' : (_end!.isBefore(_start!) ? 'End date must be on or after the start date' : null))
        : Validators.tripDates(_start, _end);
    setState(() => _dateError = dateErr);
    if (!valid || dateErr != null) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(tripRepositoryProvider);
      var trip = Trip(
        id: _existing?.id ?? repo.newId(),
        userId: uid,
        name: _name.text.trim(),
        destination: _destination.text.trim(),
        startDate: _start!,
        endDate: _end!,
        travellers: int.parse(_travellers.text.trim()),
        budget: int.parse(_budget.text.trim()),
        tripType: _type,
        notes: _notes.text.trim(),
        items: _existing?.items ?? const [],
      );
      trip = repo.clampItems(trip);
      await repo.saveTrip(trip);
      await ref.read(dataSyncProvider).refresh();
      showToast(_existing == null ? 'Trip created' : 'Trip updated');
      if (!mounted) return;
      if (_existing == null) {
        context.pushReplacement('/trips/${trip.id}');
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.tripId != null;
    final days = _start != null && _end != null && !_end!.isBefore(_start!) ? _end!.difference(_start!).inDays + 1 : null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit trip' : 'Plan a new trip')),
      body: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('trip_name'),
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Trip name',
                  hintText: 'e.g. Manali Winter Trip',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (v) => Validators.text(v, 'Trip name', min: 3, max: 50),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('trip_destination'),
                controller: _destination,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g. Himachal Pradesh',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) => Validators.text(v, 'Destination', min: 2, max: 50),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start date',
                      value: _start,
                      onTap: () => _pickDate(start: true),
                      fieldKey: const Key('trip_start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'End date',
                      value: _end,
                      onTap: () => _pickDate(start: false),
                      fieldKey: const Key('trip_end'),
                    ),
                  ),
                ],
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(_dateError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                )
              else if (days != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('$days day${days == 1 ? '' : 's'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('trip_travellers'),
                      controller: _travellers,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Travellers', hintText: '1-20', prefixIcon: Icon(Icons.group_outlined)),
                      validator: (v) => Validators.intInRange(v, 'Travellers', min: 1, max: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('trip_budget'),
                      controller: _budget,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Budget (₹)',
                        hintText: 'e.g. 25000',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (v) => Validators.intInRange(v, 'Budget', min: 500, max: 10000000),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Trip type', prefixIcon: Icon(Icons.category_outlined)),
                items: [for (final t in tripTypes) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => _type = v ?? tripTypes.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Packing list, bookings, reminders...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.optionalText(v, 'Notes', max: 300),
              ),
              const SizedBox(height: 20),
              LoadingButton(
                key: const Key('trip_save'),
                label: editing ? 'Save changes' : 'Create trip',
                loading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.fieldKey});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => InkWell(
    key: fieldKey,
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.event)),
      child: Text(value == null ? 'Select date' : Fmt.date(value!), style: TextStyle(color: value == null ? Colors.grey.shade500 : null)),
    ),
  );
}
