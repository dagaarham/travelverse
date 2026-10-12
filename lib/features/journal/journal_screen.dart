import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../core/export_builder.dart';
import '../../core/formatters.dart';
import '../../data/models/journal_entry.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/local_photo.dart';

/// Timeline of journal entries (all, or for one trip) with .txt export.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, this.tripId});

  final String? tripId;

  Future<void> _export(BuildContext context, WidgetRef ref, String title, List<JournalEntry> entries) async {
    if (entries.isEmpty) {
      showSnack(context, 'Add at least one entry before exporting', error: true);
      return;
    }
    try {
      await ref
          .read(exportServiceProvider)
          .saveAndShare(
            fileName: ExportBuilder.fileName(title, 'txt'),
            content: ExportBuilder.journalTxt(title, entries, ref.read(placeByIdProvider)),
            mimeType: 'text/plain',
          );
    } catch (e) {
      if (context.mounted) showSnack(context, 'Export failed: ${friendlyError(e)}', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider(tripId));
    final trip = tripId == null ? null : ref.watch(tripProvider(tripId!)).value;
    final title = trip == null ? 'My travel journal' : '${trip.name} journal';
    final byId = ref.watch(placeByIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Export journal (.txt)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _export(context, ref, title, entries.value ?? const []),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_journal_fab'),
        onPressed: () => context.push(tripId == null ? '/journal/new' : '/journal/new?tripId=$tripId'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('New entry'),
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(journalProvider)),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Your journal is empty',
                message: 'Capture moments from your trips with a photo and a few words. Entries are saved on your phone.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  final place = e.placeId == null ? null : byId[e.placeId];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline rail
                        SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              Container(width: 2, height: 18, color: i == 0 ? Colors.transparent : Colors.grey.shade300),
                              CircleAvatar(radius: 7, backgroundColor: Theme.of(context).colorScheme.primary),
                              Expanded(child: Container(width: 2, color: i == list.length - 1 ? Colors.transparent : Colors.grey.shade300)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => context.push('/journal/${e.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (e.photoPath != null) LocalPhoto(path: e.photoPath!, height: 170, width: double.infinity, radius: 0),
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Fmt.date(e.date),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                          if (place != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text('📍 ${place.name}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(e.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
                                          const SizedBox(height: 6),
                                          Text('${'★' * e.mood}${'☆' * (5 - e.mood)}', style: const TextStyle(color: Color(0xFFFFA000))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
