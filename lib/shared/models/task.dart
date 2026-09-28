/// Task model for the Tasks feature (todos, habits).
class Task {
  const Task({
    this.id,
    required this.title,
    this.notes = '',
    this.completed = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isHabit = false,
    this.habitStreak = 0,
    this.createdAt,
  });

  /// Database row id (null for unsaved items).
  final int? id;

  /// Task title.
  final String title;

  /// Optional long description.
  final String notes;

  /// Whether the task is done.
  final bool completed;

  /// Priority: low / medium / high.
  final TaskPriority priority;

  /// Planned date (today / week tabs filter by it).
  final DateTime? dueDate;

  /// Habits repeat daily; regular tasks do not.
  final bool isHabit;

  /// Current streak in days (for habits).
  final int habitStreak;

  /// Creation timestamp.
  final DateTime? createdAt;

  Task copyWith({
    int? id,
    String? title,
    String? notes,
    bool? completed,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isHabit,
    int? habitStreak,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isHabit: isHabit ?? this.isHabit,
      habitStreak: habitStreak ?? this.habitStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'notes': notes,
      'completed': completed ? 1 : 0,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'is_habit': isHabit ? 1 : 0,
      'habit_streak': habitStreak,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      completed: (map['completed'] as int?) == 1,
      priority: TaskPriorityX.fromName(map['priority'] as String?),
      dueDate: map['due_date'] is String
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      isHabit: (map['is_habit'] as int?) == 1,
      habitStreak: (map['habit_streak'] as int?) ?? 0,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'notes': notes,
        'completed': completed,
        'priority': priority.name,
        'due_date': dueDate?.toIso8601String(),
        'is_habit': isHabit,
        'habit_streak': habitStreak,
        'created_at': createdAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, Object?> json) {
    return Task(
      id: json['id'] as int?,
      title: (json['title'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      priority: TaskPriorityX.fromName(json['priority'] as String?),
      dueDate: json['due_date'] is String
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      isHabit: (json['is_habit'] as bool?) ?? false,
      habitStreak: (json['habit_streak'] as int?) ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  @override
  String toString() => 'Task(id: $id, title: $title, completed: $completed)';
}

/// Task priority levels.
enum TaskPriority { low, medium, high }

/// Helpers for [TaskPriority] serialization.
class TaskPriorityX {
  TaskPriorityX._();

  static TaskPriority fromName(String? name) {
    return TaskPriority.values.firstWhere(
      (TaskPriority p) => p.name == name,
      orElse: () => TaskPriority.medium,
    );
  }
}
