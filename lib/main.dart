// /main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jplan_manager/pages/login_page.dart';
import 'package:jplan_manager/pages/todo_main_page.dart'; // TodoMainPage import
import 'package:jplan_manager/pages/diary_main_page.dart'; // DiaryMainPage import
import 'package:jplan_manager/pages/approval_page.dart';
import 'package:jplan_manager/services/nas_auth_service.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:intl/date_symbol_data_local.dart';
void main() async {
  await initializeDateFormatting('ko_KR');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NasApiService>(create: (_) => NasApiService()),
        ChangeNotifierProvider<NasAuthService>(create: (_) => NasAuthService()),
      ],
      child: MaterialApp(
        title: '선생님 관리 앱',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              // ✅ minimumSize 속성을 제거하거나, 특정 값으로 지정합니다.
              // minimumSize: const Size(0, 50), // 또는 이 라인 전체를 주석 처리
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              // 필요하다면 패딩을 조절해 버튼 크기를 키울 수 있습니다.
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NasAuthService>(
      builder: (context, authService, _) {
        if (authService.isTeacherLoggedIn) {
          return const HomePageWrapper();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TodoMainPage(),    // 첫 번째 탭: 학생 ToDo 관리
    DiaryMainPage(),   // 두 번째 탭: 학생 다이어리 관리
    ApprovalPage(),    // 세 번째 탭: 회원가입 승인
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ [수정] body 부분을 Column과 Expanded로 감싸서 너비 제약 설정
      body: Column(
        children: [
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'ToDo 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: '다이어리 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: '회원가입 승인',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: Visibility(
        visible: _selectedIndex == 0,
        child: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('새로운 ToDo 추가 기능 구현 필요')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}