class SetLog {
  final String id;
  final String exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final String dateString;
  final int timestamp;
  final String notes;

  SetLog({
    required this.id,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.dateString,
    required this.timestamp,
    this.notes = '',
  });

  // Epley formula for Estimated 1 Rep Max: weight * (1 + reps / 30)
  double get estimated1RM {
    if (reps <= 0 || weightKg <= 0) return weightKg;
    if (reps == 1) return weightKg;
    return (weightKg * (1 + (reps / 30.0)));
  }

  double get volume => weightKg * reps;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'weightKg': weightKg,
      'reps': reps,
      'dateString': dateString,
      'timestamp': timestamp,
      'notes': notes,
    };
  }

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      setNumber: (json['setNumber'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      dateString: json['dateString'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      notes: json['notes'] as String? ?? '',
    );
  }

  SetLog copyWith({
    String? id,
    String? exerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    String? dateString,
    int? timestamp,
    String? notes,
  }) {
    return SetLog(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      dateString: dateString ?? this.dateString,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}
