import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/gradient_card.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/item_card.dart';
import '../widgets/common/quick_action_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentTasks = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 加载团队
      await Provider.of<TeamProvider>(context, listen: false).fetchTeams();

      // 加载统计数据
      final statsRes = await ApiService.instance.get('/dashboard/stats');
      if (statsRes.statusCode == 200) {
        _stats = statsRes.data;
      }

      // 加载最近任务
      final tasksRes = await ApiService.instance.get('/dashboard/recent-tasks');
      if (tasksRes.statusCode == 200) {
        _recentTasks = tasksRes.data ?? [];
      }

      // 加载通知
      final notifRes = await ApiService.instance.get('/notifications');
      if (notifRes.statusCode == 200) {
        _notifications = (notifRes.data ?? []).take(5).toList();
      }
    } catch (e) {
      // 使用本地数据
      final teams = Provider.of<TeamProvider>(context, listen: false).teams;
      _stats = {'teams': teams.length, 'projects': 0, 'tasks': 0, 'completed': 0};
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final teams = context.watch<TeamProvider>().teams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CollabU'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(),
          ),
        ],
      ),
      drawer: _buildDrawer(user),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(user),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentTeams(teams),
                    const SizedBox(height: 24),
                    _buildRecentTasks(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic user) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? '早上好' : (hour < 18 ? '下午好' : '晚上好');

    return GradientCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Text(
                (user?.nickname ?? user?.username ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting!',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.nickname ?? user?.username ?? '用户',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.0,
        children: [
          StatCard(
            title: '团队',
            value: '${_stats['teams'] ?? 0}',
            icon: Icons.groups,
            color: AppTheme.info,
          ),
          StatCard(
            title: '项目',
            value: '${_stats['projects'] ?? 0}',
            icon: Icons.folder,
            color: AppTheme.warning,
          ),
          StatCard(
            title: '任务',
            value: '${_stats['tasks'] ?? 0}',
            icon: Icons.task_alt,
            color: AppTheme.primaryColor,
          ),
          StatCard(
            title: '已完成',
            value: '${_stats['completed'] ?? 0}',
            icon: Icons.check_circle,
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '快捷操作', icon: Icons.flash_on),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  label: '我的团队',
                  icon: Icons.groups,
                  color: AppTheme.info,
                  onTap: () => context.push('/teams'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  label: '个人资料',
                  icon: Icons.person,
                  color: AppTheme.accentColor,
                  onTap: () => context.push('/profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTeams(List teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '我的团队',
          icon: Icons.groups,
          actionText: '查看全部',
          onAction: () => context.push('/teams'),
        ),
        if (teams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Center(child: Text('暂无团队', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
            ),
          )
        else
          ...teams.take(3).map((team) => ItemCard(
            title: team.name,
            subtitle: team.description ?? '暂无描述',
            leadingIcon: Icons.groups,
            leadingColor: AppTheme.primaryColor,
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
            onTap: () => context.push('/teams/${team.id}'),
          )),
      ],
    );
  }

  Widget _buildRecentTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '待办任务', icon: Icons.task_alt),
        if (_recentTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Center(child: Text('暂无待办任务', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
            ),
          )
        else
          ..._recentTasks.take(5).map((task) => ItemCard(
            title: task['title'] ?? '',
            subtitle: task['project_name'] ?? '',
            leadingIcon: task['status'] == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
            leadingColor: task['status'] == 'completed' ? AppTheme.success : AppTheme.textHint,
            trailing: _buildPriorityBadge(task['priority']),
          )),
      ],
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color = AppTheme.textHint;
    String label = '普通';
    if (priority == 'high') { color = AppTheme.error; label = '高'; }
    if (priority == 'low') { color = AppTheme.success; label = '低'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildDrawer(dynamic user) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.username ?? 'U')[0].toUpperCase(),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.nickname ?? user?.username ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(Icons.dashboard, '仪表盘', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.group, '团队', () { Navigator.pop(context); context.push('/teams'); }),
                _buildDrawerItem(Icons.group_add, '加入团队', () { Navigator.pop(context); _showJoinTeamDialog(); }),
                _buildDrawerItem(Icons.person, '个人资料', () { Navigator.pop(context); context.push('/profile'); }),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildDrawerItem(Icons.logout, '退出登录', () => context.read<AuthProvider>().logout(), isDestructive: true),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.error : Theme.of(context).iconTheme.color),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.error : Theme.of(context).textTheme.bodyMedium?.color)),
      onTap: onTap,
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                   const Text('通知中心', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   if (_notifications.isNotEmpty)
                     TextButton(
                       onPressed: () {}, // TODO: Mark all read
                       child: const Text('全部已读'),
                     ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _notifications.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('暂无通知', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['content'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinTeamDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加入团队'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '邀请码',
                hintText: '输入8位邀请码',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showQRScanner();
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫描二维码'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final success = await Provider.of<TeamProvider>(context, listen: false)
                  .joinTeam(controller.text);
              if (mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('成功加入团队')),
                  );
                  _loadDashboardData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Provider.of<TeamProvider>(context, listen: false).error ?? '加入失败')),
                  );
                }
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: const Text('扫描邀请码', style: TextStyle(color: Colors.white)),
              centerTitle: true,
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null && code.isNotEmpty) {
                      Navigator.pop(ctx);
                      final success = await Provider.of<TeamProvider>(context, listen: false)
                          .joinTeam(code);
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('成功加入团队')),
                          );
                          _loadDashboardData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(Provider.of<TeamProvider>(context, listen: false).error ?? '加入失败')),
                          );
                        }
                      }
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '将二维码放入框内扫描',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
