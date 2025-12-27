import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProjectGanttChart extends StatelessWidget {
  final List<Project> projects;

  const ProjectGanttChart({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Center(child: Text('暂无项目数据'));
    }

    // Sort projects by start date
    final sortedProjects = List<Project>.from(projects)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.startDate ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b.startDate ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            ...sortedProjects.map((p) => _buildProjectRow(context, p)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        children: [
          SizedBox(width: 150, child: Text('项目名称', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color))),
          SizedBox(width: 100, child: Text('状态', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color))),
          SizedBox(width: 200, child: Text('时间轴', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color))),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, Project project) {
    final start = DateTime.tryParse(project.startDate ?? '');
    final end = DateTime.tryParse(project.endDate ?? '');
    final hasDates = start != null && end != null;
    
    String dateRange = '未设置日期';
    if (hasDates) {
      dateRange = '${DateFormat('MM/dd').format(start)} - ${DateFormat('MM/dd').format(end)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              (project.name ?? 'Untitled').toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(project.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (project.status ?? 'active').toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: hasDates
                ? _buildBar(context, start, end)
                : Text(
                    dateRange,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, DateTime start, DateTime end) {
    // This is a simplified "bar" visualization
    // In a real Gantt, we'd map dates to X-coordinates.
    // Here we just show a visual bar and the text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          width: 100, // Fixed width for demo, ideally calculated based on duration
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        Text(
          '${DateFormat('MM/dd').format(start)} - ${DateFormat('MM/dd').format(end)}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active': return Colors.green.shade100;
      case 'completed': return Colors.blue.shade100;
      case 'archived': return Colors.grey.shade100;
      default: return Colors.grey.shade200;
    }
  }
}
