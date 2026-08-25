import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/chat_models.dart';
import '../../services/ai_chat_service.dart';
import '../../services/finance_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;

  const ChatDetailScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late AIChatService _chatService;
  Future<List<String>>? _promptFuture;
  bool _showSuggestions = true;
  late final stt.SpeechToText _speechToText;
  late final FlutterTts _tts;
  bool _isListening = false;
  bool _voiceRepliesEnabled = true;
  String? _lastSpokenMessageId;

  @override
  void initState() {
    super.initState();
    final financeService = Provider.of<FinanceService>(context, listen: false);
    _chatService = AIChatService(financeService, widget.title);
    _promptFuture = _chatService.fetchDynamicPrompts(widget.title);

    _speechToText = stt.SpeechToText();
    _tts = FlutterTts();
    _tts.setLanguage('en-IN');
    _tts.setSpeechRate(0.6);
    _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    _tts.stop();
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

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _showSuggestions = false;
    });

    _textController.clear();
    await _chatService.sendMessage(text);
    setState(() {
      _showSuggestions =
          true; // show suggestions again after AI response arrives
    });
    _scrollToBottom();
  }

  void _useSuggestion(String suggestion) {
    _sendMessage(suggestion);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice input'),
        ),
      );
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    _speechToText.listen(
      localeId: 'en_IN',
      onResult: (SpeechRecognitionResult result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _sendMessage(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  String _prepareTextForSpeech(String markdown) {
    var text = markdown;

    // Remove fenced code blocks
    text = text.replaceAll(RegExp(r"```[\s\S]*?```", multiLine: true), '');

    // Inline code: `code` -> code
    text = text.replaceAll(RegExp(r"`([^`]*)`"), r"$1");

    // Convert markdown links [text](url) -> text
    text = text.replaceAll(RegExp(r"\[([^\]]+)\]\([^\)]+\)"), r"$1");

    // Remove markdown headings at start of lines
    text = text.replaceAll(RegExp(r"^\s*#{1,6}\s*", multiLine: true), '');

    // Remove list / quote markers at start of lines (*, -, +, >)
    text = text.replaceAll(RegExp(r"^\s*[*+>-]+\s*", multiLine: true), '');

    // Replace table pipes with spaces
    text = text.replaceAll('|', ' ');

    // Collapse extra whitespace
    text = text.replaceAll(RegExp(r"\s+"), ' ').trim();

    // Optionally limit very long responses
    const maxLength = 600;
    if (text.length > maxLength) {
      text = text.substring(0, maxLength) + '...';
    }

    return text;
  }

  void _handleNewMessagesForTts(List<ChatMessage> messages) {
    if (!_voiceRepliesEnabled) return;
    if (messages.isEmpty) return;

    final aiMessages = messages.where(
      (m) => m.sender == MessageSender.ai && !m.isLoading,
    );
    if (aiMessages.isEmpty) return;

    final lastAi = aiMessages.last;
    if (lastAi.id == _lastSpokenMessageId) return;

    _lastSpokenMessageId = lastAi.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spokenText = _prepareTextForSpeech(lastAi.text);
      if (spokenText.isNotEmpty) {
        _speak(spokenText);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.iconBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _voiceRepliesEnabled ? Icons.volume_up : Icons.volume_off,
            ),
            onPressed: () {
              setState(() {
                _voiceRepliesEnabled = !_voiceRepliesEnabled;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Clear Chat'),
                      content: const Text(
                        'Are you sure you want to clear all messages in this chat?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _chatService.clearChat();
                            Navigator.pop(context);
                            setState(() {
                              _showSuggestions = true;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListenableBuilder(
              listenable: _chatService,
              builder: (context, child) {
                final messages = _chatService.messages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Start chatting with your financial AI assistant!",
                    ),
                  );
                }

                _scrollToBottom();
                _handleNewMessagesForTts(messages);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Suggestions
          if (_showSuggestions && !_chatService.isGenerating)
            FutureBuilder<List<String>>(
              future: _promptFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return _SuggestionChips(
                  suggestions: snapshot.data!,
                  onSelected: _useSuggestion,
                );
              },
            ),

          // Input field pinned to bottom with safe area
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask me about your finances...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: widget.iconBg,
                    ),
                    onPressed: _toggleListening,
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: widget.iconBg,
                    onPressed: () => _sendMessage(_textController.text),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final time = DateFormat.jm().format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUser
                            ? Theme.of(context).primaryColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft:
                          isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(0),
                      bottomRight:
                          !isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(0),
                    ),
                  ),
                  child:
                      message.isLoading
                          ? _buildLoadingIndicator()
                          : isUser
                          ? Text(
                            message.text,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          )
                          : MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: TextStyle(
                                fontSize: 16,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                            onTapLink: (text, href, title) {
                              // TODO: handle links if needed
                            },
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(message.text),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      child: Center(
        child: Icon(Icons.assistant, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(Icons.person, color: Colors.white, size: 20)),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelected;

  const _SuggestionChips({required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(suggestions[index]),
            labelStyle: TextStyle(fontSize: 12),
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
            onPressed: () => onSelected(suggestions[index]),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}
