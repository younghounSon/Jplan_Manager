// /pages/approval_page.dart
import 'package:flutter/material.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/models/user.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final NasApiService _api = NasApiService();
  late Future<List<User>> _pendingUsersFuture;

  @override
  void initState() {
    super.initState();
    print('ApprovalPage initState: _pendingUsersFuture 초기화 시작');
    _pendingUsersFuture = _api.getPendingUsers();
    print('ApprovalPage initState: _pendingUsersFuture 초기화 완료');
  }

  Future<void> _approveUser(int userId) async {
    try {
      print('회원 ID $userId 승인 요청 시작');
      await _api.approveUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용자가 승인되었습니다.')));
        setState(() {
          print('승인 후 목록 새로고침');
          _pendingUsersFuture = _api.getPendingUsers();
        });
      }
      print('회원 ID $userId 승인 요청 완료');
    } catch (e) {
      print('승인 실패 오류: $e'); // 💡 실패 시 로그 추가
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('승인 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 승인')),
      body: FutureBuilder<List<User>>(
        future: _pendingUsersFuture,
        builder: (context, snapshot) {
          print('FutureBuilder 상태: ${snapshot.connectionState}'); // 기존 로그

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('FutureBuilder 오류 발생: ${snapshot.error}'); // 기존 로그
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('FutureBuilder: 데이터 없음 또는 비어있음'); // 기존 로그
            return const Center(child: Text('승인 대기 중인 사용자가 없습니다.'));
          } else {
            final users = snapshot.data!;
            // 💡 로그 위치 1: API로부터 받은 전체 데이터 목록을 확인합니다.
            print('✅ FutureBuilder: 데이터 수신 완료. 전체 데이터: ${users.toString()}');

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                // 💡 로그 위치 2: 리스트의 각 아이템이 위젯으로 만들어지기 직전에 확인합니다.
                // 만약 여기서 "Instance of 'User'"가 아닌 "null"이 출력되면 리스트 안에 null이 포함된 것입니다.
                final user = users[index];
                print('... ListView.builder[$index]: user 객체 = ${user.toString()}');

                // 💡 로그 위치 3: user 객체의 각 속성이 null인지 개별적으로 확인합니다.
                // 여기서 특정 속성이 null로 출력된다면 User 모델 클래스나 API 응답에 문제가 있는 것입니다.
                print('... ListView.builder[$index]: userId = ${user.userId}, username = ${user.username}');

                return ListTile(
                  title: Text(user.username),
                  subtitle: const Text('승인 대기'),
                  trailing: SizedBox( // 👈 SizedBox 추가
                    width: 80, // 👈 버튼에 적절한 너비 지정
                    child: ElevatedButton(
                      onPressed: () => _approveUser(user.userId),
                      child: const Text('승인'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}