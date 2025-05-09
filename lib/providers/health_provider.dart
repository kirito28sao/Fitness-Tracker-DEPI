import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthProvider with ChangeNotifier {
  final Health health = Health();
  bool _isLoading = false;
  List<HealthDataPoint> _healthData = [];
  List<HealthDataPoint> _todaySteps = [];
  List<HealthDataPoint> _todayCalories = [];
  List<HealthDataPoint> _todayHeartRate = [];
  List<HealthDataPoint> _todayActiveMinutes = [];

  bool get isLoading => _isLoading;
  List<HealthDataPoint> get todaySteps => _todaySteps;
  List<HealthDataPoint> get todayCalories => _todayCalories;
  List<HealthDataPoint> get todayHeartRate => _todayHeartRate;
  List<HealthDataPoint> get todayActiveMinutes => _todayActiveMinutes;

  // Request authorization for health data
  Future<bool> requestAuthorization() async {
    try {
      // Request permissions
      await Permission.activityRecognition.request();
      await Permission.sensors.request();

      // Request health data access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.EXERCISE_TIME,
      ];

      final authorized = await health.requestAuthorization(types);
      return authorized;
    } catch (e) {
      debugPrint('Error requesting health authorization: $e');
      return false;
    }
  }

  // Fetch today's health data
  Future<void> fetchTodayHealthData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.EXERCISE_TIME,
      ];

      // Fetch health data
      final healthData = await health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      // Process and store health data
      _healthData = healthData;

      // Filter data by type
      _todaySteps = healthData
          .where((data) => data.type == HealthDataType.STEPS)
          .toList();
      _todayCalories = healthData
          .where((data) => data.type == HealthDataType.ACTIVE_ENERGY_BURNED)
          .toList();
      _todayHeartRate = healthData
          .where((data) => data.type == HealthDataType.HEART_RATE)
          .toList();
      _todayActiveMinutes = healthData
          .where((data) => data.type == HealthDataType.EXERCISE_TIME)
          .toList();
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get total steps for today
  int getTodaySteps() {
    return _todaySteps.fold(0, (sum, data) => sum + (data.value as int));
  }

  // Get total calories burned today
  double getTodayCalories() {
    return _todayCalories.fold(
      0.0,
      (sum, data) => sum + (data.value as double),
    );
  }

  // Get average heart rate today
  double getAverageHeartRate() {
    if (_todayHeartRate.isEmpty) return 0.0;
    final sum = _todayHeartRate.fold(
      0.0,
      (sum, data) => sum + (data.value as double),
    );
    return sum / _todayHeartRate.length;
  }

  // Get total active minutes today
  int getTodayActiveMinutes() {
    return _todayActiveMinutes.fold(
      0,
      (sum, data) => sum + (data.value as int),
    );
  }

  // Fetch health data for a specific date range
  Future<List<HealthDataPoint>> fetchHealthDataForRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      return await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
    } catch (e) {
      debugPrint('Error fetching health data for range: $e');
      return [];
    }
  }
}
