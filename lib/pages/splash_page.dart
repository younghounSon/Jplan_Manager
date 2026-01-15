import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jplan_manager/services/nas_auth_service.dart';
import 'package:jplan_manager/pages/login_page.dart'; // 로그인 페이지 경로
import 'package:jplan_manager/pages/todo_main_page.dart';
import 'package:jplan_manager/main.dart';
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 자동 로그인 시도
  Future<void> _checkLoginStatus() async {
    final authService = Provider.of<NasAuthService>(context, listen: false);

    // 약간의 딜레이를 줘서 로고를 보여줄 수도 있음 (선택사항)
    await Future.delayed(const Duration(milliseconds: 500));

    // 저장된 정보로 로그인 시도
    final isSuccess = await authService.tryAutoLogin();

    if (!mounted) return;

    if (isSuccess) {
      // 성공하면 메인 페이지로 이동 (뒤로가기 불가)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePageWrapper()),
      );
    } else {
      // 실패하거나 정보가 없으면 로그인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // 로그인 페이지 클래스명 넣기
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고가 있다면 여기에 Image.asset(...) 추가
            Icon(Icons.assignment_ind, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            CircularProgressIndicator(), // 로딩 뺑뺑이
            SizedBox(height: 10),
            Text('로그인 확인 중...'),
          ],
        ),
      ),
    );
  }
}