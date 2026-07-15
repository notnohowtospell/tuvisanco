import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161F2C),
        elevation: 0,
        title: const Text('Chi tiết Tin tức', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Featured Image
                Hero(
                  tag: 'news_img_${newsItem['title']}',
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(newsItem['img'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Tag & Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(20)),
                        child: Text(newsItem['tag'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        newsItem['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.calendar_month, color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Text('15 tháng 7, 2026', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          SizedBox(width: 16),
                          Icon(Icons.timer_outlined, color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Text('5 phút đọc', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 3. Main Content (Thiên cơ bóng đá)
                      const Text(
                        'Trong bầu không khí rực lửa của vòng bán kết, giới mộ điệu không chỉ chờ đợi những pha bóng mãn nhãn mà còn hướng về những dự báo tâm linh đầy huyền bí. Cuộc đối đầu giữa đội tuyển Pháp và Tây Ban Nha được xem như một sự giao thoa định mệnh giữa hai thế lực mang những bản mệnh ngũ hành đối nghịch.\n\nSự xung đột giữa Hỏa và Thủy sẽ tạo ra một kịch bản vô cùng khó lường. Các chuyên gia tử vi nhận định rằng, nếu trận đấu diễn ra ở nhịp độ cao, phần thắng sẽ nghiêng về phía "Gà trống Gaulois". Tuy nhiên, nếu "Bò tót" đủ kiên nhẫn để dập tắt những đợt tấn công chớp nhoáng, dòng Thủy sẽ dần thẩm thấu và nhấn chìm đối thủ ở những phút cuối hiệp hai.\n\nMbappé, ngôi sao sáng nhất của Pháp, mang mệnh Kim - vốn bị Hỏa khắc chế trong ngày thi đấu. Điều này báo hiệu một ngày làm việc vất vả cho tiền đạo này. Ngược lại, Lamine Yamal bên phía Tây Ban Nha lại có những chỉ số tinh tú vô cùng thuận lợi, hứa hẹn sẽ là "biến số" tạo nên sự bùng nổ bất ngờ.',
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 4. Interaction Buttons
                      Row(
                        children: [
                          _buildAction(Icons.thumb_up_alt_outlined, '2.4k'),
                          const SizedBox(width: 20),
                          _buildAction(Icons.comment_outlined, '128'),
                          const Spacer(),
                          const Icon(Icons.bookmark_border, color: Colors.white38),
                        ],
                      ),
                      
                      const Divider(color: Colors.white10, height: 40),
                      
                      // 5. Comment Section
                      const Text('Bình luận (128)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildComment(
                        'Đạo Hữu Soi Kèo',
                        'Trận này Pháp mệnh Hỏa gặp Tây Ban Nha mệnh Thủy, chắc chắn sẽ có biến! Tôi dự đoán sẽ có thẻ đỏ ở hiệp 2.',
                        '2 giờ trước',
                      ),
                      _buildComment(
                        'Lão Nhị Sân Cỏ',
                        'Cung mệnh của Mbappé đang ở thế kẹt, khó mà ghi bàn được. Anh em cẩn thận kèo trên nhé!',
                        '5 giờ trước',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 6. Bottom Comment Input
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFF161F2C)),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFF0B0F16), borderRadius: BorderRadius.circular(25)),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận của bạn...', 
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 13), 
                          border: InputBorder.none
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(backgroundColor: Color(0xFF3B66F5), child: Icon(Icons.send, color: Colors.white, size: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildComment(String user, String text, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 14, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 16, color: Colors.white38)),
              const SizedBox(width: 10),
              Text(user, style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(time, style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.favorite_border, color: Colors.white24, size: 14),
              SizedBox(width: 6),
              Text('43', style: TextStyle(color: Colors.white24, fontSize: 11)),
              SizedBox(width: 20),
              Text('Phản hồi', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
