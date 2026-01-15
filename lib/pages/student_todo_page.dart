import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jplan_manager/services/nas_api_service.dart';
import 'package:jplan_manager/models/todo.dart';
import 'package:provider/provider.dart'; // ✅ Provider import 추가
import 'package:jplan_manager/services/nas_auth_service.dart'; // ✅ AuthService import 추가

class StudentTodoPage extends StatefulWidget {
  final int studentId;
  const StudentTodoPage({super.key, required this.studentId});

  @override
  State<StudentTodoPage> createState() => _StudentTodoPageState();
}

class _StudentTodoPageState extends State<StudentTodoPage> {
  final NasApiService _api = NasApiService();
  late Future<List<Todo>> _todosFuture;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() {
    setState(() {
      final formattedStart = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEnd = DateFormat('yyyy-MM-dd').format(_endDate);
      _todosFuture = _api.getStudentTodos(widget.studentId, formattedStart, formattedEnd);
    });
  }

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

  // ✅ [수정] 선생님 상태만 업데이트하는 함수
  Future<void> _updateTeacherTodoStatus(Todo todo, int newStatus) async {
    final originalStatus = todo.teacherStatus;
    // Provider를 통해 현재 로그인된 선생님 ID 가져오기
    final teacherId = Provider.of<NasAuthService>(context, listen: false).currentUserId;
    if (teacherId == null) return;

    setState(() {
      todo.teacherStatus = newStatus;
    });

    try {
      await _api.updateTeacherTodoStatus(todo.id, newStatus, teacherId);
      // 성공 시 UI 즉시 갱신을 위해 목록 다시 로드
      _loadTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('상태 업데이트 실패: $e')));
        setState(() {
          todo.teacherStatus = originalStatus;
        });
      }
    }
  }

  // ✅ [수정] 제목과 내용을 모두 수정하는 대화상자
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
                if (teacherId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류: 사용자 정보를 찾을 수 없습니다.')));
                  }
                  return;
                }
                final newTitle = titleController.text;
                final newContent = contentController.text;

                try {
                  await _api.editTodo(todo.id, newTitle, newContent, teacherId);
                  _loadTodos(); // 수정 성공 시 목록 새로고침
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

  Icon _getStatusIcon(int? status) {
    switch (status) {
      case 1:
        return const Icon(Icons.radio_button_checked, color: Colors.blue);
      case 2:
        return const Icon(Icons.check_box, color: Colors.green);
      case 3:
        return const Icon(Icons.close, color: Colors.red);
      default:
        return const Icon(Icons.check_box_outline_blank, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 ToDo 관리'),
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
          const Divider(),
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
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    // ✅ [추가] 각 ListTile을 TodoItem 위젯으로 분리
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

// ✅ [추가] ListTile의 UI와 로직을 별도의 위젯으로 분리하여 가독성 및 재사용성 향상
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
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        onLongPress: widget.onEdit, // 길게 누르면 수정
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
                        Text(widget.todo.title ?? '제목 없음', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.todo.date == null ? '날짜 미지정' : DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(widget.todo.date!)),
                      ],
                    ),
                  ),
                  // ✅ [수정] 학생/선생님 아이콘 분리 표시
                  Row(
                    children: [
                      Column(children: [const Text('학'), _getStatusIcon(widget.todo.studentStatus)]),
                      const SizedBox(width: 8),
                      Column(children: [
                        const Text('교'),
                        IconButton(
                          icon: _getStatusIcon(widget.todo.teacherStatus),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            int currentStatus = widget.todo.teacherStatus ?? 0;
                            int nextStatus = (currentStatus + 1) % 4;
                            widget.onStatusChange(nextStatus);
                          },
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(height: 24),
                Text(widget.todo.content ?? '내용 없음'),
                if (widget.todo.lastEditedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '최종 수정: ${widget.todo.lastEditedByName ?? ''} (${DateFormat('yy-MM-dd HH:mm').format(widget.todo.lastEditedAt!)})',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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