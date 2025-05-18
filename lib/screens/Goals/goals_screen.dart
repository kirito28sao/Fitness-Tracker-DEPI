import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goals_provider.dart';


class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedUnit = 'steps';
  String _selectedCategory = 'exercise';
  late TabController _tabController;

  final List<String> _categories = [
    'exercise',
    'running',
    'jumping',
    'strength',
    'general',
  ];

  final Map<String, String> _categoryNames = {
    'exercise': 'General Exercise',
    'running': 'Running',
    'jumping': 'Jumping',
    'strength': 'Strength Training',
    'general': 'General Goals',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => 
      Provider.of<GoalsProvider>(context, listen: false).fetchGoals()
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Goal'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Goal Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Target'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a target';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_categoryNames[category] ?? category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(value: 'steps', child: Text('Steps')),
                    DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                    DropdownMenuItem(value: 'calories', child: Text('Calories')),
                    DropdownMenuItem(value: 'times', child: Text('Times')),
                    DropdownMenuItem(value: 'km', child: Text('Kilometers')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedUnit = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Provider.of<GoalsProvider>(context, listen: false).addGoal(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  target: int.parse(_targetController.text),
                  unit: _selectedUnit,
                  category: _selectedCategory,
                );
                _titleController.clear();
                _descriptionController.clear();
                _targetController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _categoryNames[goal.category] ?? goal.category,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => Provider.of<GoalsProvider>(context, listen: false)
                      .deleteGoal(goal.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: goal.current / goal.target,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.current} / ${goal.target} ${goal.unit}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.motivationalMessage,
              style: TextStyle(
                color: goal.isCompleted ? Colors.green : Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (!goal.isCompleted)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Update Progress',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (value) {
                        final newProgress = int.tryParse(value);
                        if (newProgress != null) {
                          Provider.of<GoalsProvider>(context, listen: false)
                              .updateGoalProgress(goal.id, newProgress);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      final newProgress = goal.current + 1;
                      Provider.of<GoalsProvider>(context, listen: false)
                          .updateGoalProgress(goal.id, newProgress);
                    },
                    child: const Text('+1'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          if (goalsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (goalsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${goalsProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => goalsProvider.fetchGoals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (goalsProvider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No goals yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddGoalDialog,
                    child: const Text('Add Your First Goal'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // All Goals
              RefreshIndicator(
                onRefresh: () => goalsProvider.fetchGoals(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goalsProvider.goals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(goalsProvider.goals[index]);
                  },
                ),
              ),
              // In Progress Goals
              RefreshIndicator(
                onRefresh: () => goalsProvider.fetchGoals(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goalsProvider.inProgressGoals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(goalsProvider.inProgressGoals[index]);
                  },
                ),
              ),
              // Completed Goals
              RefreshIndicator(
                onRefresh: () => goalsProvider.fetchGoals(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goalsProvider.completedGoals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(goalsProvider.completedGoals[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 