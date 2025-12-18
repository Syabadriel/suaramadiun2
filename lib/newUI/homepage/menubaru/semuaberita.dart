import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SemuaBeritaPage extends StatefulWidget {
  final List<Map<String, dynamic>> instagramPosts;
  final List<Map<String, dynamic>> kabarWargaPosts;
  final List<Map<String, dynamic>> madiunTodayPosts;

  const SemuaBeritaPage({
    Key? key,
    required this.instagramPosts,
    required this.kabarWargaPosts,
    required this.madiunTodayPosts,
  }) : super(key: key);

  @override
  _SemuaBeritaPageState createState() => _SemuaBeritaPageState();
}

class _SemuaBeritaPageState extends State<SemuaBeritaPage>
    with TickerProviderStateMixin {
  final int _itemsPerPage = 7;

  int _currentPageInstagram = 1;
  int _currentPageKabarWarga = 1;
  int _currentPageMadiunToday = 1;

  int getTotalPages(int itemCount) {
    return (itemCount / _itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> getPaginatedPosts(
      List<Map<String, dynamic>> posts, int currentPage) {
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (currentPage) * _itemsPerPage;
    return posts.sublist(
      start,
      end > posts.length ? posts.length : end,
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 72, 122),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(186, 141, 86, 15),
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color.fromARGB(15, 226, 156, 50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              dividerColor: Colors.white.withValues(alpha: 0.0),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Kabar Warga'),
                Tab(text: 'Instagram'),
                Tab(text: 'MadiunToday'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBeritaList(widget.kabarWargaPosts, 'Kabar Warga',
                    _currentPageKabarWarga, onPageChanged: (page) {
                      setState(() {
                        _currentPageKabarWarga = page;
                      });
                    }),
                _buildBeritaList(widget.instagramPosts, 'Instagram',
                    _currentPageInstagram, onPageChanged: (page) {
                      setState(() {
                        _currentPageInstagram = page;
                      });
                    }),
                _buildBeritaList(widget.madiunTodayPosts, 'madiuntoday.id',
                    _currentPageMadiunToday, onPageChanged: (page) {
                      setState(() {
                        _currentPageMadiunToday = page;
                      });
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeritaList(
      List<Map<String, dynamic>> allPosts, String label, int currentPage,
      {required Function(int) onPageChanged}) {
    if (allPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox, size: 80, color: Colors.white24),
            SizedBox(height: 8),
            Text('Tidak ada berita.', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final paginatedPosts = getPaginatedPosts(allPosts, currentPage);
    final totalPages = getTotalPages(allPosts.length);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: paginatedPosts.length,
              itemBuilder: (context, index) {
                final post = paginatedPosts[index];
                return BeritaCard(post: post, label: label);
              },
            ),
          ),
          _buildPaginationControls(currentPage, totalPages, onPageChanged),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(
      int currentPage, int totalPages, Function(int) onPageChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        children: List.generate(totalPages, (index) {
          final page = index + 1;
          return GestureDetector(
            onTap: () => onPageChanged(page),
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentPage == page ? Colors.blue : Colors.white54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: currentPage == page
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BeritaCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String label;

  const BeritaCard({Key? key, required this.post, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image'] ?? '';

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final url = post['url'];
          if (url != null && url.toString().isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Gambar
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 160,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              )
                  : Container(
                width: double.infinity,
                height: 160,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported,
                    size: 50, color: Colors.grey),
              ),
            ),

            // Bagian Teks
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.public, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border,
                            color: Colors.grey),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disimpan ke bookmark')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.grey),
                        onPressed: () {
                          final url = post['url'] ?? '';
                          if (url.isNotEmpty) {
                            Share.share(url);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
