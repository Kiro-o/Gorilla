class WorkoutSplit {
  final String id;
  final String name;
  final String colorHex;
  final String icon;
  final int order;

  WorkoutSplit({
    required this.id,
    required this.name,
    this.colorHex = '#00FF88',
    this.icon = '⚡',
    this.order = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'icon': icon,
      'order': order,
    };
  }

  factory WorkoutSplit.fromJson(Map<String, dynamic> json) {
    return WorkoutSplit(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#00FF88',
      icon: json['icon'] as String? ?? '⚡',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  WorkoutSplit copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? icon,
    int? order,
  }) {
    return WorkoutSplit(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      order: order ?? this.order,
    );
  }
}
