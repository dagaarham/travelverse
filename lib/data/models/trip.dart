/// A planned trip. Stored in SQLite first (offline-first) and synced to
/// Firestore when the device is online.
class Trip {
  const Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.budget,
    required this.tripType,
    this.notes = '',
    this.items = const [],
    this.updatedAt,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travellers;

  /// Total budget in rupees.
  final int budget;
  final String tripType;
  final String notes;
  final List<TripItem> items;
  final DateTime? updatedAt;
  final bool synced;

  /// Number of days, inclusive of start and end.
  int get dayCount => endDate.difference(startDate).inDays + 1;

  List<TripItem> itemsForDay(int day) => items.where((i) => i.day == day).toList()..sort((a, b) => a.position.compareTo(b.position));

  bool get isUpcoming => startDate.isAfter(DateTime.now());

  Trip copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? travellers,
    int? budget,
    String? tripType,
    String? notes,
    List<TripItem>? items,
    DateTime? updatedAt,
    bool? synced,
  }) => Trip(
    id: id,
    userId: userId,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    travellers: travellers ?? this.travellers,
    budget: budget ?? this.budget,
    tripType: tripType ?? this.tripType,
    notes: notes ?? this.notes,
    items: items ?? this.items,
    updatedAt: updatedAt ?? this.updatedAt,
    synced: synced ?? this.synced,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'destination': destination,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'travellers': travellers,
    'budget': budget,
    'trip_type': tripType,
    'notes': notes,
    'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    'synced': synced ? 1 : 0,
  };

  factory Trip.fromRow(Map<String, Object?> row, List<TripItem> items) => Trip(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    name: row['name'] as String,
    destination: row['destination'] as String,
    startDate: DateTime.parse(row['start_date'] as String),
    endDate: DateTime.parse(row['end_date'] as String),
    travellers: row['travellers'] as int,
    budget: row['budget'] as int,
    tripType: row['trip_type'] as String,
    notes: row['notes'] as String? ?? '',
    items: items,
    updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    synced: (row['synced'] as int? ?? 0) == 1,
  );

  /// Shape used for the Firestore copy (items embedded).
  Map<String, dynamic> toCloud() => {...toRow()..remove('synced'), 'items': items.map((i) => i.toRow()).toList()};

  factory Trip.fromCloud(Map<String, dynamic> map) => Trip.fromRow(
    Map<String, Object?>.from(map)..['synced'] = 1,
    (map['items'] as List? ?? const []).map((i) => TripItem.fromRow(Map<String, Object?>.from(i as Map))).toList(),
  );
}

/// A place scheduled on a given day of a trip.
class TripItem {
  const TripItem({
    required this.id,
    required this.tripId,
    required this.placeId,
    required this.day,
    required this.position,
    this.note = '',
  });

  final String id;
  final String tripId;
  final String placeId;

  /// 1-based day number within the trip.
  final int day;
  final int position;
  final String note;

  Map<String, Object?> toRow() => {'id': id, 'trip_id': tripId, 'place_id': placeId, 'day': day, 'position': position, 'note': note};

  factory TripItem.fromRow(Map<String, Object?> row) => TripItem(
    id: row['id'] as String,
    tripId: row['trip_id'] as String,
    placeId: row['place_id'] as String,
    day: (row['day'] as num).toInt(),
    position: (row['position'] as num).toInt(),
    note: row['note'] as String? ?? '',
  );
}
