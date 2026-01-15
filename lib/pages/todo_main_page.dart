import 'package:flutter/material.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/models/student.dart';
import 'package:jplan_manager/pages/student_todo_page.dart';

class TodoMainPage extends StatefulWidget {
  const TodoMainPage({super.key});

  @override
  State<TodoMainPage> createState() => _TodoMainPageState();
}

class _TodoMainPageState extends State<TodoMainPage> {
  final NasApiService _api = NasApiService();
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _api.getStudentList();
  }

  // ✅ [추가] 목록을 새로고침하는 함수
  void _refreshStudentList() {
    setState(() {
      _studentsFuture = _api.getStudentList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ [수정] Scaffold를 추가하여 페이지의 경계를 명확히 함
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo 관리'),
        // ✅ [추가] 새로고침 버튼 추가
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStudentList,
          ),
        ],
      ),
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 학생이 없습니다.'));
          } else {
            // ✅ [수정] ListView.builder를 Column과 Expanded로 감싸서
            // 'infinite height/width' 오류를 근본적으로 방지
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final student = snapshot.data![index];
                      // ✅ [개선] 안정성을 위해 null 체크 추가
                      if (student == null) return const SizedBox.shrink();
                      return ListTile(
                        title: Text(student.name ?? '이름 없음'),
                        onTap: () async {
                          // ✅ [개선] 페이지에서 돌아왔을 때 목록이 새로고침되도록 await 추가
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentTodoPage(studentId: student.id),
                            ),
                          );
                          _refreshStudentList();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}