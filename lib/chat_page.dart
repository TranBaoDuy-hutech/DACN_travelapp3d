import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shimmer/shimmer.dart';

class ChatPage extends StatefulWidget {
  final int customerId;
  final String? customerName;

  const ChatPage({super.key, required this.customerId, this.customerName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late WebSocketChannel channel;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> pendingMessages = [];
  bool isLoading = true;
  bool isSendingMessage = false;
  String? errorMessage;
  late AnimationController _animationController;
  late AnimationController _typingController;
  bool isTyping = false;

  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    fetchChatHistory();
    connectWebSocket();
  }

  Future<void> fetchChatHistory() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://127.0.0.1:8000/chat/history/${widget.customerId}');
    try {
      final res = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['chat'];
        setState(() {
          messages = List<Map<String, dynamic>>.from(data);
          isLoading = false;
          errorMessage = null;
          _animationController.forward(from: 0);
        });
        _scrollToBottom();
      } else {
        throw Exception('Lỗi khi tải lịch sử chat: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi: ${e.toString()}';
      });
    }
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8000/ws/chat/${widget.customerId}'),
    );

    channel.stream.listen(
          (msg) {
        Map<String, dynamic> message;
        try {
          message = jsonDecode(msg);
        } catch (e) {
          message = {
            'Content': msg.toString(),
            'IsFromAdmin': true,
            'CreatedAt': DateTime.now().toIso8601String(),
            'MessageID': null,
          };
        }

        if (message['CustomerID'] == widget.customerId) {
          setState(() {
            final messageId = message['MessageID'];
            if (messageId != null && !messages.any((m) => m['MessageID'] == messageId)) {
              messages.add(message);
            }
            pendingMessages.removeWhere((pending) => pending['Content'] == message['Content']);
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        setState(() => errorMessage = 'Lỗi kết nối: $error');
      },
      onDone: () {
        setState(() => errorMessage = 'Kết nối đã đóng');
      },
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || isSendingMessage) return;

    final content = _controller.text.trim();
    setState(() => isSendingMessage = true);

    final msg = {
      'CustomerID': widget.customerId,
      'Content': content,
      'IsFromAdmin': false,
      'CreatedAt': DateTime.now().toIso8601String(),
      'MessageID': null,
    };

    try {
      channel.sink.add(jsonEncode(msg));
      setState(() {
        pendingMessages.add({...msg, 'IsPending': true});
        _controller.clear();
      });
    } catch (e) {
      setState(() => errorMessage = 'Lỗi gửi tin nhắn: $e');
    } finally {
      setState(() => isSendingMessage = false);
    }

    _scrollToBottom();
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

  @override
  void dispose() {
    channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Widget _buildShimmerMessage(double maxWidth, bool isAdmin) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isAdmin ? 4 : 20),
                bottomRight: Radius.circular(isAdmin ? 20 : 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(width: 150, height: 14, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 50, height: 10, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final maxMessageWidth = screenW * 0.75;
    final allMessages = [...messages, ...pendingMessages];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: deepOcean,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: lightOcean,
                child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName ?? "Việt Lữ Travel",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    errorMessage != null ? "Offline" : "Đang hoạt động",
                    style: TextStyle(
                      color: errorMessage != null
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: fetchChatHistory,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [deepOcean, oceanBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: isLoading
                ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) =>
                  _buildShimmerMessage(maxMessageWidth, index % 2 == 0),
            )
                : errorMessage != null && allMessages.isEmpty
                ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: fetchChatHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Thử lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oceanBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : allMessages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: oceanBlue.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: oceanBlue.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Chưa có tin nhắn nào",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Gửi tin nhắn đầu tiên để bắt đầu trò chuyện!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              itemCount: allMessages.length,
              itemBuilder: (context, index) {
                final msg = allMessages[index];
                final isAdmin = msg['IsFromAdmin'] ?? false;
                final isPending = msg['IsPending'] ?? false;
                final timestamp = msg['CreatedAt'] != null
                    ? DateTime.parse(msg['CreatedAt']).toLocal()
                    : DateTime.now();

                // Animation cho mỗi tin nhắn
                return TweenAnimationBuilder<double>(
                  duration: Duration(
                    milliseconds: 300 + (index * 50),
                  ),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isAdmin
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAdmin) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: oceanBlue,
                            child: const Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: maxMessageWidth,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isAdmin
                                  ? null
                                  : LinearGradient(
                                colors: isPending
                                    ? [
                                  oceanBlue.withOpacity(0.4),
                                  lightOcean.withOpacity(0.4),
                                ]
                                    : [oceanBlue, lightOcean],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              color: isAdmin ? Colors.white : null,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(
                                  isAdmin ? 4 : 20,
                                ),
                                bottomRight: Radius.circular(
                                  isAdmin ? 20 : 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isAdmin
                                      ? Colors.black.withOpacity(0.05)
                                      : oceanBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isAdmin
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg['Content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isAdmin
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAdmin
                                            ? Colors.grey[500]
                                            : Colors.white70,
                                      ),
                                    ),
                                    if (!isAdmin) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        isPending
                                            ? Icons.access_time
                                            : Icons.done_all,
                                        size: 14,
                                        color: isPending
                                            ? Colors.white60
                                            : Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isAdmin) const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.grey[400],
                              size: 22,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: isSendingMessage ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [oceanBlue, lightOcean],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: oceanBlue.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSendingMessage
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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