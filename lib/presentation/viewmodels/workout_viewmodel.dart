import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/workout_split.dart';
import '../../data/models/exercise_machine.dart';
import '../../data/models/set_log.dart';
import '../../data/storage/local_storage_service.dart';
import '../../data/storage/firestore_sync_service.dart';

class WorkoutViewModel extends ChangeNotifier {
  final LocalStorageService _storage;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  List<WorkoutSplit> _splits = [];
  String? _activeSplitId;
  String _searchQuery = '';

  // Active Live Logger State
  ExerciseMachine? _activeExercise;
  int _activeSetNumber = 1;
  double _currentWeight = 60.0;
  int _currentReps = 10;
  int _chosenRestDuration = 180; // Default 3 minutes (180s)

  // Rest Timer State
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerRunning = false;

  WorkoutViewModel(this._storage) {
    _init();
  }

  void _init() {
    _splits = _storage.getSplits();
    if (_splits.isNotEmpty) {
      _activeSplitId = _splits.first.id;
    }
    notifyListeners();
  }

  // --- Getters ---

  LocalStorageService get storage => _storage;
  List<WorkoutSplit> get splits => _splits;
  String? get activeSplitId => _activeSplitId;
  String get searchQuery => _searchQuery;

  WorkoutSplit? get activeSplit {
    if (_activeSplitId == null) return null;
    try {
      return _splits.firstWhere((s) => s.id == _activeSplitId);
    } catch (_) {
      return null;
    }
  }

