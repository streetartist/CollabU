import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/common/gradient_card.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamProvider>(context, listen: false).fetchTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的团队'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: '使用邀请码加入',
            onPressed: () => _showJoinTeamDialog(context),
          ),
        ],
      ),
      body: Consumer<TeamProvider>(
        builder: (context, teamProvider, child) {
          if (teamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (teamProvider.error != null) {
            return Center(child: Text('Error: ${teamProvider.error}'));
          }

          if (teamProvider.teams.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => teamProvider.fetchTeams(),
            child: ListView.builder(
              itemCount: teamProvider.teams.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final team = teamProvider.teams[index];
                return _buildTeamItem(context, team);
              },
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: FloatingActionButton(
          onPressed: () => _showJoinOrCreateDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
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
            child: const Icon(Icons.groups, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text('暂无团队', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('创建或加入一个团队开始协作'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showJoinOrCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('创建或加入'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(BuildContext context, Team team) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isCreator = user != null && team.creatorId == user.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/teams/${team.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                                style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                          if (isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '创建者',
                                style: TextStyle(fontSize: 11, color: AppTheme.accentColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                        Text(
                        team.description ?? '暂无描述',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildPopupMenu(team, isCreator),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(Team team, bool isCreator) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditTeamDialog(context, team);
        } else if (value == 'delete') {
          _confirmDeleteTeam(context, team);
        } else if (value == 'leave') {
          _confirmLeaveTeam(context, team);
        }
      },
      itemBuilder: (context) => [
        if (isCreator) ...[
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          PopupMenuItem(
            value: 'delete',
            child: Text('解散团队', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ] else ...[
          PopupMenuItem(
            value: 'leave',
            child: Text('退出团队', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ],
    );
  }

  void _showEditTeamDialog(BuildContext context, Team team) {
    final nameController = TextEditingController(text: team.name);
    final descController = TextEditingController(text: team.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑团队'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '团队名称'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<TeamProvider>(context, listen: false)
                  .updateTeam(team.id, nameController.text, descController.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更新成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更新失败')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeam(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散团队'),
        content: Text('确定要解散 "${team.name}" 吗？此操作无法撤销，所有项目和任务将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<TeamProvider>(context, listen: false)
                  .deleteTeam(team.id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('团队已解散')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('操作失败')),
                  );
                }
              }
            },
            child: Text('解散', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveTeam(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出团队'),
        content: Text('确定要退出 "${team.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<TeamProvider>(context, listen: false)
                  .leaveTeam(team.id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出团队')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('退出失败')),
                  );
                }
              }
            },
            child: Text('退出', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showJoinOrCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入或创建团队'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('加入团队'),
              onTap: () {
                Navigator.pop(context);
                _showJoinTeamDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create),
              title: const Text('创建团队'),
              onTap: () {
                Navigator.pop(context);
                _showCreateTeamDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinTeamDialog(BuildContext context) {
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
                _showQRScanner(context);
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

  void _showQRScanner(BuildContext context) {
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

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建团队'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '团队名称'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<TeamProvider>(context, listen: false)
                  .createTeam(nameController.text, descController.text);
              if (mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Provider.of<TeamProvider>(context, listen: false).error ?? '创建失败')),
                  );
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
