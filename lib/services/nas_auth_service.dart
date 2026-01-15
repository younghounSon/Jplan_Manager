import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 패키지 import
import 'package:jplan_manager/services/nas_api_service.dart';

class NasAuthService extends ChangeNotifier {
  final NasApiService _api = NasApiService();

  // 기기에 정보를 안전하게 저장하는 저장소
  final _storage = const FlutterSecureStorage();

  int? _currentUserId;
  Map<String, dynamic>? _currentUserData;

  // ---------------- Getter (기존 호환 유지) ----------------

  // 인증 여부 확인
  bool get isAuthenticated => _currentUserId != null;

  // 선생님 로그인 여부 (요청하신 부분)
  bool get isTeacherLoggedIn => _currentUserId != null;

  // 현재 사용자 ID
  int? get currentUserId => _currentUserId;

  // 현재 사용자 전체 데이터
  Map<String, dynamic>? get currentUserData => _currentUserData;


  // ---------------- 기능 함수 ----------------

  // 1. 로그인 (API 호출 + 저장소 저장)
  // 기존에는 UI에서 API를 불렀지만, 이제는 여기서 부릅니다.
  Future<void> login(String email, String password) async {
    try {
      // API 호출
      final data = await _api.loginTeacher(email, password);

      // 상태 업데이트
      _currentUserId = data['user_id']; // 서버 응답의 키값 확인 필요 (user_id)
      _currentUserData = data;

      // ✅ 자동 로그인을 위해 기기에 암호화하여 저장
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);

      notifyListeners();
    } catch (e) {
      rethrow; // 에러를 UI로 던져서 스낵바 등을 띄우게 함
    }
  }

  // 2. 자동 로그인 시도 (앱 켤 때 호출)
  Future<bool> tryAutoLogin() async {
    // 저장된 이메일/비번 읽기
    final savedEmail = await _storage.read(key: 'email');
    final savedPassword = await _storage.read(key: 'password');

    // 저장된 정보가 없으면 실패
    if (savedEmail == null || savedPassword == null) {
      return false;
    }

    try {
      // 저장된 정보로 로그인 재시도
      final data = await _api.loginTeacher(savedEmail, savedPassword);

      // 성공 시 상태 복구
      _currentUserId = data['user_id'];
      _currentUserData = data;

      notifyListeners();
      return true; // 성공
    } catch (e) {
      // 비번 변경 등으로 실패 시 저장된 정보 삭제
      await logout();
      return false; // 실패
    }
  }

  // 3. 로그아웃
  Future<void> logout() async {
    _currentUserId = null;
    _currentUserData = null;

    // ✅ 저장소에서도 정보 삭제 (완전 로그아웃)
    await _storage.deleteAll();

    notifyListeners();
  }
}