// /pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/services/nas_auth_service.dart';
import 'package:jplan_manager/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NasApiService _api = NasApiService();

  Future<void> _login() async {
    print('1. 로그인 버튼 클릭. _login 함수 시작');
    try {
      final response = await _api.loginTeacher(_idController.text, _passwordController.text);
      print('2. API 응답 수신: ${response}');

      // 서버 응답에 'message' 키가 있고 그 값이 'Login successful'인지 확인
      if (response['message'] == 'Login successful') {
        print('3. 로그인 성공. Provider 상태 업데이트 시도.');

        final userId = response['user_id'];
        final userData = {
          'id': userId,
          'role': response['role'] ?? 'teacher', // 서버 응답에 role이 있다면 사용, 없으면 'teacher'로 기본값 설정
          'status': response['status'] ?? 'approved', // 서버 응답에 status가 있다면 사용, 없으면 'approved'로 기본값 설정
        };

        if (mounted) {
          // Provider 상태만 업데이트. AuthWrapper가 페이지 전환을 감지함
          Provider.of<NasAuthService>(context, listen: false).login(userId, userData);
          print('4. Provider 상태 업데이트 완료. isTeacherLoggedIn: ${Provider.of<NasAuthService>(context, listen: false).isTeacherLoggedIn}');
        }
      } else {
        print('3. 로그인 실패: 메시지 불일치');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 실패: 자격 증명 오류')),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선생님 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _idController, decoration: const InputDecoration(labelText: '아이디')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(), // 콜백 함수로 명확하게 감싸서 호출
              child: const Text('로그인'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}