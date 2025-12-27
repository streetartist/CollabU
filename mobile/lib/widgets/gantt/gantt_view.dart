import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../models/task.dart';
import '../../models/task_link.dart';
import 'gantt_bar.dart';
import 'gantt_header.dart';
import 'gantt_link_painter.dart';

class GanttView extends StatefulWidget {
  final List<Task> tasks;
  final List<TaskLink> links;
  final Function(Task)? onTaskTap;
  final Function(int taskId, DateTime newStart, DateTime newEnd)? onDateChange;
  final Function(int taskId, int newProgress)? onProgressChange;
  final Function(int sourceId, int targetId, String linkType)? onLinkCreate;
  final Function(int linkId)? onLinkDelete;
  final Function(Task parentTask)? onAddSubtask;

  const GanttView({
    super.key,
    required this.tasks,
    required this.links,
    this.onTaskTap,
    this.onDateChange,
    this.onProgressChange,
    this.onLinkCreate,
    this.onLinkDelete,
    this.onAddSubtask,
  });

  @override
  State<GanttView> createState() => _GanttViewState();
}

class _GanttViewState extends State<GanttView> {
  late LinkedScrollControllerGroup _controllers;
  late ScrollController _taskController;
  late ScrollController _timelineController;
  final ScrollController _horizontalController = ScrollController();
  bool _isTaskListVisible = true;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  static const double _dayWidth = 40.0;
  static const double _rowHeight = 50.0;
  static const double _taskColumnWidth = 150.0;

