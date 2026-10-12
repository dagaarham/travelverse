import 'package:cloud_firestore/cloud_firestore.dart';

/// A structured review written by a traveller about a place.
class Review {
  const Review({
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.valueRating,
    required this.cleanlinessRating,
    required this.accessibilityRating,
    required this.text,
    required this.recommend,
    required this.bestTime,
    required this.verifiedVisit,
    required this.createdAt,
  });

  final String placeId;
  final String userId;
  final String userName;
  final double rating;
  final double valueRating;
  final double cleanlinessRating;
  final double accessibilityRating;
  final String text;
  final bool recommend;
  final String bestTime;

  /// True when the author had marked the place as visited before reviewing.
  final bool verifiedVisit;
  final DateTime createdAt;

  /// One review per traveller per place, so the id is deterministic.
  static String docId(String placeId, String userId) => '${placeId}_$userId';

  Map<String, dynamic> toMap() => {
    'placeId': placeId,
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'valueRating': valueRating,
    'cleanlinessRating': cleanlinessRating,
    'accessibilityRating': accessibilityRating,
    'text': text,
    'recommend': recommend,
    'bestTime': bestTime,
    'verifiedVisit': verifiedVisit,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Review.fromMap(Map<String, dynamic> map) => Review(
    placeId: map['placeId'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    userName: map['userName'] as String? ?? 'Traveller',
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    valueRating: (map['valueRating'] as num?)?.toDouble() ?? 0,
    cleanlinessRating: (map['cleanlinessRating'] as num?)?.toDouble() ?? 0,
    accessibilityRating: (map['accessibilityRating'] as num?)?.toDouble() ?? 0,
    text: map['text'] as String? ?? '',
    recommend: map['recommend'] as bool? ?? false,
    bestTime: map['bestTime'] as String? ?? '',
    verifiedVisit: map['verifiedVisit'] as bool? ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
