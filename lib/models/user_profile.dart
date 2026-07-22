class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;
  final bool showAds;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isAdmin = false,
    this.showAds = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'showAds': showAds,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      showAds: json['showAds'] as bool? ?? true,
    );
  }
}

