import 'package:flutter/material.dart';

class NasAuthService extends ChangeNotifier {
  int? _currentUserId; // userId로 변수명 변경
  Map<String, dynamic>? _currentUserData;

  // 인증 여부를 확인하는 getter
  bool get isAuthenticated => _currentUserId != null;

  // 선생님 앱에서 사용할 isTeacherLoggedIn getter 추가
  bool get isTeacherLoggedIn => _currentUserId != null; // 이 부분을 추가하세요.
  int? get currentUserId => _currentUserId;

  // 현재 사용자 데이터 getter
  Map<String, dynamic>? get currentUserData => _currentUserData;

  // 로그인 시 사용자 정보 저장
  void login(int userId, Map<String, dynamic> userData) {
    _currentUserId = userId;
    _currentUserData = userData;
    notifyListeners();
  }

  // 로그아웃
  void logout() {
    _currentUserId = null;
    _currentUserData = null;
    notifyListeners();
  }
}