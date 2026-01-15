import 'package:flutter/material.dart';
import 'package:jplan_manager/services/nas_api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NasApiService _api = NasApiService();

  Future<void> _signup() async {
    try {
      await _api.signup(
        _emailController.text,
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 관리자의 승인을 기다려 주세요.')),
        );
        Navigator.pop(context); // 회원가입 성공 시 이전 페이지(로그인 페이지)로 돌아가기
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일')),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '이름')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: '전화번호')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: const Text('회원가입 신청'),
            ),
          ],
        ),
      ),
    );
  }
}