  // Click-to-link state: first click selects source, second click creates link
  int? _linkSourceTaskId;

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _taskController = _controllers.addAndGet();
    _timelineController = _controllers.addAndGet();
    _calculateDateRange();
  }

  @override
  void didUpdateWidget(GanttView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _calculateDateRange();
    }
  }

  void _calculateDateRange() {
    if (widget.tasks.isEmpty) return;

    DateTime? minDate;
    DateTime? maxDate;

    for (final task in widget.tasks) {
      if (task.startDate != null) {
        final start = DateTime.parse(task.startDate!);
        if (minDate == null || start.isBefore(minDate)) {
          minDate = start;
        }
      }
      if (task.endDate != null) {
        final end = DateTime.parse(task.endDate!);
        if (maxDate == null || end.isAfter(maxDate)) {
          maxDate = end;
        }
      }
    }

    setState(() {
      _startDate = minDate?.subtract(const Duration(days: 7)) ??
          DateTime.now().subtract(const Duration(days: 7));
      _endDate = maxDate?.add(const Duration(days: 14)) ??
          DateTime.now().add(const Duration(days: 30));
    });
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTimeControls(),
        Expanded(
          child: Row(
            children: [
              _buildTaskColumn(),
              Expanded(child: _buildTimelineArea()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_isTaskListVisible ? Icons.fullscreen : Icons.fullscreen_exit),
                onPressed: () {
                  setState(() {
                    _isTaskListVisible = !_isTaskListVisible;
                  });
                },
                tooltip: _isTaskListVisible ? '隐藏任务列表' : '显示任务列表',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _scrollTimeline(-7),
                tooltip: '前一周',
              ),
              TextButton(
                onPressed: _scrollToToday,
                style: TextButton.styleFrom(
                  minimumSize: const Size(40, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('今天'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _scrollTimeline(7),
                tooltip: '后一周',
              ),
            ],
          ),
          Flexible(
            child: Text(
              '${_startDate.year}年${_startDate.month}月',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}';

  void _scrollTimeline(int days) {
    if (!_horizontalController.hasClients) return;
    final newOffset = _horizontalController.offset + (days * _dayWidth);
    _horizontalController.animateTo(
      newOffset.clamp(0.0, _horizontalController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToToday() {
    if (!_horizontalController.hasClients) return;
    final today = DateTime.now();
    final daysSinceStart = today.difference(_startDate).inDays;
    final targetOffset = (daysSinceStart * _dayWidth) - (MediaQuery.of(context).size.width / 2);

    _horizontalController.animateTo(
      targetOffset.clamp(0.0, _horizontalController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTaskColumn() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isTaskListVisible ? _taskColumnWidth : 0,
      child: ClipRect(
        child: Container(
          width: _taskColumnWidth,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('任务名称', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _taskController,
                  itemCount: widget.tasks.length,
                  itemBuilder: (context, index) {
                    final task = widget.tasks[index];
                    return _buildTaskNameRow(task);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskNameRow(Task task) {
    final isChild = task.level > 0;
    return InkWell(
      onTap: () => widget.onTaskTap?.call(task),
      child: Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          color: isChild ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardTheme.color,
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            // Indent with colored line for children
            if (isChild)
              Container(
                width: 3,
                height: _rowHeight,
                margin: EdgeInsets.only(left: 4.0 + ((task.level - 1) * 12.0)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            SizedBox(width: isChild ? 8 : 8),
            // Task icon
            Icon(
              task.hasSubtasks 
                  ? Icons.folder_outlined

                  : isChild 
                      ? Icons.subdirectory_arrow_right
                      : Icons.task_alt,
              size: 16,
              color: task.hasSubtasks ? Colors.amber.shade700 : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: task.hasSubtasks ? FontWeight.w600 : FontWeight.normal,
                  color: isChild ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineArea() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalController,
      child: SizedBox(
        width: _totalDays * _dayWidth,
        child: Column(
          children: [
            // Link mode indicator
            if (_linkSourceTaskId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('正在创建依赖: 点击目标任务完成连接',
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _linkSourceTaskId = null),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
            GanttHeader(
              startDate: _startDate,
              totalDays: _totalDays,
              dayWidth: _dayWidth,
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildGridBackground(),
                  _buildTodayLine(),
                  // Link painter (dependency arrows)
                  CustomPaint(
                    size: Size(_totalDays * _dayWidth, widget.tasks.length * _rowHeight),
                    painter: GanttLinkPainter(
                      tasks: widget.tasks,
                      links: widget.links,
                      startDate: _startDate,
                      dayWidth: _dayWidth,
                      rowHeight: _rowHeight,
                    ),
                  ),
                  // Task bars
                  ListView.builder(
                    controller: _timelineController,
                    itemCount: widget.tasks.length,
                    itemBuilder: (context, index) {
                      final task = widget.tasks[index];
                      final isLinkSource = _linkSourceTaskId == task.id;
                      final hasLinks = widget.links.any((l) => l.source == task.id || l.target == task.id);
                      return GanttBar(
                        task: task,
                        startDate: _startDate,
                        dayWidth: _dayWidth,
                        rowHeight: _rowHeight,
                        isLinkSource: isLinkSource,
                        isLinkMode: _linkSourceTaskId != null,
                        hasLinks: hasLinks,
                        onTap: () => widget.onTaskTap?.call(task),
                        onDateChange: (newStart, newEnd) {
                          widget.onDateChange?.call(task.id, newStart, newEnd);
                        },
                        onProgressChange: (newProgress) {
                          widget.onProgressChange?.call(task.id, newProgress);
                        },
                        onLinkPointTap: () => _handleLinkPointTap(task),
                        onAddSubtask: () {
                          widget.onAddSubtask?.call(task);
                        },
                        onLinkTap: () => _showTaskLinksDialog(task),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLinkPointTap(Task task) {
    if (_linkSourceTaskId == null) {
      // First click: select source
      setState(() => _linkSourceTaskId = task.id);
    } else if (_linkSourceTaskId != task.id) {
      // Second click on different task: show type selection
      _showLinkTypeDialog(_linkSourceTaskId!, task.id);
    } else {
      // Clicked same task: cancel
      setState(() => _linkSourceTaskId = null);
    }
  }

  void _handleLinkTap(Offset tapPosition) {
    // Find if tap is near any link line
    const hitThreshold = 15.0;
    
    for (final link in widget.links) {
      final sourceTask = widget.tasks.firstWhere(
        (t) => t.id == link.source,
        orElse: () => Task(id: -1, title: ''),
      );
      final targetTask = widget.tasks.firstWhere(
        (t) => t.id == link.target,
        orElse: () => Task(id: -1, title: ''),
      );
      
      if (sourceTask.id == -1 || targetTask.id == -1) continue;
      
      final sourceIndex = widget.tasks.indexOf(sourceTask);
      final targetIndex = widget.tasks.indexOf(targetTask);
      
      // Get link endpoints based on type
      Offset startPos, endPos;
      switch (link.type) {
        case '0': // FS
          if (sourceTask.endDate == null || targetTask.startDate == null) continue;
          startPos = Offset((DateTime.parse(sourceTask.endDate!).difference(_startDate).inDays + 1) * _dayWidth, sourceIndex * _rowHeight + _rowHeight / 2);
          endPos = Offset(DateTime.parse(targetTask.startDate!).difference(_startDate).inDays * _dayWidth, targetIndex * _rowHeight + _rowHeight / 2);
          break;
        case '1': // SS
          if (sourceTask.startDate == null || targetTask.startDate == null) continue;
          startPos = Offset(DateTime.parse(sourceTask.startDate!).difference(_startDate).inDays * _dayWidth, sourceIndex * _rowHeight + _rowHeight / 2);
          endPos = Offset(DateTime.parse(targetTask.startDate!).difference(_startDate).inDays * _dayWidth, targetIndex * _rowHeight + _rowHeight / 2);
          break;
        case '2': // FF
          if (sourceTask.endDate == null || targetTask.endDate == null) continue;
          startPos = Offset((DateTime.parse(sourceTask.endDate!).difference(_startDate).inDays + 1) * _dayWidth, sourceIndex * _rowHeight + _rowHeight / 2);
          endPos = Offset((DateTime.parse(targetTask.endDate!).difference(_startDate).inDays + 1) * _dayWidth, targetIndex * _rowHeight + _rowHeight / 2);
          break;
        case '3': // SF
          if (sourceTask.startDate == null || targetTask.endDate == null) continue;
          startPos = Offset(DateTime.parse(sourceTask.startDate!).difference(_startDate).inDays * _dayWidth, sourceIndex * _rowHeight + _rowHeight / 2);
          endPos = Offset((DateTime.parse(targetTask.endDate!).difference(_startDate).inDays + 1) * _dayWidth, targetIndex * _rowHeight + _rowHeight / 2);
          break;
        default:
          continue;
      }
      
      // Check if tap is near the line (simplified check)
      final midPoint = Offset((startPos.dx + endPos.dx) / 2, (startPos.dy + endPos.dy) / 2);
      if ((tapPosition - midPoint).distance < hitThreshold ||
          (tapPosition - startPos).distance < hitThreshold ||
          (tapPosition - endPos).distance < hitThreshold) {
        _showDeleteLinkDialog(link);
        return;
      }
    }
  }

  void _showDeleteLinkDialog(TaskLink link) {
    final sourceTask = widget.tasks.firstWhere((t) => t.id == link.source, orElse: () => Task(id: -1, title: '?'));
    final targetTask = widget.tasks.firstWhere((t) => t.id == link.target, orElse: () => Task(id: -1, title: '?'));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除依赖关系'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除以下依赖关系吗？'),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GanttLinkPainter.getLinkColor(link.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(link.typeShort, style: TextStyle(color: GanttLinkPainter.getLinkColor(link.type), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('${sourceTask.title} → ${targetTask.title}', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLinkDelete?.call(link.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTaskLinksDialog(Task task) {
    final taskLinks = widget.links.where((l) => l.source == task.id || l.target == task.id).toList();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${task.title} 的依赖关系'),
        content: taskLinks.isEmpty
            ? const Text('没有依赖关系')
            : SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: taskLinks.length,
                  itemBuilder: (context, index) {
                    final link = taskLinks[index];
                    final isSource = link.source == task.id;
                    final otherTaskId = isSource ? link.target : link.source;
                    final otherTask = widget.tasks.firstWhere(
                      (t) => t.id == otherTaskId,
                      orElse: () => Task(id: -1, title: '未知任务'),
                    );
                    
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GanttLinkPainter.getLinkColor(link.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          link.typeShort,
                          style: TextStyle(
                            color: GanttLinkPainter.getLinkColor(link.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        isSource ? '→ ${otherTask.title}' : '← ${otherTask.title}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(isSource ? '前置' : '后置', style: const TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onLinkDelete?.call(link.id);
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showLinkTypeDialog(int sourceId, int targetId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择依赖类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLinkTypeOption(ctx, sourceId, targetId, '0', 'FS', '完成-开始', '前置任务完成后，后置任务才能开始'),
            const Divider(),
            _buildLinkTypeOption(ctx, sourceId, targetId, '1', 'SS', '开始-开始', '两个任务同时开始'),
            const Divider(),
            _buildLinkTypeOption(ctx, sourceId, targetId, '2', 'FF', '完成-完成', '两个任务同时完成'),
            const Divider(),
            _buildLinkTypeOption(ctx, sourceId, targetId, '3', 'SF', '开始-完成', '前置任务开始后，后置任务才能完成'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _linkSourceTaskId = null);
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTypeOption(BuildContext ctx, int sourceId, int targetId, String type, String short, String name, String desc) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(short, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
      ),
      title: Text(name),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
      onTap: () {
        Navigator.pop(ctx);
        widget.onLinkCreate?.call(sourceId, targetId, type);
        setState(() => _linkSourceTaskId = null);
      },
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size(_totalDays * _dayWidth, widget.tasks.length * _rowHeight),
      painter: _GridPainter(
        dayWidth: _dayWidth,
        rowHeight: _rowHeight,
        totalDays: _totalDays,
        totalRows: widget.tasks.length,
        startDate: _startDate,
      ),
    );
  }

  Widget _buildTodayLine() {
    final today = DateTime.now();
    final daysSinceStart = today.difference(_startDate).inDays;

    if (daysSinceStart < 0 || daysSinceStart > _totalDays) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: daysSinceStart * _dayWidth + (_dayWidth / 2),
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        color: Theme.of(context).primaryColor.withOpacity(0.7),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _timelineController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}

class _GridPainter extends CustomPainter {
  final double dayWidth;
  final double rowHeight;
  final int totalDays;
  final int totalRows;
  final DateTime startDate;

  _GridPainter({
    required this.dayWidth,
    required this.rowHeight,
    required this.totalDays,
    required this.totalRows,
    required this.startDate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use fixed low-opacity colors for grid lines to work on both backgrounds
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    final weekendPaint = Paint()..color = Colors.grey.withOpacity(0.05);

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        canvas.drawRect(
          Rect.fromLTWH(i * dayWidth, 0, dayWidth, size.height),
          weekendPaint,
        );
      }
    }

    for (int i = 0; i <= totalDays; i++) {
      canvas.drawLine(
        Offset(i * dayWidth, 0),
        Offset(i * dayWidth, size.height),
        paint,
      );
    }

    for (int i = 0; i <= totalRows; i++) {
      canvas.drawLine(
        Offset(0, i * rowHeight),
        Offset(size.width, i * rowHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
