import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:fitcoach_/services/exercise_api_service.dart';
import 'package:fitcoach_/screens/workout/exercise_detail_screen.dart';
import 'package:flutter/material.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  // Data
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String _errorMessage = "";
  int _currentOffset = 0;

  // Selection
  final Set<String> _selectedIds = {};
  final List<Exercise> _selectedExercises = [];

  // Filters
  String _selectedCategory = "all";
  Timer? _debounce;

  // SIMPLIFIED CATEGORIES (The Service handles the "Chest" -> "Pectorals" mapping now)
  final Map<String, String> _categories = {
    "All": "all",
    "Chest": "chest",
    "Back": "back",
    "Abs": "abs",
    "Legs": "legs",
    "Shoulders": "shoulders",
    "Arms": "arms",
    "Cardio": "cardio",
  };

  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonYellow = const Color(0xFFD0FD3E);

  @override
  void initState() {
    super.initState();
    _loadExercises(reset: true);
  }

  Future<void> _loadExercises({bool reset = false}) async {
    if (reset) {
      setState(() {
        _exercises = [];
        _currentOffset = 0;
        _isLoading = true;
        _errorMessage = "";
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      List<Exercise> results;
      if (_selectedCategory == "all") {
        results = await ExerciseApiService.fetchExercises(
          limit: 50,
          offset: _currentOffset,
        );
      } else {
        // Fetch specific category using the new Smart Search
        results = await ExerciseApiService.fetchByBodyPart(_selectedCategory);
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _exercises = results;
          } else {
            _exercises.addAll(results);
          }
          if (_selectedCategory == "all") {
             _currentOffset += 50;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load. Check connection.";
        });
        print("API Error: $e"); 
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isLoading = true);
      try {
        final results = await ExerciseApiService.searchExercises(
          query.toLowerCase(),
        );
        if (mounted) {
          setState(() {
            _exercises = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selectedIds.contains(exercise.id)) {
        _selectedIds.remove(exercise.id);
        _selectedExercises.removeWhere((e) => e.id == exercise.id);
      } else {
        _selectedIds.add(exercise.id);
        _selectedExercises.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Exercises",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, _selectedExercises),
              backgroundColor: _neonYellow,
              label: Text(
                "Add (${_selectedExercises.length})",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.black),
            )
          : null,
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search (e.g., Bench Press)...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: _cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = entry.value);
                      _loadExercises(reset: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _neonYellow : _cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // List
          Expanded(
            child: _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        TextButton(
                          onPressed: () => _loadExercises(reset: true),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : _exercises.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      "No exercises found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // Add "Load More" button only for "All" tab
                    itemCount: _exercises.length + (_selectedCategory == "all" ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: () => _loadExercises(reset: false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cardDark,
                                    foregroundColor: _neonYellow,
                                  ),
                                  child: const Text("Load More Exercises"),
                                ),
                        );
                      }

                      final exercise = _exercises[index];
                      final isSelected = _selectedIds.contains(exercise.id);
                      return _buildExerciseTile(exercise, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise, bool isSelected) {
    bool hasUrl = exercise.gifUrl.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(
              exercise: exercise,
              onAdd: () => _toggleSelection(exercise),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: isSelected ? _neonYellow.withOpacity(0.1) : _cardDark,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: _neonYellow, width: 2) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: !hasUrl
                  ? const Center(child: Icon(Icons.fitness_center, color: Colors.grey, size: 30))
                  : CachedNetworkImage(
                      imageUrl: exercise.gifUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
            ),
          ),
          title: Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            "${exercise.bodyPart} • ${exercise.target}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: IconButton(
            icon: Icon(
              isSelected ? Icons.check_circle : Icons.add_circle,
              color: isSelected ? _neonYellow : Colors.white,
            ),
            onPressed: () => _toggleSelection(exercise),
          ),
        ),
      ),
    );
  }
}