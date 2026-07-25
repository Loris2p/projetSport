class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime? birthDate;
  final bool isAdmin;
  final bool showAds;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.birthDate,
    this.isAdmin = false,
    this.showAds = true,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? birthDate,
    bool? isAdmin,
    bool? showAds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      isAdmin: isAdmin ?? this.isAdmin,
      showAds: showAds ?? this.showAds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'birthDate': birthDate?.toIso8601String(),
      'isAdmin': isAdmin,
      'showAds': showAds,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['birthDate'] != null) {
      if (json['birthDate'] is String) {
        parsedDate = DateTime.tryParse(json['birthDate'] as String);
      } else {
        try {
          parsedDate = (json['birthDate'] as dynamic).toDate();
        } catch (_) {
          parsedDate = DateTime.tryParse(json['birthDate'].toString());
        }
      }
    }

    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      birthDate: parsedDate,
      isAdmin: json['isAdmin'] as bool? ?? false,
      showAds: json['showAds'] as bool? ?? true,
    );
  }
}


