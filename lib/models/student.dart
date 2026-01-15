class Student {
  final int id;
  final String name;

  Student({required this.id, required this.name});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['user_id'],
      name: json['name'],
    );
  }
}