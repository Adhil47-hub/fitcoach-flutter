import 'package:flutter/material.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final String title;
  final String tag;
  final String metric;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final String description;

  const RecommendationDetailScreen({
    super.key,
    required this.title,
    required this.tag,
    required this.metric,
    required this.icon,
    required this.color,
    required this.imageUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color _bgBlack = Theme.of(context).scaffoldBackgroundColor;
    Color _cardDark = Theme.of(context).cardColor;
    Color _textWhite = isDark ? Colors.white : Colors.black;
    Color _textGrey = isDark ? Colors.grey : Colors.black54;

    return Scaffold(
      backgroundColor: _bgBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            backgroundColor: _bgBlack,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200,
                      child: Icon(
                        icon,
                        color: _textGrey.withOpacity(0.5),
                        size: 80,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _bgBlack.withOpacity(0.8),
                          _bgBlack,
                        ],
                        stops: const [0.6, 0.9, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _textGrey,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            metric,
                            style: TextStyle(color: _textGrey, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Elaborate Description Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: color, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              "The Breakdown",
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          description,
                          style: TextStyle(
                            color: _textWhite.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
