// /pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jplan_manager/services/nas_auth_service.dart';
import 'package:jplan_manager/pages/signup_page.dart';
import 'package:jplan_manager/pages/todo_main_page.dart'; // ✅ 메인 페이지 import 필수!
import 'package:jplan_manager/main.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ✅ NasApiService 제거 (AuthService가 내부에서 처리함)

  Future<void> _login() async {
    // 1. 입력값 검증
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    print('1. 로그인 요청 시작 (Service 호출)');

    try {
      // ✅ 2. Provider를 통해 AuthService의 login 함수 호출
      // 이제 이메일과 비밀번호만 넘겨주면, 서비스가 알아서 API 호출 + 기기 저장까지 수행합니다.
      await Provider.of<NasAuthService>(context, listen: false)
          .login(_idController.text, _passwordController.text);

      print('2. 로그인 성공 및 저장 완료. 메인 페이지로 이동.');

      if (mounted) {
        // ✅ 3. 성공 시 메인 페이지로 이동 (뒤로가기 방지를 위해 pushReplacement 사용)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageWrapper()),
        );
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        // 실패 시 에러 메시지 표시
        // AuthService에서 rethrow한 에러 메시지가 여기 뜹니다.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${e.toString().replaceAll("Exception:", "")}')),
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
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디 (이메일)'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('로그인', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 10),

            // 회원가입 버튼
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