import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class TeamChatScreen extends StatefulWidget {
  final int teamId;
  const TeamChatScreen({super.key, required this.teamId});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initSocket();
  }

  void _initSocket() {
    SocketService.instance.init();
    SocketService.instance.joinTeam(widget.teamId);
    SocketService.instance.onMessage((data) {
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final res = await ApiService.instance.get('/teams/${widget.teamId}/messages');
      if (mounted) {
        setState(() { _messages = res.data ?? []; _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    try {
      SocketService.instance.sendMessage(widget.teamId, _messageController.text);
      _messageController.clear();
      // Message will be added via socket listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) return const Center(child: Text('暂无消息'));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageItem(msg);
      },
    );
  }

  Widget _buildMessageItem(dynamic msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text((msg['nickname'] ?? 'U')[0].toUpperCase()),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg['nickname'] ?? '用户', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(msg['content'] ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService.instance.offMessage();
    SocketService.instance.leaveTeam(widget.teamId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
