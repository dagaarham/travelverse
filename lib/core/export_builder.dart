import 'package:csv/csv.dart';

import '../data/models/journal_entry.dart';
import '../data/models/place.dart';
import '../data/models/trip.dart';
import 'formatters.dart';

/// Builds the text of exported files. Kept free of I/O so it can be unit
/// tested; [ExportService] writes the result to disk and shares it.
class ExportBuilder {
  ExportBuilder._();

  static const csvHeader = ['Day', 'Date', 'Order', 'Place', 'City', 'Category', 'Latitude', 'Longitude', 'Note'];

  static String tripCsv(Trip trip, Map<String, Place> places) {
    final rows = <List<Object>>[csvHeader];
    for (var day = 1; day <= trip.dayCount; day++) {
      final date = trip.startDate.add(Duration(days: day - 1));
      final items = trip.itemsForDay(day);
      for (var i = 0; i < items.length; i++) {
        final p = places[items[i].placeId];
        rows.add([
          day,
          Fmt.date(date),
          i + 1,
          p?.name ?? items[i].placeId,
          p?.city ?? '',
          p?.category.label ?? '',
          p?.lat ?? '',
          p?.lng ?? '',
          items[i].note,
        ]);
      }
    }
    return Csv(lineDelimiter: '\n').encode(rows);
  }

  static String journalTxt(String title, List<JournalEntry> entries, Map<String, Place> places) {
    final b = StringBuffer()
      ..writeln(title.toUpperCase())
      ..writeln('=' * title.length)
      ..writeln('Exported from TouchGrass on ${Fmt.date(DateTime.now())}')
      ..writeln();
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      b.writeln('${Fmt.date(e.date)} — ${e.title}');
      if (e.placeId != null && places[e.placeId] != null) {
        b.writeln('Place: ${places[e.placeId]!.name}, ${places[e.placeId]!.city}');
      }
      b
        ..writeln('Experience: ${'★' * e.mood}${'☆' * (5 - e.mood)}')
        ..writeln()
        ..writeln(e.body)
        ..writeln()
        ..writeln('-' * 40)
        ..writeln();
    }
    if (sorted.isEmpty) b.writeln('No journal entries yet.');
    return b.toString();
  }

  /// Safe file name from a user-entered title.
  static String fileName(String title, String ext) {
    final base = title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return '${base.isEmpty ? 'touchgrass' : base}.$ext';
  }
}
