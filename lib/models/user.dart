// /models/user.dart
class User {
  final int userId; // 필드 이름을 userId로 변경
  final String username;
  final String status;

  User({required this.userId, required this.username, required this.status});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int, // 서버 응답의 'user_id' 키를 사용
      username: json['name'] as String,   // 서버 응답의 'name' 키를 사용
      status: json['status'] as String,
    );
  }
}