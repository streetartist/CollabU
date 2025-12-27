import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';

class TeamTimelineScreen extends StatefulWidget {
  final int teamId;
  const TeamTimelineScreen({super.key, required this.teamId});

  @override
  State<TeamTimelineScreen> createState() => _TeamTimelineScreenState();
}

class _TeamTimelineScreenState extends State<TeamTimelineScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.get('/timeline/team/${widget.teamId}');
      if (mounted) setState(() { _items = res.data ?? []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成果记录')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 继续...

  Widget _buildBody() {
    if (_items.isEmpty) {
      return const Center(child: Text('暂无成果记录'));
    }
    return RefreshIndicator(
      onRefresh: _loadTimeline,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildTimelineItem(item, index == _items.length - 1);
        },
      ),
    );
  }

  // 继续2...

  Widget _buildTimelineItem(dynamic item, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
            ),
            if (!isLast) Container(width: 2, height: 100, color: Theme.of(context).dividerColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item['event_date'] ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                  if (item['description'] != null && item['description'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MarkdownBody(data: item['description'], selectable: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 继续3...

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('添加成果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述 (Markdown)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('日期: ${selectedDate.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setSheetState(() => selectedDate = date);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitTimeline(titleCtrl.text, descCtrl.text, selectedDate),
                child: const Text('保存'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 继续4...

  Future<void> _submitTimeline(String title, String desc, DateTime date) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    try {
      await ApiService.instance.post('/timeline', data: {
        'team_id': widget.teamId,
        'title': title,
        'description': desc,
        'event_date': date.toIso8601String().substring(0, 10),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加成功')),
        );
        _loadTimeline();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加失败')),
        );
      }
    }
  }
}
