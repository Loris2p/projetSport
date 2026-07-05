class UserProfile {
  final String uid;
  final String email;
  final String displayName;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
    );
  }
}
