import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/article_screen.dart';

class ArticleListScreen extends StatelessWidget {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allArticles = [
      {
        "title": "Supplement Guide 101",
        "image":
            "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?q=80&w=1470&auto=format&fit=crop",
        "color": const Color(0xFFBB86FC),
      },
      {
        "title": "Recovery Protocols",
        "image":
            "https://images.unsplash.com/photo-1516481157630-05bc0aeb8b19?q=80&w=1470&auto=format&fit=crop",
        "color": Colors.blueAccent,
      },
      {
        "title": "Nutrition Myths Busted",
        "image":
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1470&auto=format&fit=crop",
        "color": const Color(0xFFD0FD3E),
      },
      {
        "title": "Mastering the Squat",
        "image":
            "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
        "color": Colors.redAccent,
      },
      {
        "title": "Sleep and Muscle Growth",
        "image":
            "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?q=80&w=1460&auto=format&fit=crop",
        "color": Colors.tealAccent,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Articles & Tips",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allArticles.length,
        itemBuilder: (context, index) {
          final article = allArticles[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleScreen(
                  title: article["title"],
                  imageUrl: article["image"],
                  color: article["color"],
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(article["image"]),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: article["color"].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: article["color"].withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        "PRO TIP",
                        style: TextStyle(
                          color: article["color"],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
