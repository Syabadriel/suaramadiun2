import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BeritaSection extends StatelessWidget {
  final List<Map<String, dynamic>> instagramPosts;
  final List<Map<String, dynamic>> kabarWargaPosts;
  final List<Map<String, dynamic>> madiunTodayPosts;
  final VoidCallback onSeeAll;

  const BeritaSection({
    super.key,
    required this.instagramPosts,
    required this.kabarWargaPosts,
    required this.madiunTodayPosts,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Berita",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  "Lihat Semua >",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Kabar Warga'),
              Tab(text: 'Instagram'),
              Tab(text: 'Madiuntoday'),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500,
            ),
            child: TabBarView(
              children: [
                _buildPostList(kabarWargaPosts, 'Berita Kabar Warga'),
                _buildPostList(instagramPosts, '@93fmsuaramadiun'),
                _buildPostList(madiunTodayPosts, 'madiuntoday.id'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts, String label) {
    if (posts.isEmpty) {
      return const Center(child: Text('Tidak ada berita.'));
    }

    final limitedPosts = posts.take(4).toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      itemCount: limitedPosts.length,
      itemBuilder: (context, index) {
        final post = limitedPosts[index];
        return _buildNewsCard(post, label);
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> post, String label) {
    return Card(
      color: const Color.fromRGBO(255, 255, 255, 0.85),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: post['image'] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            post['image'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image),
          ),
        )
            : const Icon(Icons.image_not_supported, size: 40),
        title: Text(
          post['title'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(label),
        onTap: () async {
          final url = post['url'];
          if (url != null && url.toString().isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
      ),
    );
  }
}