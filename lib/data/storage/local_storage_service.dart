import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_split.dart';
import '../models/exercise_machine.dart';
import '../models/set_log.dart';

class LocalStorageService {
  static const String _keySplits = 'gym_splits_v1';
  static const String _keyExercises = 'gym_exercises_v1';
  static const String _keyLogs = 'gym_logs_v1';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._seedInitialDataIfEmpty();
    return service;
  }

  // --- Splits ---

  List<WorkoutSplit> getSplits() {
    final raw = _prefs.getString(_keySplits);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw) as List;
      final splits = decoded
          .map((item) => WorkoutSplit.fromJson(item as Map<String, dynamic>))
          .toList();
      splits.sort((a, b) => a.order.compareTo(b.order));
      return splits;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSplit(WorkoutSplit split) async {
    final splits = getSplits();
    final index = splits.indexWhere((s) => s.id == split.id);
    if (index >= 0) {
      splits[index] = split;
    } else {
      splits.add(split);
    }
    await _saveSplitsList(splits);
  }

  Future<void> deleteSplit(String splitId) async {
    final splits = getSplits().where((s) => s.id != splitId).toList();
    await _saveSplitsList(splits);

    // Also cascade delete exercises and their logs
    final exercises = getExercises().where((e) => e.splitId == splitId).toList();
    for (final ex in exercises) {
      await deleteExercise(ex.id);
    }
  }

  Future<void> _saveSplitsList(List<WorkoutSplit> splits) async {
    final raw = jsonEncode(splits.map((s) => s.toJson()).toList());
    await _prefs.setString(_keySplits, raw);
  }

  // --- Exercises ---

  List<ExerciseMachine> getExercises() {
    final raw = _prefs.getString(_keyExercises);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw) as List;
      final exercises = decoded
          .map((item) => ExerciseMachine.fromJson(item as Map<String, dynamic>))
          .toList();
      exercises.sort((a, b) => a.order.compareTo(b.order));
      return exercises;
    } catch (e) {
      return [];
    }
  }

  List<ExerciseMachine> getExercisesBySplit(String splitId) {
    return getExercises().where((e) => e.splitId == splitId).toList();
  }

  Future<void> saveExercise(ExerciseMachine exercise) async {
    final list = getExercises();
    final index = list.indexWhere((e) => e.id == exercise.id);
    if (index >= 0) {
      list[index] = exercise;
    } else {
      list.add(exercise);
    }
    await _saveExercisesList(list);
  }

  Future<void> deleteExercise(String exerciseId) async {
    final list = getExercises().where((e) => e.id != exerciseId).toList();
    await _saveExercisesList(list);

    // Cascade delete logs for this exercise
    final logs = getLogs().where((l) => l.exerciseId != exerciseId).toList();
    await _saveLogsList(logs);
  }

  Future<void> _saveExercisesList(List<ExerciseMachine> exercises) async {
    final raw = jsonEncode(exercises.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyExercises, raw);
  }

  // --- Set Logs ---

  List<SetLog> getLogs() {
    final raw = _prefs.getString(_keyLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw) as List;
      final logs = decoded
          .map((item) => SetLog.fromJson(item as Map<String, dynamic>))
          .toList();
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return logs;
    } catch (e) {
      return [];
    }
  }

  List<SetLog> getLogsByExercise(String exerciseId) {
    return getLogs().where((l) => l.exerciseId == exerciseId).toList();
  }

  Future<void> saveLog(SetLog log) async {
    final list = getLogs();
    final index = list.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      list[index] = log;
    } else {
      list.add(log);
    }
    await _saveLogsList(list);
  }

  Future<void> deleteLog(String logId) async {
    final list = getLogs().where((l) => l.id != logId).toList();
    await _saveLogsList(list);
  }

  Future<void> _saveLogsList(List<SetLog> logs) async {
    final raw = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs.setString(_keyLogs, raw);
  }

  // --- Initial Seed ---

  Future<void> _seedInitialDataIfEmpty() async {
    if (getSplits().isNotEmpty) return;

    final defaultSplits = [
      WorkoutSplit(
        id: 'split_push',
        name: 'Push Day (Chest, Shoulders)',
        colorHex: '#00FF88',
        icon: '⚡',
        order: 1,
      ),
      WorkoutSplit(
        id: 'split_pull',
        name: 'Pull Day (Back & Biceps)',
        colorHex: '#00E5FF',
        icon: '🔥',
        order: 2,
      ),
      WorkoutSplit(
        id: 'split_legs',
        name: 'Legs & Calves (Quads, Hamstrings)',
        colorHex: '#FFB703',
        icon: '💥',
        order: 3,
      ),
      WorkoutSplit(
        id: 'split_posterior',
        name: 'Posterior Chain (Glutes & Back)',
        colorHex: '#A855F7',
        icon: '🛡️',
        order: 4,
      ),
    ];

    await _saveSplitsList(defaultSplits);

    final now = DateTime.now().millisecondsSinceEpoch;
    final dayMs = 86400000;

    final defaultExercises = [
      ExerciseMachine(
        id: 'ex_incline_press',
        splitId: 'split_push',
        name: 'Incline Chest Press Machine',
        targetMuscle: 'Chest',
        adjustmentNotes: 'Seat height: #4 | Pin hole: 2nd from top | Handles: Wide neutral grip',
        order: 1,
        createdAt: now - dayMs * 5,
      ),
      ExerciseMachine(
        id: 'ex_shoulder_press',
        splitId: 'split_push',
        name: 'Seated Shoulder Press Machine',
        targetMuscle: 'Shoulders',
        adjustmentNotes: 'Back pad: 85° | Seat pin: 3 | Elbows tucked 30°',
        order: 2,
        createdAt: now - dayMs * 5,
      ),
      ExerciseMachine(
        id: 'ex_tricep_pushdown',
        splitId: 'split_push',
        name: 'Cable Triceps Pushdown',
        targetMuscle: 'Triceps',
        adjustmentNotes: 'Pulley top notch | V-bar attachment | Pin: #8',
        order: 3,
        createdAt: now - dayMs * 5,
      ),
      ExerciseMachine(
        id: 'ex_lat_pulldown',
        splitId: 'split_pull',
        name: 'Lat Pulldown Machine',
        targetMuscle: 'Back',
        adjustmentNotes: 'Thigh pad locked at notch 3 | Mag-Grip medium | Lean back 10°',
        order: 1,
        createdAt: now - dayMs * 4,
      ),
      ExerciseMachine(
        id: 'ex_cable_row',
        splitId: 'split_pull',
        name: 'Seated Cable Row',
        targetMuscle: 'Back',
        adjustmentNotes: 'Footplate high | Neutral close grip | Full thoracic stretch',
        order: 2,
        createdAt: now - dayMs * 4,
      ),
      ExerciseMachine(
        id: 'ex_leg_press',
        splitId: 'split_legs',
        name: '45° Plate-Loaded Leg Press',
        targetMuscle: 'Quads',
        adjustmentNotes: 'Backrest: lowest angle | Feet mid-platform shoulder width | Safety notch: 2',
        order: 1,
        createdAt: now - dayMs * 3,
      ),
      ExerciseMachine(
        id: 'ex_leg_curl',
        splitId: 'split_legs',
        name: 'Seated Leg Curl Machine',
        targetMuscle: 'Hamstrings',
        adjustmentNotes: 'Thigh clamp: tight | Ankle roller: notch 4 | Back seat: 5',
        order: 2,
        createdAt: now - dayMs * 3,
      ),
    ];

    await _saveExercisesList(defaultExercises);

    // Seed realistic previous logs for progressive overload demo
    final dateStr = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0];
    final sampleLogs = [
      SetLog(
        id: 'log_seed_1',
        exerciseId: 'ex_incline_press',
        setNumber: 1,
        weightKg: 65.0,
        reps: 12,
        dateString: dateStr,
        timestamp: now - dayMs * 2,
      ),
      SetLog(
        id: 'log_seed_2',
        exerciseId: 'ex_incline_press',
        setNumber: 2,
        weightKg: 75.0,
        reps: 10,
        dateString: dateStr,
        timestamp: now - dayMs * 2 + 180000,
      ),
      SetLog(
        id: 'log_seed_3',
        exerciseId: 'ex_incline_press',
        setNumber: 3,
        weightKg: 82.5,
        reps: 8,
        dateString: dateStr,
        timestamp: now - dayMs * 2 + 360000,
      ),
    ];

    await _saveLogsList(sampleLogs);
  }
}
