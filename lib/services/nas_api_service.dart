import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jplan_manager/models/student.dart';
import 'package:jplan_manager/models/todo.dart';
import 'package:jplan_manager/models/user.dart';

class NasApiService {
  // 실제 사용 중인 주소로 유지
  final String _baseUrl = 'http://alecs5iris.asuscomm.com:8000';

  // ✅ 성공 여부를 판단하는 헬퍼 함수 (200~299 사이면 성공)
  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // 1. 선생님 로그인
  Future<Map<String, dynamic>> loginTeacher(String name, String password) async {
    final url = Uri.parse('$_baseUrl/teacher/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': name, 'password': password}),
    );

    if (_isSuccess(response.statusCode)) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('로그인 실패: [${response.statusCode}] ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 2. 학생 목록 조회
  Future<List<Student>> getStudentList() async {
    final url = Uri.parse('$_baseUrl/students');
    final response = await http.get(url);

    if (_isSuccess(response.statusCode)) {
      final List<dynamic> studentsJson = json.decode(utf8.decode(response.bodyBytes));
      return studentsJson.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('학생 목록 불러오기 실패: ${response.statusCode}');
    }
  }

  // 3. 학생 투두리스트 조회 (날짜 범위)
  Future<List<Todo>> getStudentTodos(int studentId, String startDate, String endDate) async {
    final url = Uri.parse('$_baseUrl/todos?student_id=$studentId&start_date=$startDate&end_date=$endDate');
    final response = await http.get(url);

    if (_isSuccess(response.statusCode)) {
      final List<dynamic> todosJson = json.decode(utf8.decode(response.bodyBytes));
      return todosJson.map((json) => Todo.fromJson(json)).toList();
    } else {
      throw Exception('투두리스트 조회 실패: ${response.statusCode}');
    }
  }

  // 4. 선생님의 투두 상태 변경 (여기가 문제였던 부분)
  // ✅ [수정] teacherId 포함 및 에러 디버깅 강화
  Future<void> updateTeacherTodoStatus(int todoId, int newStatus, int teacherId) async {
    final url = Uri.parse('$_baseUrl/todos/$todoId/teacher_status');

    print('PUT 요청 전송: $url'); // 디버깅 로그

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'teacher_status': newStatus,
        'last_edited_by_id': teacherId,
      }),
    );

    // ✅ 로그 확인용 (앱 실행 콘솔에서 확인 가능)
    print('상태 업데이트 응답: ${response.statusCode}, Body: ${response.body}');

    // 200~299 사이가 아니면 에러 처리
    if (!_isSuccess(response.statusCode)) {
      // 서버가 보낸 구체적인 에러 메시지를 포함해서 throw
      throw Exception('업데이트 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
    // 성공 시에는 아무것도 리턴하지 않음 (void)
  }

  // 4-1. 투두 내용/제목 수정
  Future<void> editTodo(int todoId, String newTitle, String newContent, int teacherId) async {
    final url = Uri.parse('$_baseUrl/todos/$todoId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': newTitle,
        'content': newContent,
        'last_edited_by_id': teacherId,
      }),
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception('ToDo 수정 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 5. 학생 다이어리 조회
  Future<Map<String, dynamic>> getStudentDiary(int studentId, String date) async {
    // ⚠️ 수정: 서버가 'userId'를 찾으므로 user_id -> userId로 변경해야 합니다!
    final url = Uri.parse('$_baseUrl/diary?userId=$studentId&date=$date');

    final response = await http.get(url);

    if (_isSuccess(response.statusCode)) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('다이어리 불러오기 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 6. 선생님 코멘트 저장
  Future<void> saveTeacherComment(int studentId, String date, String comment) async {
    final url = Uri.parse('$_baseUrl/diary/comment');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': studentId, 'date': date, 'comment': comment}),
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception('코멘트 저장 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 7. 회원가입 승인 대기 목록 조회
  Future<List<User>> getPendingUsers() async {
    final url = Uri.parse('$_baseUrl/users/pending');
    final response = await http.get(url);

    if (_isSuccess(response.statusCode)) {
      final List<dynamic> usersJson = json.decode(utf8.decode(response.bodyBytes));
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('승인 대기 목록 조회 실패: ${response.statusCode}');
    }
  }

  // 8. 사용자 승인
  Future<void> approveUser(int userId) async {
    final url = Uri.parse('$_baseUrl/user/$userId/approve');
    final response = await http.put(url);

    if (!_isSuccess(response.statusCode)) {
      throw Exception('사용자 승인 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 9. 선생님 회원가입
  Future<void> signup(String email, String name, String phoneNumber, String password) async {
    final url = Uri.parse('$_baseUrl/signup/teacher');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception('회원가입 실패(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }
}