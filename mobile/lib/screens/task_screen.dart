import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/views/task_list_view.dart';
import '../widgets/gantt/gantt_view.dart';
import 'task_detail_screen.dart';

class TaskScreen extends StatefulWidget {
  final int projectId;
  const TaskScreen({super.key, required this.projectId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _showGantt = true; // Default to Gantt view

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      provider.fetchTasks(widget.projectId);
      provider.fetchGanttData(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('任务'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (taskProvider.error != null) {
            return Center(child: Text('Error: ${taskProvider.error}'));
          }
          if (taskProvider.tasks.isEmpty) {
            return _buildEmptyState();
          }
          return Column(
            children: [
              _buildViewToggle(),
              Expanded(
                child: _showGantt
                    ? _buildGanttView(taskProvider)
                    : _buildListView(taskProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('甘特图'), icon: Icon(Icons.bar_chart)),
                  ButtonSegment(value: false, label: Text('列表'), icon: Icon(Icons.list)),
                ],
                selected: {_showGantt},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() => _showGantt = newSelection.first);
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          // Link type legend
          if (_showGantt)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                children: [
                  _buildLegendItem(const Color(0xFF4CAF50), 'FS 完成-开始'),
                  _buildLegendItem(const Color(0xFF2196F3), 'SS 开始-开始'),
                  _buildLegendItem(const Color(0xFFFF9800), 'FF 完成-完成'),
                  _buildLegendItem(const Color(0xFF9C27B0), 'SF 开始-完成'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildGanttView(TaskProvider provider) {
    return GanttView(
      tasks: provider.tasks,
      links: provider.links,
      onTaskTap: (task) => _navigateToDetail(task),
      onDateChange: (taskId, newStart, newEnd) async {
        final success = await provider.updateTask(
          taskId,
          startDate: newStart.toIso8601String().split('T')[0],
          endDate: newEnd.toIso8601String().split('T')[0],
        );
        if (success && mounted) {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日期已更新'), duration: Duration(seconds: 1)),
          );
        }
      },
      onProgressChange: (taskId, newProgress) async {
        final success = await provider.updateTaskProgress(taskId, newProgress);
        if (success && mounted) {
          // Local state is updated in provider, no need for full refresh
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('进度已更新: $newProgress%'), duration: const Duration(seconds: 1)),
          );
        }
      },
      onLinkCreate: (sourceId, targetId, linkType) async {
        final success = await provider.createLink(sourceId, targetId, linkType);
        if (success && mounted) {
          provider.fetchGanttData(widget.projectId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('依赖关系已创建'), duration: Duration(seconds: 1)),
          );
        }
      },
      onLinkDelete: (linkId) async {
        final success = await provider.deleteLink(linkId);
        if (success && mounted) {
          provider.fetchGanttData(widget.projectId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('依赖关系已删除'), duration: Duration(seconds: 1)),
          );
        }
      },
      onAddSubtask: (parentTask) {
        _showCreateSubtaskDialog(context, parentTask);
      },
    );
  }

  Widget _buildListView(TaskProvider provider) {
    return TaskListView(
      tasks: provider.tasks,
      onTaskTap: (task) => _navigateToDetail(task),
      onRefresh: () async {
        await provider.fetchTasks(widget.projectId);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text('暂无任务', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('点击下方按钮创建第一个任务'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('新建任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    ).then((_) => _refreshData());
  }

  void _showCreateTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateTaskSheet(projectId: widget.projectId),
    );
  }

  void _showCreateSubtaskDialog(BuildContext context, Task parentTask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateTaskSheet(
        projectId: widget.projectId,
        parentTaskId: parentTask.id,
        parentTaskTitle: parentTask.title,
      ),
    );
  }
}

class CreateTaskSheet extends StatefulWidget {
  final int projectId;
  final int? parentTaskId;
  final String? parentTaskTitle;
  
  const CreateTaskSheet({
    super.key, 
    required this.projectId,
    this.parentTaskId,
    this.parentTaskTitle,
  });

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await Provider.of<TaskProvider>(context, listen: false).createTask(
      widget.projectId,
      _titleController.text,
      _descController.text,
      priority: _priority,
      startDate: _startDate?.toIso8601String().split('T')[0],
      endDate: _endDate?.toIso8601String().split('T')[0],
      parentId: widget.parentTaskId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubtask = widget.parentTaskId != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSubtask ? '添加子任务' : '创建任务', 
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (isSubtask) ...[
            const SizedBox(height: 4),
            Text(
              '父任务: ${widget.parentTaskTitle}',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: isSubtask ? '子任务标题' : '任务标题',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: '描述'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('优先级: '),
              DropdownButton<String>(
                value: _priority,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('低')),
                  DropdownMenuItem(value: 'medium', child: Text('中')),
                  DropdownMenuItem(value: 'high', child: Text('高')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate == null ? '开始日期' : _startDate.toString().split(' ')[0]),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_endDate == null ? '结束日期' : _endDate.toString().split(' ')[0]),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : const Text('创建'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
