import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/gemma_service.dart';
import '../widgets/analysis_card.dart';

class ChatProvider extends ChangeNotifier {
  final GemmaService _gemma = GemmaService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _modelReady = false;
  String _statusText = 'Initializing...';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get modelReady => _modelReady;
  String get statusText => _statusText;

  Future<void> initialize() async {
    try {
      await _gemma.initialize(
        onStatus: (status) {
          _statusText = status;
          notifyListeners();
        },
      );
      _modelReady = true;
      notifyListeners();
    } catch (e) {
      _statusText = 'Init failed: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text, {String? imagePath}) async {
    if (text.trim().isEmpty && imagePath == null) return;
    if (_isLoading) return;

    final imageBytes =
        imagePath != null ? await File(imagePath).readAsBytes() : null;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim().isEmpty ? '[Image attached]' : text.trim(),
      isUser: true,
      imageBytes: imageBytes,
    );
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _gemma.generateResponse(
        text.trim().isEmpty ? 'Analyze this image for security threats.' : text,
        imageBytes: imageBytes,
      );

      AnalysisResult? analysis;
      try {
        final json = jsonDecode(_extractJson(response)) as Map<String, dynamic>;
        analysis = AnalysisResult.fromJson(json);
      } catch (_) {
        analysis = AnalysisResult.fromRawText(response);
      }

      final botMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        analysis: analysis,
      );
      _messages.add(botMsg);
    } catch (e) {
      final botMsg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: 'Error: $e',
        isUser: false,
        analysis: AnalysisResult(
          threatLevel: ThreatLevel.unknown,
          summary: 'Failed to generate analysis: $e',
          keyFindings: const [],
          mitigations: const [],
        ),
      );
      _messages.add(botMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  @override
  void dispose() {
    _gemma.dispose();
    super.dispose();
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider()..initialize(),
      child: const _ChatBody(),
    );
  }
}

class _ChatBody extends StatefulWidget {
  const _ChatBody();

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    final provider = context.read<ChatProvider>();
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xfile != null) {
      await provider.sendMessage(_controller.text, imagePath: xfile.path);
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text(
              'GemmaGuard',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: provider.modelReady
                    ? Colors.green.withAlpha(25)
                    : Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.modelReady ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.modelReady
                        ? Icons.check_circle
                        : Icons.hourglass_top,
                    size: 16,
                    color: provider.modelReady
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.modelReady ? 'Ready' : 'Loading',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: provider.modelReady
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!provider.modelReady)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.statusText,
                      style: TextStyle(
                          fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildChatList(provider)),
          _buildInputBar(provider),
        ],
      ),
    );
  }

  Widget _buildChatList(ChatProvider provider) {
    if (provider.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'GemmaGuard is ready.\nType a message or attach an image\nfor security analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Analyzing...',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        final msg = provider.messages[index];
        return _buildMessage(msg);
      },
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isUser)
            _buildUserBubble(msg)
          else
            _buildBotBubble(msg),
        ],
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(msg.imageBytes!,
                    width: 200, height: 200, fit: BoxFit.cover),
              ),
            if (msg.hasImage) const SizedBox(height: 8),
            if (msg.text.isNotEmpty)
              Text(msg.text, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotBubble(ChatMessage msg) {
    if (msg.analysis != null) {
      return ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
        child: AnalysisCard(analysis: msg.analysis!),
      );
    }
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(msg.text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () => _showImageSourceDialog(),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: provider.modelReady,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: provider.modelReady
                      ? 'Describe a security concern...'
                      : 'Waiting for model...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed:
                  provider.modelReady && !provider.isLoading ? _send : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
