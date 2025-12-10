import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 待办事项列表
  final List<TodoItem> _pendingTodos = [];
  final List<TodoItem> _completedTodos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: 从服务器加载待办事项
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 标题栏
          _buildHeader(),
          // 标签页
          _buildTabBar(),
          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(_pendingTodos, false),
                _buildTodoList(_completedTodos, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建标题栏
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.translate('todo'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          // 添加待办按钮
          ElevatedButton.icon(
            onPressed: _showAddTodoDialog,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.translate('add_todo')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1890FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建标签栏
  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1890FF),
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: const Color(0xFF1890FF),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Tab(text: l10n.translate('pending')),
          Tab(text: l10n.translate('completed')),
        ],
      ),
    );
  }

  // 构建待办列表
  Widget _buildTodoList(List<TodoItem> todos, bool isCompleted) {
    if (todos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoItem(todo, isCompleted);
      },
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 空状态图片
          Image.asset(
            'assets/待办/todoListEmpty.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('no_todo_content'),
            style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  // 构建待办项
  Widget _buildTodoItem(TodoItem todo, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 待办内容（可点击查看详情）
          Expanded(
            child: InkWell(
              onTap: () => _showTodoDetailDialog(todo, isCompleted),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? const Color(0xFF999999)
                            : const Color(0xFF1A1A1A),
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (todo.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        todo.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF666666),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标记完成/未完成按钮
              IconButton(
                onPressed: () => _toggleTodoStatus(todo),
                icon: Icon(
                  isCompleted ? Icons.restart_alt : Icons.check_circle_outline,
                  color: isCompleted
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF52C41A),
                ),
                tooltip: isCompleted 
                    ? AppLocalizations.of(context).translate('mark_incomplete')
                    : AppLocalizations.of(context).translate('mark_complete'),
              ),
              // 删除按钮
              IconButton(
                onPressed: () => _deleteTodo(todo),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: AppLocalizations.of(context).translate('delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 显示待办详情对话框
  void _showTodoDetailDialog(TodoItem todo, bool isCompleted) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF52C41A)
                      : const Color(0xFF1890FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted 
                      ? AppLocalizations.of(context).translate('completed')
                      : AppLocalizations.of(context).translate('pending'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.description?.isNotEmpty ?? false) ...[
                  Text(
                    AppLocalizations.of(context).translate('description'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      todo.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        height: 1.6,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    AppLocalizations.of(context).translate('no_description'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // 关闭按钮
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1890FF),
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).translate('close')),
            ),
          ],
        );
      },
    );
  }

  // 显示添加待办对话框
  void _showAddTodoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.translate('add_todo')),
          content: SizedBox(
            width: 560, // 宽度减小30% (800 * 0.7 = 560)
            height: 300, // 高度增加一倍
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('title'),
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(fontSize: 13), // 描述输入文字更小
                  decoration: InputDecoration(
                    labelText: l10n.translate('description_optional'),
                    labelStyle: const TextStyle(fontSize: 13), // 描述标签文字更小
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 8, // 增加行数以适应更大的高度
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  _addTodo(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1890FF),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('confirm')),
            ),
          ],
        );
      },
    );
  }

  // 添加待办
  void _addTodo(String title, String description) {
    setState(() {
      _pendingTodos.add(
        TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: description.isNotEmpty ? description : null,
          isCompleted: false,
        ),
      );
    });
    // TODO: 保存到服务器
  }

  // 切换待办状态
  void _toggleTodoStatus(TodoItem todo) {
    setState(() {
      if (_pendingTodos.contains(todo)) {
        _pendingTodos.remove(todo);
        _completedTodos.add(todo.copyWith(isCompleted: true));
      } else if (_completedTodos.contains(todo)) {
        _completedTodos.remove(todo);
        _pendingTodos.add(todo.copyWith(isCompleted: false));
      }
    });
    // TODO: 更新到服务器
  }

  // 删除待办
  void _deleteTodo(TodoItem todo) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.translate('confirm_delete')),
          content: Text(l10n.translate('confirm_delete_todo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pendingTodos.remove(todo);
                  _completedTodos.remove(todo);
                });
                Navigator.of(context).pop();
                // TODO: 从服务器删除
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('delete')),
            ),
          ],
        );
      },
    );
  }
}

// 待办项数据模型
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
