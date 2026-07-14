import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage('Chào đạo hữu! Lão mỗ đã chờ đạo hữu bấy lâu. Hôm nay đạo hữu muốn gieo quẻ cho đội bóng nào chăng?', false),
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

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
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await dioClient.post('/ai/chat', data: {'message': text});
      
      // Đảm bảo lấy đúng trường 'response' từ Backend
      final botResponse = response.data['response'] ?? "Lão mỗ nhất thời hoa mắt, không nhìn rõ thiên cơ...";

      setState(() {
        _messages.add(ChatMessage(botResponse, false));
        _isLoading = false;
      });
    } on DioException catch (e) {
      String msg = "Lỗi kết nối";
      if (e.type == DioExceptionType.connectionTimeout) {
        msg = "Kết nối quá hạn (Timeout)";
      } else if (e.type == DioExceptionType.connectionError) {
        msg = "Không tìm thấy Backend. Hãy kiểm tra IP máy tính trong CMD!";
      } else if (e.response != null) {
        msg = e.response?.data['response'] ?? "Lỗi backend: ${e.response?.statusCode}";
      } else {
        msg = "Lỗi: ${e.message}";
      }
      setState(() {
        _messages.add(ChatMessage('Huyền cơ báo rằng: "$msg"', false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Lỗi hệ thống: $e', false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161F2C),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/ChatBox.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lão Đạo Hữu AI', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Đang gieo quẻ...', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF3B66F5) : const Color(0xFF161F2C),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: msg.isUser ? Colors.white : Colors.white70, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFF161F2C)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F16),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Hỏi Lão Đạo Hữu về thiên cơ...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: Color(0xFF3B66F5),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
