class UserModel {
  final String id;
  final String username;
  final String email;
  final String profileImage;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.profileImage,
  });

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
    };
  }

  // Create empty user
  factory UserModel.empty() {
    return UserModel(id: '', username: '', email: '', profileImage: '');
  }

  // Check if user is empty
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  get token => null;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email)';
  }
}
