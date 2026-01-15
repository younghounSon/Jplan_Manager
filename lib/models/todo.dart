import 'package:intl/intl.dart';

class Todo {
  final int id;
  String? title;
  String? content;
  int? studentStatus;
  int? teacherStatus;
  final DateTime? date;
  final String? lastEditedByName;
  final DateTime? lastEditedAt;

  Todo({
    required this.id,
    this.title,
    this.content,
    this.studentStatus,
    this.teacherStatus,
    this.date,
    this.lastEditedByName,
    this.lastEditedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    // 날짜 파싱 로직
    DateTime? parseFlexibleDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString.replaceFirst(' ', 'T'));
      } catch (e) {
        try {
          return DateFormat("E, d MMM y HH:mm:ss 'GMT'", 'en_US').parse(dateString, true);
        } catch (e2) {
          return null;
        }
      }
    }

    return Todo(
      // ✅ 1. 서버는 'todo_id'를 줍니다.
      id: json['todo_id'] ?? json['id'] ?? 0,

      // ✅ 2. 제목
      title: json['title'] ?? '제목 없음',

      // ✅ 3. 서버는 'description'을 줍니다. (content 아님!)
      content: json['description'] ?? json['content'] ?? '',

      // ✅ 4. 학생 상태 (student_status)
      studentStatus: int.tryParse(json['student_status']?.toString() ?? '0'),

      // ⚠️ [가장 중요] 서버는 'is_teacher_checked'라고 줍니다!
      // 앱이 이걸 못 읽어서 계속 0으로 떴던 겁니다.
      teacherStatus: int.tryParse(json['is_teacher_checked']?.toString() ?? '0'),

      // 날짜 및 최종 수정 정보
      date: parseFlexibleDate(json['date'] as String?),
      lastEditedByName: json['last_edited_by_name'],
      lastEditedAt: parseFlexibleDate(json['last_edited_at'] as String?),
    );
  }
}