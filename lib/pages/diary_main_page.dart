// /pages/diary_main_page.dart
import 'package:flutter/material.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/models/student.dart';
import 'package:jplan_manager/pages/student_diary_page.dart';

class DiaryMainPage extends StatefulWidget {
  const DiaryMainPage({super.key});

  @override
  State<DiaryMainPage> createState() => _DiaryMainPageState();
}

class _DiaryMainPageState extends State<DiaryMainPage> {
  final NasApiService _api = NasApiService();
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _api.getStudentList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('다이어리 관리')),
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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                // 💡 여기서 null 체크를 추가합니다.
                if (snapshot.data == null) {
                  return const SizedBox.shrink(); // 데이터가 없으면 빈 위젯 반환
                }
                final student = snapshot.data![index];
                return ListTile(
                  title: Text(student.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDiaryPage(studentId: student.id),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}