  List<ExerciseMachine> get exercisesForActiveSplit {
    if (_activeSplitId == null) return [];
    var list = _storage.getExercisesBySplit(_activeSplitId!);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.targetMuscle.toLowerCase().contains(q) ||
            e.adjustmentNotes.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  int getExerciseCountForSplit(String splitId) {
    return _storage.getExercisesBySplit(splitId).length;
  }

  ExerciseMachine? get activeExercise => _activeExercise;
  int get activeSetNumber => _activeSetNumber;
  double get currentWeight => _currentWeight;
  int get currentReps => _currentReps;
  int get chosenRestDuration => _chosenRestDuration;

  int get restSecondsRemaining => _restSecondsRemaining;
  bool get isRestTimerRunning => _isRestTimerRunning;
  String get restFormattedTime {
    final m = _restSecondsRemaining ~/ 60;
    final s = _restSecondsRemaining % 60;
    return '$m:${s < 10 ? '0' : ''}$s';
  }

  // --- Splits API ---

  void selectSplit(String splitId) {
    if (_activeSplitId != splitId) {
      _activeSplitId = splitId;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> saveSplit({String? id, required String name, String? colorHex, String? icon}) async {
    final split = WorkoutSplit(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      colorHex: colorHex ?? '#00FF88',
      icon: icon ?? '⚡',
      order: id == null ? _splits.length + 1 : (_splits.firstWhere((s) => s.id == id).order),
    );
    await _storage.saveSplit(split);
    _splits = _storage.getSplits();
    _activeSplitId = split.id;
    notifyListeners();
  }

  Future<void> deleteSplit(String splitId) async {
    await _storage.deleteSplit(splitId);
    _splits = _storage.getSplits();
    if (_activeSplitId == splitId) {
      _activeSplitId = _splits.isNotEmpty ? _splits.first.id : null;
    }
    notifyListeners();
  }

  // --- Exercises API ---

  Future<void> saveExercise({
    String? id,
    required String name,
    required String targetMuscle,
    required String adjustmentNotes,
    String? photoPath,
  }) async {
    if (_activeSplitId == null) return;
    final exercise = ExerciseMachine(
      id: id ?? _uuid.v4(),
      splitId: _activeSplitId!,
      name: name.trim(),
      targetMuscle: targetMuscle,
      adjustmentNotes: adjustmentNotes.trim(),
      photoPath: photoPath,
      order: id == null ? exercisesForActiveSplit.length + 1 : 0,
    );
    await _storage.saveExercise(exercise);
    notifyListeners();
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _storage.deleteExercise(exerciseId);
    notifyListeners();
  }

  Future<String?> pickAndStoreImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'machine_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // --- Live Set Logger API ---

  void openLiveLogger(ExerciseMachine exercise) {
    _activeExercise = exercise;

    // Load today's sets
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final allLogs = _storage.getLogsByExercise(exercise.id);
    final todayLogs = allLogs.where((l) => l.dateString == todayStr).toList();
    final pastLogs = allLogs.where((l) => l.dateString != todayStr).toList();

    _activeSetNumber = todayLogs.length + 1;

    // Initialize weight & reps based on previous set today or last session
    if (todayLogs.isNotEmpty) {
      _currentWeight = todayLogs.last.weightKg;
      _currentReps = todayLogs.last.reps;
    } else if (pastLogs.isNotEmpty) {
      _currentWeight = pastLogs.last.weightKg;
      _currentReps = pastLogs.last.reps;
    } else {
      _currentWeight = 60.0;
      _currentReps = 10;
    }

    notifyListeners();
  }

  List<SetLog> getTodaySetsForActiveExercise() {
    if (_activeExercise == null) return [];
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    return _storage
        .getLogsByExercise(_activeExercise!.id)
        .where((l) => l.dateString == todayStr)
        .toList();
  }

  List<SetLog> getLastSessionSets(String exerciseId) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final pastLogs = _storage
        .getLogsByExercise(exerciseId)
        .where((l) => l.dateString != todayStr)
        .toList();

    if (pastLogs.isEmpty) return [];
    final lastDate = pastLogs.last.dateString;
    return pastLogs.where((l) => l.dateString == lastDate).toList();
  }

  void copyLastSessionValues() {
    if (_activeExercise == null) return;
    final lastSession = getLastSessionSets(_activeExercise!.id);
    if (lastSession.isEmpty) return;

    final todaySets = getTodaySetsForActiveExercise();
    final matchIndex = todaySets.length < lastSession.length
        ? todaySets.length
        : lastSession.length - 1;

    final targetSet = lastSession[matchIndex];
    _currentWeight = targetSet.weightKg;
    _currentReps = targetSet.reps;
    notifyListeners();
  }

  void navigateAdjacentExercise(int direction) {
    final list = exercisesForActiveSplit;
    if (list.length <= 1 || _activeExercise == null) return;
    final currentIndex = list.indexWhere((e) => e.id == _activeExercise!.id);
    if (currentIndex == -1) return;
    final nextIndex = (currentIndex + direction + list.length) % list.length;
    openLiveLogger(list[nextIndex]);
  }

  void adjustWeight(double delta) {
    _currentWeight = (_currentWeight + delta).clamp(0.0, 999.0);
    // Round to 1 decimal place
    _currentWeight = (double.parse(_currentWeight.toStringAsFixed(1)));
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void setWeight(double weight) {
    _currentWeight = weight.clamp(0.0, 999.0);
    notifyListeners();
  }

  void adjustReps(int delta) {
    _currentReps = (_currentReps + delta).clamp(1, 999);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void setReps(int reps) {
    _currentReps = reps.clamp(1, 999);
    notifyListeners();
  }

  void adjustSetNumber(int delta) {
    _activeSetNumber = (_activeSetNumber + delta).clamp(1, 99);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void setSetNumber(int setNumber) {
    _activeSetNumber = setNumber.clamp(1, 99);
    notifyListeners();
  }

  void setChosenRestDuration(int seconds) {
    _chosenRestDuration = seconds;
    notifyListeners();
  }

  Future<void> logSet() async {
    if (_activeExercise == null) return;

    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];

    final log = SetLog(
      id: _uuid.v4(),
      exerciseId: _activeExercise!.id,
      setNumber: _activeSetNumber,
      weightKg: _currentWeight,
      reps: _currentReps,
      dateString: dateStr,
      timestamp: now.millisecondsSinceEpoch,
    );

    await _storage.saveLog(log);
    HapticFeedback.heavyImpact();

    // Start rest timer automatically (default 180s / 3m)
    startRestTimer(_chosenRestDuration);

    // Increment set number for next set
    _activeSetNumber++;
    notifyListeners();

    // Auto sync to Firestore leaderboards & user profile in background
    firestoreSyncService.syncLocalStats(storage: _storage).catchError((e) {
      debugPrint('Leaderboard auto-sync error: $e');
    });
  }

  Future<void> deleteLog(String logId) async {
    await _storage.deleteLog(logId);
    if (_activeExercise != null) {
      final todayCount = getTodaySetsForActiveExercise().length;
      _activeSetNumber = todayCount + 1;
    }
    notifyListeners();
  }

  // --- Rest Timer ---

  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restSecondsRemaining = seconds;
    _isRestTimerRunning = true;
    notifyListeners();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 1) {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 3) {
          HapticFeedback.lightImpact();
        }
        notifyListeners();
      } else {
        _restSecondsRemaining = 0;
        _isRestTimerRunning = false;
        timer.cancel();
        HapticFeedback.vibrate();
        notifyListeners();
      }
    });
  }

  void addRestSeconds(int extra) {
    _restSecondsRemaining += extra;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void subtractRestSeconds(int extra) {
    _restSecondsRemaining = (_restSecondsRemaining - extra).clamp(0, 9999);
    HapticFeedback.selectionClick();
    if (_restSecondsRemaining == 0 && _isRestTimerRunning) {
      _restTimer?.cancel();
      _isRestTimerRunning = false;
      HapticFeedback.vibrate();
    }
    notifyListeners();
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    _isRestTimerRunning = false;
    _restSecondsRemaining = 0;
    notifyListeners();
  }

  // --- Statistics & Progressive Overload ---

  Map<String, dynamic> getStatsForExercise(String exerciseId) {
    final logs = _storage.getLogsByExercise(exerciseId);
    if (logs.isEmpty) {
      return {
        'hasHistory': false,
        'prWeight': 0.0,
        'prReps': 0,
        'best1RM': 0.0,
        'totalVolume': 0.0,
        'lastSet': null,
      };
    }

    double prWeight = 0;
    int prReps = 0;
    double best1RM = 0;
    double totalVolume = 0;

    for (final l in logs) {
      totalVolume += l.volume;
      if (l.weightKg > prWeight) {
        prWeight = l.weightKg;
        prReps = l.reps;
      }
      final e1rm = l.estimated1RM;
      if (e1rm > best1RM) {
        best1RM = e1rm;
      }
    }

    final last = logs.last;

    return {
      'hasHistory': true,
      'prWeight': prWeight,
      'prReps': prReps,
      'best1RM': best1RM,
      'totalVolume': totalVolume,
      'lastSet': '${last.weightKg.toStringAsFixed(last.weightKg % 1 == 0 ? 0 : 1)}kg × ${last.reps}',
      'lastDate': last.dateString,
    };
  }

  Map<String, List<SetLog>> getGroupedHistory(String exerciseId) {
    final logs = _storage.getLogsByExercise(exerciseId);
    final Map<String, List<SetLog>> grouped = {};

    for (final l in logs) {
      if (!grouped.containsKey(l.dateString)) {
        grouped[l.dateString] = [];
      }
      grouped[l.dateString]!.add(l);
    }

    return grouped;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
