/// Profile document stored at users/{uid}.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.homeCity = '',
    this.bio = '',
    this.interests = const [],
    this.travelStyle = '',
    this.savedPlaceIds = const [],
    this.visitedPlaceIds = const [],
    this.onboarded = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String homeCity;
  final String bio;

  /// PlaceCategory names the traveller is interested in.
  final List<String> interests;

  /// solo / couple / family / friends.
  final String travelStyle;
  final List<String> savedPlaceIds;
  final List<String> visitedPlaceIds;
  final bool onboarded;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'homeCity': homeCity,
    'bio': bio,
    'interests': interests,
    'travelStyle': travelStyle,
    'savedPlaceIds': savedPlaceIds,
    'visitedPlaceIds': visitedPlaceIds,
    'onboarded': onboarded,
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    homeCity: map['homeCity'] as String? ?? '',
    bio: map['bio'] as String? ?? '',
    interests: List<String>.from(map['interests'] as List? ?? const []),
    travelStyle: map['travelStyle'] as String? ?? '',
    savedPlaceIds: List<String>.from(map['savedPlaceIds'] as List? ?? const []),
    visitedPlaceIds: List<String>.from(map['visitedPlaceIds'] as List? ?? const []),
    onboarded: map['onboarded'] as bool? ?? false,
  );
}
