class ExerciseMachine {
  final String id;
  final String splitId;
  final String name;
  final String targetMuscle;
  final String adjustmentNotes;
  final String? photoPath;
  final int order;
  final int createdAt;

  ExerciseMachine({
    required this.id,
    required this.splitId,
    required this.name,
    this.targetMuscle = 'General',
    this.adjustmentNotes = '',
    this.photoPath,
    this.order = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'splitId': splitId,
      'name': name,
      'targetMuscle': targetMuscle,
      'adjustmentNotes': adjustmentNotes,
      'photoPath': photoPath,
      'order': order,
      'createdAt': createdAt,
    };
  }

  factory ExerciseMachine.fromJson(Map<String, dynamic> json) {
    return ExerciseMachine(
      id: json['id'] as String,
      splitId: json['splitId'] as String,
      name: json['name'] as String,
      targetMuscle: json['targetMuscle'] as String? ?? 'General',
      adjustmentNotes: json['adjustmentNotes'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  ExerciseMachine copyWith({
    String? id,
    String? splitId,
    String? name,
    String? targetMuscle,
    String? adjustmentNotes,
    String? photoPath,
    int? order,
    int? createdAt,
  }) {
    return ExerciseMachine(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      adjustmentNotes: adjustmentNotes ?? this.adjustmentNotes,
      photoPath: photoPath ?? this.photoPath,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
