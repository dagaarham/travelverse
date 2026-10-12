/// A travel-journal entry. Photos stay on the device (path only), text is
/// also synced to Firestore.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.date,
    required this.mood,
    this.tripId,
    this.placeId,
    this.photoPath,
    this.updatedAt,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime date;

  /// Experience rating 1-5.
  final int mood;
  final String? tripId;
  final String? placeId;
  final String? photoPath;
  final DateTime? updatedAt;
  final bool synced;

  Map<String, Object?> toRow() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'date': date.toIso8601String(),
    'mood': mood,
    'trip_id': tripId,
    'place_id': placeId,
    'photo_path': photoPath,
    'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    'synced': synced ? 1 : 0,
  };

  factory JournalEntry.fromRow(Map<String, Object?> row) => JournalEntry(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    title: row['title'] as String,
    body: row['body'] as String,
    date: DateTime.parse(row['date'] as String),
    mood: (row['mood'] as num).toInt(),
    tripId: row['trip_id'] as String?,
    placeId: row['place_id'] as String?,
    photoPath: row['photo_path'] as String?,
    updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    synced: (row['synced'] as int? ?? 0) == 1,
  );

  /// Cloud copy leaves out the local photo path, which is meaningless on
  /// another device.
  Map<String, dynamic> toCloud() => toRow()
    ..remove('synced')
    ..remove('photo_path');
}
