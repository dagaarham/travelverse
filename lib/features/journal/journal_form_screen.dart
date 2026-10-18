import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_exception.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/models/journal_entry.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/local_photo.dart';
import '../../shared/widgets/rating.dart';

/// Create / edit a journal entry with a photo from the camera or gallery.
class JournalFormScreen extends ConsumerStatefulWidget {
  const JournalFormScreen({super.key, this.entryId, this.tripId});

  final String? entryId;
  final String? tripId;

  @override
  ConsumerState<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends ConsumerState<JournalFormScreen> with SubmitValidation<JournalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  DateTime _date = DateTime.now();
  double _mood = 0;
  String? _placeId;
  String? _tripId;
  String? _photoPath;
  bool _submitted = false;
  bool _loading = false;
  JournalEntry? _existing;

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
    if (widget.entryId != null) _load();
  }

  Future<void> _load() async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final all = await ref.read(tripRepositoryProvider).journal(uid);
    final e = all.where((x) => x.id == widget.entryId).firstOrNull;
    if (e == null || !mounted) return;
    setState(() {
      _existing = e;
      _title.text = e.title;
      _body.text = e.body;
      _date = e.date;
      _mood = e.mood.toDouble();
      _placeId = e.placeId;
      _tripId = e.tripId;
      _photoPath = e.photoPath;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Picks an image and copies it into the app's private folder so it
  /// survives the gallery/camera cache being cleared.
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      if (kIsWeb) {
        setState(() => _photoPath = file.path);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'journal_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}');
      await file.saveTo(dest);
      setState(() => _photoPath = dest);
    } catch (e) {
      if (mounted) {
        showSnack(
          context,
          source == ImageSource.camera ? 'Camera unavailable or permission denied.' : 'Could not open the gallery.',
          error: true,
        );
      }
    }
  }

  void _photoOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: 'Date of this memory',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final valid = validateForm(_formKey);
    if (!valid || _mood < 1) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .saveJournal(
            JournalEntry(
              id: _existing?.id ?? ref.read(tripRepositoryProvider).newId(),
              userId: uid,
              title: _title.text.trim(),
              body: _body.text.trim(),
              date: _date,
              mood: _mood.round(),
              tripId: _tripId,
              placeId: _placeId,
              photoPath: _photoPath,
            ),
          );
      await ref.read(dataSyncProvider).refresh();
      showToast(_existing == null ? 'Memory saved to your journal' : 'Entry updated');
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
      title: 'Delete this entry?',
      message: 'The text and photo will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(tripRepositoryProvider).deleteJournal(e);
    await ref.read(dataSyncProvider).refresh();
    showToast('Entry deleted');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final places = [...ref.watch(placesProvider)]..sort((a, b) => a.name.compareTo(b.name));
    final trips = ref.watch(tripsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New journal entry' : 'Edit entry'),
        actions: [if (_existing != null) IconButton(tooltip: 'Delete entry', onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _photoOptions,
                borderRadius: BorderRadius.circular(16),
                child: _photoPath == null
                    ? Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('Add a photo (camera or gallery)'),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          LocalPhoto(path: _photoPath!, height: 220, width: double.infinity, radius: 16),
                          const Positioned(
                            right: 10,
                            top: 10,
                            child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.edit)),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('journal_title'),
                controller: _title,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Sunrise at the Taj'),
                validator: (v) => Validators.text(v, 'Title', min: 3, max: 60),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.event)),
                  child: Text(Fmt.date(_date)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _placeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Place (optional)', prefixIcon: Icon(Icons.place_outlined)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('No specific place')),
                  for (final pl in places)
                    DropdownMenuItem<String?>(
                      value: pl.id,
                      child: Text('${pl.name}, ${pl.city}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _placeId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: trips.any((t) => t.id == _tripId) ? _tripId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Trip (optional)', prefixIcon: Icon(Icons.luggage_outlined)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Not part of a trip')),
                  for (final t in trips)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _tripId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('journal_body'),
                controller: _body,
                minLines: 5,
                maxLines: 12,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your story',
                  hintText: 'What happened? How did it feel? (min 10 characters)',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.text(v, 'Story', min: 10, max: 2000),
              ),
              const SizedBox(height: 8),
              Text('How was the experience?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              StarRatingInput(
                value: _mood,
                onChanged: (v) => setState(() => _mood = v),
                errorText: _submitted && _mood < 1 ? 'Please rate the experience' : null,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                key: const Key('journal_save'),
                label: _existing == null ? 'Save entry' : 'Save changes',
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
