import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../widgets/markdown_editor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';

class TeamResourcesScreen extends StatefulWidget {
  final int teamId;
  const TeamResourcesScreen({super.key, required this.teamId});

  @override
  State<TeamResourcesScreen> createState() => _TeamResourcesScreenState();
}

class _TeamResourcesScreenState extends State<TeamResourcesScreen> {
  List<dynamic> _resources = [];
  bool _isLoading = true;
  String _viewMode = 'list'; // list, detail, edit
  dynamic _selectedResource;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.get('/resources', queryParameters: {'team_id': widget.teamId});
      if (mounted) {
        setState(() {
          _resources = (res.data ?? []).map((r) {
            // Pre-process content to fix HTML images
            if (r['content'] != null && r['content'] is String) {
              r['content'] = _fixHtmlImages(r['content']);
            }
            return r;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fixHtmlImages(String content) {
    // Replace <img ... src="..." ...> with ![](...)
    // Simple regex for basic cases
    final RegExp imgTag = RegExp(r'<img[^>]+src="([^">]+)"[^>]*>');
    return content.replaceAllMapped(imgTag, (match) {
      final src = match.group(1);
      return '![]($src)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _viewMode == 'list' ? FloatingActionButton(
        onPressed: () => setState(() { _viewMode = 'edit'; _selectedResource = null; }),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  // 继续...

  AppBar _buildAppBar() {
    String title = '资源分享';
    if (_viewMode == 'detail') title = _selectedResource?['title'] ?? '详情';
    if (_viewMode == 'edit') title = _selectedResource == null ? '新建资源' : '编辑资源';

    return AppBar(
      title: Text(title),
      leading: _viewMode != 'list' ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() { _viewMode = 'list'; _selectedResource = null; }),
      ) : null,
      actions: _viewMode == 'detail' ? [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => setState(() => _viewMode = 'edit'),
        ),
      ] : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    switch (_viewMode) {
      case 'detail': return _buildDetailView();
      case 'edit': return _buildEditView();
      default: return _buildListView();
    }
  }

  // 继续2...

  Widget _buildListView() {
    if (_resources.isEmpty) {
      return const Center(child: Text('暂无资源，点击右下角添加'));
    }
    return RefreshIndicator(
      onRefresh: _loadResources,
      child: ListView.builder(
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final res = _resources[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.article),
              title: Text(res['title'] ?? ''),
              subtitle: Text(res['updated_at']?.toString().substring(0, 10) ?? ''),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => _confirmDelete(res['id']),
              ),
              onTap: () => setState(() { _viewMode = 'detail'; _selectedResource = res; }),
            ),
          );
        },
      ),
    );
  }

  // 继续3...

  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedResource?['title'] ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '更新于 ${_selectedResource?['updated_at']?.toString().substring(0, 10) ?? ''}',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const Divider(height: 24),
          MarkdownBody(
            data: _selectedResource?['content'] ?? '',
            selectable: true,
            onTapLink: (text, href, title) async {
              if (href != null) {
                String fullUrl = href;
                if (!href.startsWith('http')) {
                  // Fix double /api issue: if href starts with /api/files/, strip /api prefix from it 
                  // OR just construct using baseUrl without potential double path.
                  // Simpler: If href starts with /api and baseUrl ends with /api, remove one.
                  String baseUrl = ApiService.baseUrl;
                  if (href.startsWith('/api/') && baseUrl.endsWith('/api')) {
                    fullUrl = '${baseUrl.substring(0, baseUrl.length - 4)}$href';
                  } else {
                     fullUrl = '${baseUrl}${href.startsWith('/') ? '' : '/'}$href';
                  }
                }
                
                // If it's a file from our API, download and open it
                if (fullUrl.contains('/api/files/')) {
                  await _downloadAndOpenFile(fullUrl, text);
                } else {
                   final Uri uri = Uri.parse(fullUrl);
                   if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              }
            },
            imageBuilder: (uri, title, alt) {
              String imageUrl = uri.toString();
              if (uri.scheme.isEmpty) {
                 String baseUrl = ApiService.baseUrl;
                  if (imageUrl.startsWith('/api/') && baseUrl.endsWith('/api')) {
                    imageUrl = '${baseUrl.substring(0, baseUrl.length - 4)}$imageUrl';
                  } else {
                     imageUrl = '${baseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
                  }
              }
              
              // Use headers for auth
              final token = Provider.of<AuthProvider>(context, listen: false).token;
              
              return Image.network(
                imageUrl,
                headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: Theme.of(context).disabledColor),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String filename) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading...')));
      
      // Extract filename
      String saveName = filename;
      if (saveName.isEmpty || saveName.contains('/')) {
        saveName = url.split('/').last;
        if (saveName.contains('?')) saveName = saveName.split('?').first;
      }

      if (kIsWeb) {
        // Web download logic
        final response = await ApiService.instance.dio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final blob = html.Blob([response.data]);
        final urlObj = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: urlObj)
          ..setAttribute("download", saveName)
          ..click();
        html.Url.revokeObjectUrl(urlObj);
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started')));
      } else {
        // Mobile/Desktop logic
        final dir = await getApplicationDocumentsDirectory();
        final savePath = '${dir.path}/$saveName';
        
        await ApiService.instance.dio.download(url, savePath);
        
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open file: ${result.message}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }


  // 继续4...

  Widget _buildEditView() {
    final titleCtrl = TextEditingController(text: _selectedResource?['title'] ?? '');
    final editorKey = GlobalKey<_MarkdownEditorPageState>();

    return _MarkdownEditorPage(
      key: editorKey,
      initialTitle: _selectedResource?['title'] ?? '',
      initialContent: _selectedResource?['content'] ?? '',
      onSave: (title, content) => _saveResource(title, content),
    );
  }

  Future<void> _saveResource(String title, String content) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }
    try {
      if (_selectedResource == null) {
        await ApiService.instance.post('/resources', data: {
          'team_id': widget.teamId,
          'title': title,
          'content': content,
        });
      } else {
        await ApiService.instance.put('/resources/${_selectedResource['id']}', data: {
          'title': title,
          'content': content,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        setState(() { _viewMode = 'list'; _selectedResource = null; });
        _loadResources();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个资源吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.delete('/resources/$id');
                _loadResources();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
              }
            },
            child: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _MarkdownEditorPage extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final Function(String, String) onSave;

  const _MarkdownEditorPage({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<_MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<_MarkdownEditorPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _contentCtrl = TextEditingController(text: widget.initialContent);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: MarkdownEditor(
            initialContent: widget.initialContent,
            onChanged: (content) => _contentCtrl.text = content,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_titleCtrl.text, _contentCtrl.text),
              child: const Text('保存'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }
}
