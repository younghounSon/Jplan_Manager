import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/models/todo.dart';
import 'package:provider/provider.dart';
import 'package:jplan_manager/services/nas_auth_service.dart';

class StudentTodoPage extends StatefulWidget {
  final int studentId;
  const StudentTodoPage({super.key, required this.studentId});

  @override
  State<StudentTodoPage> createState() => _StudentTodoPageState();
}

class _StudentTodoPageState extends State<StudentTodoPage> {
  final NasApiService _api = NasApiService();
  late Future<List<Todo>> _todosFuture;

  // 조회용 기간 설정 (기본값: 오늘)
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // 목록 불러오기
  void _loadTodos() {
    setState(() {
      final formattedStart = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEnd = DateFormat('yyyy-MM-dd').format(_endDate);
      _todosFuture = _api.getStudentTodos(widget.studentId, formattedStart, formattedEnd);
    });
  }

  // 날짜 범위 선택 (조회용)
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTodos();
    }
  }

  // ✅ [수정] 투두 추가 다이얼로그 (Map 기반 addTodo 사용)
  Future<void> _showAddTodoDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime selectedDate = DateTime.now(); // 추가할 투두의 날짜 (기본: 오늘)

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('새 ToDo 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 날짜 선택 버튼
                    Row(
                      children: [
                        const Text('날짜: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(selectedDate)),
                        ),
                      ],
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '제목', hintText: '예: 수학 문제집 풀기'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: '내용 (선택사항)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
                      return;
                    }

                    try {
                      // ✅ [핵심 수정] Map 형태로 데이터 전송
                      // 서버가 요구하는 필드명(user_id, description 등)을 정확히 맞춰야 합니다.
                      final Map<String, dynamic> newTodoData = {
                        'user_id': widget.studentId,
                        'title': titleController.text,
                        'description': contentController.text, // 서버 컬럼명: description
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        // 필요한 경우 기본값 추가
                        'is_teacher_checked': 0,
                        'student_status': 0,
                      };

                      await _api.addTodo(newTodoData);

                      // 성공 시 처리
                      if (mounted) {
                        Navigator.pop(context); // 닫기
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추가되었습니다.')));

                        // 날짜 범위 자동 확장 (센스 있는 UX)
                        if (selectedDate.isBefore(_startDate) || selectedDate.isAfter(_endDate)) {
                          setState(() {
                            if (selectedDate.isBefore(_startDate)) _startDate = selectedDate;
                            if (selectedDate.isAfter(_endDate)) _endDate = selectedDate;
                          });
                        }
                        _loadTodos(); // 목록 새로고침
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('추가 실패: $e')));
                      }
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 선생님 확인 상태 업데이트 (이건 기존 API 유지 - 상태 전용 엔드포인트 사용)
  Future<void> _updateTeacherTodoStatus(Todo todo, int newStatus) async {
    final originalStatus = todo.teacherStatus;
    final teacherId = Provider.of<NasAuthService>(context, listen: false).currentUserId;
    if (teacherId == null) return;

    setState(() {
      todo.teacherStatus = newStatus;
    });

    try {
      await _api.updateTeacherTodoStatus(todo.id, newStatus, teacherId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('상태 업데이트 실패: $e')));
        setState(() {
          todo.teacherStatus = originalStatus;
        });
      }
    }
  }

  // ✅ [수정] 투두 수정 다이얼로그 (Map 기반 updateTodo 사용)
  Future<void> _editTodoDialog(Todo todo) async {
    final titleController = TextEditingController(text: todo.title);
    final contentController = TextEditingController(text: todo.content);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('투두 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: '제목')),
                const SizedBox(height: 8),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: '내용'), maxLines: 5),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                final teacherId = Provider.of<NasAuthService>(context, listen: false).currentUserId;
                if (teacherId == null) return;

                try {
                  // ✅ [핵심 수정] Map 형태로 업데이트 데이터 전송
                  final Map<String, dynamic> updateData = {
                    'title': titleController.text,
                    'description': contentController.text, // 서버 컬럼명 주의
                    'last_edited_by_id': teacherId,        // 수정자(선생님) ID 포함
                  };

                  // ID와 Map을 함께 전달
                  await _api.updateTodo(todo.id, updateData);

                  _loadTodos();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
                  }
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 ToDo 관리'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('${DateFormat('yy.MM.dd').format(_startDate)} - ${DateFormat('yy.MM.dd').format(_endDate)}'),
              onPressed: _selectDateRange,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Todo>>(
              future: _todosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('해당 기간에 투두리스트가 없습니다.'));
                }

                final todos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return TodoItem(
                      todo: todo,
                      onEdit: () => _editTodoDialog(todo),
                      onStatusChange: (newStatus) => _updateTeacherTodoStatus(todo, newStatus),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// TodoItem (기존 유지)
// ---------------------------------------------------------
class TodoItem extends StatefulWidget {
  final Todo todo;
  final VoidCallback onEdit;
  final Function(int) onStatusChange;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _isExpanded = false;

  Icon _getStatusIcon(int? status) {
    switch (status) {
      case 1: return const Icon(Icons.radio_button_checked, color: Colors.blue);
      case 2: return const Icon(Icons.check_box, color: Colors.green);
      case 3: return const Icon(Icons.close, color: Colors.red);
      default: return const Icon(Icons.check_box_outline_blank, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        onLongPress: widget.onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.todo.title ?? '제목 없음',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          widget.todo.date == null
                              ? '날짜 미지정'
                              : DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.todo.date!),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(children: [
                        const Text('학', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        _getStatusIcon(widget.todo.studentStatus)
                      ]),
                      const SizedBox(width: 16),
                      Column(children: [
                        const Text('교', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        InkWell(
                          onTap: () {
                            int currentStatus = widget.todo.teacherStatus ?? 0;
                            int nextStatus = (currentStatus + 1) % 4;
                            widget.onStatusChange(nextStatus);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _getStatusIcon(widget.todo.teacherStatus),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(height: 24),
                Text(widget.todo.content ?? '', style: const TextStyle(fontSize: 14)),
                if (widget.todo.lastEditedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      '최종 수정: ${widget.todo.lastEditedByName ?? ''} (${DateFormat('yy-MM-dd HH:mm').format(widget.todo.lastEditedAt!)})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}