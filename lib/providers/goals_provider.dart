import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Goal {
  final String id;
  final String title;
  final String description;
  final int target;
  int current;
  final String unit;
  bool isCompleted;
  final String userId;
  final DateTime createdAt;
  final String category;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.unit,
    this.isCompleted = false,
    required this.userId,
    required this.createdAt,
    required this.category,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      target: json['target'],
      current: json['current'],
      unit: json['unit'],
      isCompleted: json['is_completed'] ?? false,
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target': target,
      'current': current,
      'unit': unit,
      'is_completed': isCompleted,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'category': category,
    };
  }

  String get motivationalMessage {
    if (!isCompleted) {
      final progress = (current / target * 100).round();
      if (progress < 25) {
        return 'Start your journey! 💪';
      } else if (progress < 50) {
        return 'You\'re on the right track! 🌟';
      } else if (progress < 75) {
        return 'More than halfway there! 🚀';
      } else {
        return 'You\'re so close to your goal! ⭐';
      }
    }
    return 'Congratulations! You achieved your goal! 🎉';
  }
}

class GoalsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get goals by category
  List<Goal> getGoalsByCategory(String category) {
    return _goals.where((goal) => goal.category == category).toList();
  }

  // Get completed goals
  List<Goal> get completedGoals => _goals.where((goal) => goal.isCompleted).toList();

  // Get in-progress goals
  List<Goal> get inProgressGoals => _goals.where((goal) => !goal.isCompleted).toList();

  Future<void> fetchGoals() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _goals = (response as List)
          .map((goal) => Goal.fromJson(goal))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required int target,
    required String unit,
    required String category,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.from('goals').insert({
        'title': title,
        'description': description,
        'target': target,
        'current': 0,
        'unit': unit,
        'is_completed': false,
        'user_id': userId,
        'category': category,
      }).select();

      final newGoal = Goal.fromJson(response[0]);
      _goals.insert(0, newGoal);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoalProgress(String goalId, int newProgress) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final goalIndex = _goals.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) throw Exception('Goal not found');

      final goal = _goals[goalIndex];
      final isCompleted = newProgress >= goal.target;

      await _supabase
          .from('goals')
          .update({
            'current': newProgress,
            'is_completed': isCompleted,
          })
          .eq('id', goalId);

      _goals[goalIndex] = Goal(
        id: goal.id,
        title: goal.title,
        description: goal.description,
        target: goal.target,
        current: newProgress,
        unit: goal.unit,
        isCompleted: isCompleted,
        userId: goal.userId,
        createdAt: goal.createdAt,
        category: goal.category,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.from('goals').delete().eq('id', goalId);
      _goals.removeWhere((goal) => goal.id == goalId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
} 