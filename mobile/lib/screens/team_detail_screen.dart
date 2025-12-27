import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/team_provider.dart';
import '../providers/project_provider.dart';
import '../models/team.dart';
import '../widgets/dynamic_bottom_nav.dart';
import 'project_screen.dart';
import 'team_members_screen.dart';
import 'team_calendar_screen.dart';
import 'team_resources_screen.dart';
import 'team_timeline_screen.dart';
import 'team_learning_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'team_chat_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  int _currentIndex = 0;
  Team? _team;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.folder, label: '项目', key: 'projects'),
    NavItem(icon: Icons.people, label: '成员', key: 'members'),
    NavItem(icon: Icons.calendar_today, label: '日程', key: 'calendar'),
    NavItem(icon: Icons.chat, label: '聊天', key: 'chat'),
  ];

  final List<_MoreMenuItem> _moreItems = const [
    _MoreMenuItem(icon: Icons.folder_shared, label: '资源分享', key: 'resources'),
    _MoreMenuItem(icon: Icons.timeline, label: '成果记录', key: 'timeline'),
    _MoreMenuItem(icon: Icons.school, label: '学习进度', key: 'learning'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTeamInfo();
  }

  Future<void> _loadTeamInfo() async {
    final team = await Provider.of<TeamProvider>(context, listen: false)
        .getTeamById(widget.teamId);
    if (mounted) setState(() => _team = team);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: DynamicBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onMoreTap: _showMoreMenu,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_team?.name ?? '团队'),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code, size: 28),
          tooltip: '邀请码',
          onPressed: _showInviteDialog,
        ),
        IconButton(
          icon: Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.error),
          tooltip: '退出团队',
          onPressed: _confirmLeaveTeam,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'create_project', child: Text('新建项目')),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ProjectScreen(teamId: widget.teamId);
      case 1:
        return TeamMembersScreen(teamId: widget.teamId);
      case 2:
        return TeamCalendarScreen(teamId: widget.teamId);
      case 3:
        return TeamChatScreen(teamId: widget.teamId);
      default:
        return ProjectScreen(teamId: widget.teamId);
    }
  }

  void _showInviteDialog() {
    final code = _team?.inviteCode ?? '暂无邀请码';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('团队邀请码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text('扫描二维码或使用代码加入团队', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('复制'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('邀请码已复制')),
              );
              Navigator.pop(context);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'create_project':
        _showCreateProjectDialog();
        break;
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _moreItems.map((item) => ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context);
              _navigateToMore(item.key);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _navigateToMore(String key) {
    Widget screen;
    switch (key) {
      case 'resources':
        screen = TeamResourcesScreen(teamId: widget.teamId);
        break;
      case 'timeline':
        screen = TeamTimelineScreen(teamId: widget.teamId);
        break;
      case 'learning':
        screen = TeamLearningScreen(teamId: widget.teamId);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建项目'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '项目名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await Provider.of<ProjectProvider>(context, listen: false)
                    .createProject(widget.teamId, nameController.text, '');
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveTeam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出团队'),
        content: const Text('确定要退出这个团队吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await Provider.of<TeamProvider>(context, listen: false).leaveTeam(widget.teamId);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text('退出', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem {
  final IconData icon;
  final String label;
  final String key;
  const _MoreMenuItem({required this.icon, required this.label, required this.key});
}
