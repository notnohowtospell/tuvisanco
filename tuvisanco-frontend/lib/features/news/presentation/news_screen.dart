import 'package:flutter/material.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedCategory = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeaturedNews(),
              _buildCategoryTabs(),
              _buildNewsList(),
              _buildPagination(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedNews() {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://baoxaydung.mediacdn.vn/603483875699699712/2026/7/13/nhan-dinh-phap-tay-ban-nha-17839614074781366678609.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(20)),
                      child: const Text('NỔI BẬT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Phân tích Hệ Kim', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Đại chiến Bán kết: Pháp vs Tây Ban Nha - Quẻ bốc cho nhà vua mới',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.access_time, color: Colors.white38, size: 12),
                    SizedBox(width: 4),
                    Text('15 phút trước', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    SizedBox(width: 16),
                    Icon(Icons.visibility, color: Colors.white38, size: 12),
                    SizedBox(width: 4),
                    Text('12.5k lượt xem', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['Tất cả', 'Soi quẻ', 'Bóng đá', 'Cộng đồng'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          bool isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B66F5) : const Color(0xFF161F2C),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsList() {
    final news = [
      {
        'tag': 'BÁN KẾT',
        'title': 'Pháp vs Tây Ban Nha: Đại chiến Hệ Kim v...',
        'time': 'Vừa xong',
        'views': '12.3k',
        'img': 'https://baoxaydung.mediacdn.vn/603483875699699712/2026/7/13/nhan-dinh-phap-tay-ban-nha-17839614074781366678609.jpg'
      },
      {
        'tag': 'BÁN KẾT',
        'title': 'Argentina vs Anh: Vũ điệu Tango hay Bản...',
        'time': '30 phút trước',
        'views': '15.1k',
        'img': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTBDbf6kZ2Y3uqD1UXPite9OSiOBIt_eA3FqQxnnr6zTw&s'
      },
      {
        'tag': 'TIÊN TRI',
        'title': 'Tiên tri Chung kết: AI sẽ chạm tay vào Cú...',
        'time': '2 giờ trước',
        'views': '22.1k',
        'img': 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?q=80&w=400'
      },
      {
        'tag': 'PHÂN TÍCH',
        'title': 'Phân tích Ngũ hành: Các đội bóng tại Bá...',
        'time': '4 giờ trước',
        'views': '10.5k',
        'img': 'https://images.unsplash.com/photo-1543351611-58f69d7c1781?q=80&w=400'
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = news[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: item)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F2C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: 'news_img_${item['title']}',
                    child: Image.network(
                      item['img'] as String, 
                      width: 80, 
                      height: 80, 
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(item['tag'] as String, style: const TextStyle(color: Color(0xFF3B66F5), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(item['time'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          const Spacer(),
                          const Icon(Icons.visibility, color: Colors.white24, size: 10),
                          const SizedBox(width: 4),
                          Text(item['views'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          const SizedBox(width: 8),
                          const Icon(Icons.share, color: Colors.white24, size: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn('<', false),
          _pageBtn('1', true),
          _pageBtn('2', false),
          _pageBtn('3', false),
          _pageBtn('>', false),
        ],
      ),
    );
  }

  Widget _pageBtn(String text, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B66F5) : const Color(0xFF161F2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
