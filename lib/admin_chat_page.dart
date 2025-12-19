import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:intl/intl.dart';
import 'admin_analysis_page.dart';

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({super.key});

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const String wsUrl = "ws://127.0.0.1:8000";

  List customers = [];
  List messages = [];
  int? selectedCustomerId;
  String? selectedCustomerName;
  WebSocketChannel? channel;
  TextEditingController msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<int, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/admin/chat/customers"));
      if (res.statusCode == 200) {
        setState(() {
          customers = jsonDecode(res.body);
        });
        await fetchUnreadCounts();
      } else {
        print("Lỗi load customers: ${res.statusCode}");
      }
    } catch (e) {
      print("Lỗi load customers: $e");
    }
  }

  Future<void> fetchUnreadCounts() async {
    try {
      for (var c in customers) {
        final id = c['CustomerID'];
        final unreadRes = await http.get(Uri.parse("$baseUrl/chat/unread/$id"));
        if (unreadRes.statusCode == 200) {
          final msgs = jsonDecode(unreadRes.body);
          unreadCounts[id] = msgs.length;
        } else {
          unreadCounts[id] = 0;
        }
      }
      setState(() {});
    } catch (e) {
      print("Lỗi lấy unread count: $e");
    }
  }

  Future<void> fetchMessages(int customerId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/chat/history/$customerId"));
      if (res.statusCode == 200) {
        setState(() {
          messages = jsonDecode(res.body)["chat"];
        });
        await http.post(Uri.parse("$baseUrl/chat/mark-read/$customerId"));
        unreadCounts[customerId] = 0;
        setState(() {});
        // Cuộn xuống cuối khi tải tin nhắn
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else {
        print("Lỗi load messages: ${res.statusCode}");
      }
    } catch (e) {
      print("Lỗi load messages: $e");
    }
  }

  void connectWebSocket(int customerId) {
    channel?.sink.close();
    channel = WebSocketChannel.connect(
      Uri.parse("$wsUrl/ws/chat/$customerId"),
    );

    channel!.stream.listen((data) {
      final msg = jsonDecode(data);
      setState(() {
        messages.add(msg);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });

      if (msg['IsFromAdmin'] == false &&
          selectedCustomerId != msg['CustomerID']) {
        unreadCounts[msg['CustomerID']] =
            (unreadCounts[msg['CustomerID']] ?? 0) + 1;
        setState(() {});
      }
    });
  }

  void selectCustomer(int id, String name) {
    setState(() {
      selectedCustomerId = id;
      selectedCustomerName = name;
      messages = [];
    });
    fetchMessages(id);
    connectWebSocket(id);
  }

  void sendMessage() {
    if (msgController.text.isEmpty || channel == null) return;
    final msg = {
      "Content": msgController.text,
      "IsFromAdmin": true,
      "CustomerID": selectedCustomerId,
      "UserID": 1,
    };
    channel!.sink.add(jsonEncode(msg));
    msgController.clear();
  }

  String formatTime(String time) {
    final dateTime = DateTime.parse(time);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  Widget _buildQuickReply(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          msgController.text = text;
          sendMessage();
        },
        backgroundColor: Colors.blue[100],
        labelStyle: const TextStyle(color: Colors.black87),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    channel?.sink.close();
    msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCustomerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("👥 Danh sách khách hàng"),
          backgroundColor: Colors.blue,
        ),
        body: RefreshIndicator(
          onRefresh: fetchCustomers,
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final id = customer['CustomerID'];
              final userName = customer['UserName'] ?? 'Khách $id';
              final unread = unreadCounts[id] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: InkWell(
                  onTap: () => selectCustomer(id, userName),
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: TextStyle(
                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                        color: unread > 0 ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    subtitle: Text(
                      "ID: $id${customer['LastMessageTime'] != null ? ' • ${formatTime(customer['LastMessageTime'])}' : ''}",
                    ),
                    trailing: unread > 0
                        ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$unread",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    )
                        : null,
                    tileColor: unread > 0 ? Colors.blue[50] : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("💬 Chat với $selectedCustomerName"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selectedCustomerId = null;
              selectedCustomerName = null;
              messages = [];
              channel?.sink.close();
            });
            fetchCustomers();
          },
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: "Phân tích khách này",
            onPressed: () {
              if (selectedCustomerId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminAnalysisPage(customerId: selectedCustomerId),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isAdmin = msg['IsFromAdmin'] ?? false;
                String sentiment = msg['Sentiment'] ?? '';
                IconData? sentimentIcon;
                Color sentimentColor = Colors.grey;

                if (sentiment == 'Tích cực') {
                  sentimentIcon = Icons.sentiment_satisfied_alt;
                  sentimentColor = Colors.green;
                } else if (sentiment == 'Tiêu cực') {
                  sentimentIcon = Icons.sentiment_dissatisfied;
                  sentimentColor = Colors.red;
                } else if (sentiment == 'Trung lập') {
                  sentimentIcon = Icons.sentiment_neutral;
                  sentimentColor = Colors.grey;
                }

                String? category = msg['Category'];

                return ChatBubble(
                  clipper: ChatBubbleClipper5(
                      type: isAdmin ? BubbleType.sendBubble : BubbleType.receiverBubble),
                  alignment: isAdmin ? Alignment.topRight : Alignment.topLeft,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  backGroundColor: isAdmin ? Colors.blue[600] : Colors.grey[200],
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['Content'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: isAdmin ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          formatTime(msg['CreatedAt'] ?? DateTime.now().toString()),
                          style: TextStyle(
                            fontSize: 10,
                            color: isAdmin ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (!isAdmin && (sentiment.isNotEmpty || category != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sentimentIcon != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(sentimentIcon,
                                          color: sentimentColor, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        sentiment,
                                        style: TextStyle(
                                            color: sentimentColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                if (category != null)
                                  Text(
                                    "📌 $category",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.deepPurple),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildQuickReply("Xin chào, tôi có thể giúp gì?"),
                _buildQuickReply("Cảm ơn bạn đã liên hệ!"),
                _buildQuickReply("Vui lòng cung cấp thêm thông tin."),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: msgController.text.isEmpty ? Colors.grey : Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: msgController.text.isEmpty ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}