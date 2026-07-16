import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/workout/auto_workout_generator.dart';
import 'package:fitcoach_/screens/nutrition/nutrition_screen.dart';
import 'package:fitcoach_/screens/article_screen.dart';
import 'package:fitcoach_/screens/workout/workout_menu_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _searchResults = [];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;

  final Color _purpleAccent = const Color(0xFFBB86FC);

  List<Map<String, dynamic>> get _masterData => [
    {
      "title": "100-Rep Leg Crusher",
      "category": "Workout",
      "icon": Icons.fitness_center,
      "color": _neonYellow,
      "destination": const AutoWorkoutGenerator(
        routineName: "100-Rep Leg Crusher",
      ),
    },
    {
      "title": "Spartan Core",
      "category": "Workout",
      "icon": Icons.fitness_center,
      "color": _neonYellow,
      "destination": const AutoWorkoutGenerator(routineName: "Spartan Core"),
    },
    {
      "title": "Upper Body Blast",
      "category": "Workout",
      "icon": Icons.fitness_center,
      "color": _neonYellow,
      "destination": const AutoWorkoutGenerator(
        routineName: "Upper Body Blast",
      ),
    },
    {
      "title": "Full Body Stretching",
      "category": "Workout",
      "icon": Icons.self_improvement,
      "color": _purpleAccent,
      "destination": const WorkoutMenuScreen(),
    },
    {
      "title": "Log Daily Nutrition",
      "category": "Nutrition",
      "icon": Icons.restaurant_menu,
      "color": Colors.redAccent,
      "destination": const NutritionScreen(),
    },
    {
      "title": "Supplement Guide 101",
      "category": "Article",
      "icon": Icons.article,
      "color": Colors.blueAccent,
      "destination": const ArticleScreen(
        title: "Supplement Guide 101",
        imageUrl:
            "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?q=80&w=1470&auto=format&fit=crop",
        color: Color(0xFFBB86FC),
      ),
    },
    {
      "title": "Optimal Recovery Protocols",
      "category": "Article",
      "icon": Icons.article,
      "color": Colors.blueAccent,
      "destination": const ArticleScreen(
        title: "Optimal Recovery Protocols",
        imageUrl:
            "https://images.unsplash.com/photo-1516481157630-05bc0aeb8b19?q=80&w=1470&auto=format&fit=crop",
        color: Colors.blueAccent,
      ),
    },
    {
      "title": "Macro Tracking Basics",
      "category": "Article",
      "icon": Icons.article,
      "color": Colors.blueAccent,
      "destination": const ArticleScreen(
        title: "Macro Tracking Basics",
        imageUrl:
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1453&auto=format&fit=crop",
        color: Colors.redAccent,
      ),
    },
  ];

  final List<String> _searchExamples = [
    "Leg Crusher",
    "Supplement Guide",
    "Macro Tracking",
    "Core",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _masterData
            .where(
              (item) =>
                  item["title"].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  item["category"].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = "";
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: _textWhite,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty
                              ? _neonYellow
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: _textWhite, fontSize: 16),
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search workouts, articles...",
                          hintStyle: TextStyle(color: _textGrey, fontSize: 14),
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: _clearSearch,
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Try Searching For...",
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _searchExamples.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchChanged(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.transparent : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: _neonYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        search,
                        style: TextStyle(color: _textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: _textGrey, size: 80),
            const SizedBox(height: 20),
            Text(
              "No results for '$_searchQuery'",
              style: TextStyle(
                color: _textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item["destination"]),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item["color"].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item["icon"], color: item["color"], size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["category"],
                        style: TextStyle(
                          color: item["color"],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: _textGrey, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
