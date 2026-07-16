import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/recommendation_detail_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;

  const RecommendationsScreen({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color _bgBlack = Theme.of(context).scaffoldBackgroundColor;
    Color _cardDark = Theme.of(context).cardColor;
    Color _textWhite = isDark ? Colors.white : Colors.black;
    Color _textGrey = isDark ? Colors.grey : Colors.black54;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        title: Text(
          "AI Recommendations",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
      ),
      body: recommendations.isEmpty
          ? Center(
              child: Text(
                "No recommendations generated yet.",
                style: TextStyle(color: _textGrey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                return _buildRecommendationCard(
                  context,
                  rec["title"] ?? "AI Tip",
                  rec["tag"] ?? "INFO",
                  rec["metric"] ?? "",
                  rec["icon"] ?? Icons.star,
                  rec["color"] ?? Colors.blueAccent,
                  rec["imageUrl"] ?? "",
                  rec["description"] ?? "",
                  isDark,
                  _cardDark,
                  _textWhite,
                  _textGrey,
                );
              },
            ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    String title,
    String subtitle,
    String metric,
    IconData icon,
    Color color,
    String imageUrl,
    String description,
    bool isDark,
    Color cardDark,
    Color textWhite,
    Color textGrey,
  ) {
    String cleanUrl = imageUrl.replaceAll('[', '').replaceAll(']', '').trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecommendationDetailScreen(
              title: title,
              tag: subtitle,
              metric: metric,
              icon: icon,
              color: color,
              imageUrl: cleanUrl,
              description: description,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: cleanUrl.isNotEmpty
                    ? Image.network(
                        cleanUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          icon,
                          color: textGrey.withOpacity(0.5),
                          size: 50,
                        ),
                      )
                    : Icon(icon, color: textGrey.withOpacity(0.5), size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // ✅ HIDDEN IF EMPTY
                      if (metric.isNotEmpty) ...[
                        const Spacer(),
                        Icon(Icons.timer_outlined, color: textGrey, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          metric,
                          style: TextStyle(color: textGrey, fontSize: 12),
                        ),
                      ],
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
