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
    if (title.contains("Barbell")) {
      return """Mastering the barbell is the foundation of any serious strength or hypertrophy program. But lifting heavy with poor mechanics is a one-way ticket to Snap City. 

1. The Setup is Everything
Before you even unrack the weight, your body needs to be tight. Plant your feet firmly into the floor, squeeze your glutes, and brace your core as if you are about to take a punch to the stomach. 

2. Lat Engagement
A common mistake on the bench press and squat is leaving the lats "loose." Imagine bending the bar in half like a horseshoe. This external rotation locks your lats in place, providing a massive, stable shelf for the weight.

3. Bar Path
The bar should not travel in a perfectly straight up-and-down line during a bench press. It should touch lower on your sternum and press up slightly backward toward your collarbone in a slight "J" curve.

Keep the weight manageable, prioritize the contraction, and let your muscles (not your ego) do the lifting!""";
    } else if (title.contains("Supplement")) {
      return """Supplements are meant to do exactly that: supplement a solid diet and training program. They aren't magic, but the right ones can give you an edge.

1. Whey Protein
Convenient, fast-absorbing, and highly bioavailable. Perfect for hitting your daily protein targets, especially post-workout when your muscles are primed for nutrient uptake.

2. Creatine Monohydrate
The most researched supplement on earth. It helps your muscles produce energy during heavy lifting, leading to increased strength and muscle mass over time. 3-5g a day is all you need.

3. Pre-Workout (Caffeine)
Great for days when you're low on energy, but beware of building a tolerance. Cycle off it every few weeks to maintain its effectiveness and let your adrenal system reset.

4. Omega-3 & Vitamin D
Crucial for joint health, hormone production, and overall recovery. If you aren't getting enough sun or eating fatty fish, these are non-negotiable for a healthy foundation.""";
    } else if (title.contains("Recovery")) {
      return """You don't grow in the gym; you grow when you recover. If you are training hard but ignoring recovery, you are leaving gains on the table.

1. Sleep is King
Aim for 7-9 hours of quality sleep. This is when your body releases human growth hormone (HGH) and repairs tissue. No supplement routine can outwork a bad sleep schedule.

2. Active Recovery
On rest days, don't just sit on the couch. Light walks, mobility work, or easy cycling promotes blood flow to damaged muscles, accelerating the repair process by flushing out metabolic waste.

3. Hydration & Electrolytes
A 2% drop in hydration can lead to a 10% drop in performance. Drink water consistently and ensure you're getting enough sodium, potassium, and magnesium, especially if you sweat heavily.

Listen to your body. If you're consistently sore, weak, or unmotivated, it's time to take a deload week.""";
    } else if (title.contains("Macro")) {
      return """Tracking macronutrients (macros) is the most precise way to ensure you are eating aligned with your goals—whether that's losing fat, building muscle, or maintaining.

1. Protein (4 calories per gram)
The building block of muscle. Aim for 1.6 to 2.2 grams per kilogram of body weight. Essential for muscle repair and retention during a cutting phase.

2. Fats (9 calories per gram)
Crucial for hormone regulation (including testosterone). Don't drop these too low! Avocados, nuts, whole eggs, and olive oil are excellent sources.

3. Carbohydrates (4 calories per gram)
Your body's preferred energy source. Time your carbs around your workouts to fuel performance and aid recovery.

How to start: Buy a simple digital food scale, download a tracking app, and log everything for one week just to see your baseline. It's an incredibly eye-opening experience!""";
    }

    // Fallback for any future articles we add without updating this switch
    return "This is a premium FitCoach AI article. Stay tuned for more daily fitness insights, science-based recovery protocols, and nutritional deep dives generated specifically for your goals.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            backgroundColor: Colors.black,
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
                          Colors.black.withOpacity(0.8),
                          Colors.black,
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
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),
                  Text(
                    _getArticleBody(),
                    style: const TextStyle(
                      color: Colors.grey,
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
