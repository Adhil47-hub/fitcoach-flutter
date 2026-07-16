import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;

  const ArticleScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.color,
  });

  String _getArticleBody() {
    if (title.contains("Squat") || title.contains("Barbell")) {
      return """The barbell back squat is the king of all leg exercises, but it is highly technical. A bad squat will wreck your knees and lower back.

1. Foot Placement
There is no 'perfect' stance width. It depends on your hip anatomy. Generally, point your toes out about 15-30 degrees and stand shoulder-width apart.

2. Bracing (The Valsalva Maneuver)
Before you descend, take a massive breath into your belly—not your chest. Flex your abs as if you are about to get punched. This creates a pressurized cylinder that protects your spine.

3. Depth
Aim for at least parallel (where your hip crease drops slightly below the top of your knee). If you can't hit depth without your heels coming off the floor, work on your ankle mobility.

Keep the weight manageable, prioritize the contraction, and let your muscles (not your ego) do the lifting!""";
    } else if (title.contains("Supplement")) {
      return """Supplements are exactly that—supplementary. They are meant to add to a solid foundation of whole foods and consistent training. Here are the big three that actually work:

1. Whey Protein
Protein is the building block of muscle. Whey is fast-absorbing, making it perfect for post-workout recovery. Aim for 1.6-2.2g of protein per kg of body weight daily.

2. Creatine Monohydrate
The most researched supplement on earth. It helps your muscles produce energy during heavy lifting or high-intensity exercise. 5 grams a day is all you need. No loading phase required.

3. Caffeine / Pre-Workout
A simple cup of coffee or a pre-workout supplement can significantly reduce your perceived exertion, meaning you can push harder for longer. Just avoid it within 6 hours of bedtime.""";
    } else if (title.contains("Recovery")) {
      return """You don't build muscle while you lift; you build muscle while you recover. If you are training hard 5 days a week, your recovery protocol needs to be just as intense.

1. Active Recovery
Don't just sit on the couch on your rest days. Go for a 30-minute walk, do some light yoga, or go for an easy bike ride. Blood flow delivers nutrients to torn muscle fibers.

2. Hydration
Muscle is 70% water. If you are dehydrated, your recovery slows to a crawl. Aim for at least 3-4 liters of water a day, especially if you are sweating heavily.

3. Heat and Cold Exposure
While ice baths are trendy, they can actually blunt muscle hypertrophy if done immediately after lifting. Save the cold plunges for rest days or cardio days, and use the sauna post-lift to increase blood flow.""";
    } else if (title.contains("Nutrition")) {
      return """The fitness industry is full of terrible nutrition advice. Let's clear up some of the most common myths holding you back.

Myth 1: Eating carbs at night makes you fat.
Truth: Your body doesn't have a clock that suddenly turns carbs into fat after 8 PM. Weight gain is dictated by total daily calorie intake, not meal timing.

Myth 2: You can only absorb 30g of protein per meal.
Truth: Your body will digest and utilize larger amounts of protein; the digestion process just takes longer. While spreading protein out is optimal for muscle protein synthesis, total daily intake matters far more.

Myth 3: Eating fat makes you fat.
Truth: Dietary fat is essential for hormone production (including testosterone). Eating a caloric surplus makes you fat. Avocados, nuts, and olive oil are your friends.""";
    } else if (title.contains("Sleep")) {
      return """You can have the perfect diet and the perfect workout plan, but if your sleep is garbage, your results will be too.

1. The Hormonal Cascade
During deep (Slow-Wave) sleep, your body releases the majority of its Human Growth Hormone (HGH). If you consistently get less than 7 hours of sleep, your testosterone drops and cortisol (stress hormone) spikes, telling your body to store fat and break down muscle.

2. Sleep Hygiene
• Keep your room freezing cold (around 65°F / 18°C).
• Black out your windows completely.
• Stop looking at your phone 45 minutes before bed; the blue light destroys your natural melatonin production.

Treat your sleep with the same discipline as your workouts.""";
    }

    return "This is a premium FitCoach AI article. Stay tuned for more daily fitness insights, science-based recovery protocols, and nutritional deep dives generated specifically for your goals.";
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color _bgBlack = Theme.of(context).scaffoldBackgroundColor;
    Color _textWhite = isDark ? Colors.white : Colors.black;
    Color _textGrey = isDark ? Colors.grey : Colors.black54;

    Color tagTextColor = (color == const Color(0xFFD0FD3E) && !isDark)
        ? const Color(0xFF00A86B)
        : color;

    return Scaffold(
      backgroundColor: _bgBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
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
                  Image.network(imageUrl, fit: BoxFit.cover),
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
                        stops: const [0.5, 0.9, 1.0],
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "FITCOACH AI TIP",
                      style: TextStyle(
                        color: tagTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 20),
                  Text(
                    _getArticleBody(),
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
