class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}
