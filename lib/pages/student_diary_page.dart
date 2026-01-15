import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jplan_manager/services/nas_api_service.dart';

class StudentDiaryPage extends StatefulWidget {
  final int studentId;
  const StudentDiaryPage({super.key, required this.studentId});

  @override
  State<StudentDiaryPage> createState() => _StudentDiaryPageState();
}

class _StudentDiaryPageState extends State<StudentDiaryPage> {
  final NasApiService _api = NasApiService();
  final TextEditingController _commentController = TextEditingController();

  // ✅ 이미지 로딩을 위한 베이스 URL (서버 주소와 동일하게 맞춤)
  final String _baseUrl = 'http://alecs5iris.asuscomm.com:8000';

  Map<String, dynamic>? _diaryData;
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDiaryData();
  }

  Future<void> _loadDiaryData() async {
    setState(() => _isLoading = true);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final diary = await _api.getStudentDiary(widget.studentId, formattedDate);
      setState(() {
        _diaryData = diary;
        _commentController.text = _diaryData?['teacher_comment'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _diaryData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
      }
    }
  }

  Future<void> _saveComment() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      await _api.saveTeacherComment(widget.studentId, formattedDate, _commentController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코멘트가 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDiaryData();
    }
  }

  // ✅ 이미지를 보여주는 위젯 함수
  // ✅ 이미지를 보여주는 위젯 함수 (수정됨)
  Widget _buildImageSection(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const SizedBox.shrink(); // 이미지가 없으면 빈 공간
    }

    // 서버 DB에 저장된 경로는 'uploads/filename.jpg' 형식이므로 앞에 도메인을 붙여줌
    final fullUrl = '$_baseUrl/$imagePath';

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          width: double.infinity, // 가로는 부모 위젯에 맞춰 꽉 차게 설정
          // height: 200,         // ❌ [삭제] 이 고정 높이 때문에 잘려 보였습니다.

          // ✅ [수정] BoxFit.contain은 비율을 유지하며 이미지가 잘리지 않고
          // 지정된 영역(여기서는 가로폭) 안에 다 들어오게 합니다.
          // 만약 가로에 딱 맞추고 높이를 자동으로 늘리고 싶다면 fit 속성 자체를 지워도 됩니다.
          fit: BoxFit.contain,

          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100, // 에러 메시지 박스는 높이를 고정해도 괜찮습니다.
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Text('이미지를 불러올 수 없습니다.', style: TextStyle(color: Colors.grey)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 다이어리'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDiaryData),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_diaryData == null) {
      return Center(
        child: ElevatedButton(onPressed: _loadDiaryData, child: const Text('다시 시도')),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 선택 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(onPressed: _selectDate, child: const Text('날짜 변경')),
            ],
          ),
          const Divider(height: 32),

          // 1. 학습량 섹션 (내용 + 이미지)
          const Text('오늘의 학습량', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_diaryData!['learning_amount']?.toString().isEmpty ?? true)
                      ? '내용 없음' : _diaryData!['learning_amount'],
                  style: const TextStyle(fontSize: 16),
                ),
                // ✅ 이미지 표시 추가
                _buildImageSection(_diaryData!['learning_amount_image_url']),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. 느낀점 섹션 (내용 + 이미지)
          const Text('느낀점', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_diaryData!['feelings']?.toString().isEmpty ?? true)
                      ? '내용 없음' : _diaryData!['feelings'],
                  style: const TextStyle(fontSize: 16),
                ),
                // ✅ 이미지 표시 추가
                _buildImageSection(_diaryData!['feelings_image_url']),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. 선생님 코멘트 섹션
          const Text('선생님 코멘트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '학생에게 남길 코멘트를 입력하세요.'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveComment,
              icon: const Icon(Icons.save),
              label: const Text('코멘트 저장'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}