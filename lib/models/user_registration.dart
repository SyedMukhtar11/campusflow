import 'program.dart';

class UserRegistration {
  final String id;
  final String programId;
  final List<int> completedModules;
  final int progress;
  final String status; // 'ongoing' | 'completed'
  final DateTime? completedAt;
  final DateTime? registeredAt;
  final Program? program;

  const UserRegistration({
    required this.id,
    required this.programId,
    this.completedModules = const [],
    this.progress = 0,
    this.status = 'ongoing',
    this.completedAt,
    this.registeredAt,
    this.program,
  });

  bool get isCompleted => status == 'completed' || progress == 100;
  bool get isOngoing => !isCompleted;

  bool isModuleCompleted(int moduleIndex) =>
      completedModules.contains(moduleIndex);

  UserRegistration copyWith({
    String? id,
    String? programId,
    List<int>? completedModules,
    int? progress,
    String? status,
    DateTime? completedAt,
    DateTime? registeredAt,
    Program? program,
  }) {
    return UserRegistration(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      completedModules: completedModules ?? this.completedModules,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      registeredAt: registeredAt ?? this.registeredAt,
      program: program ?? this.program,
    );
  }

  factory UserRegistration.fromJson(Map<String, dynamic> json) {
    return UserRegistration(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      programId: (json['programId'] ?? '').toString(),
      completedModules: (json['completedModules'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'ongoing',
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'].toString())
          : null,
      program: json['program'] is Map<String, dynamic>
          ? Program.fromJson(json['program'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'completedModules': completedModules,
      'progress': progress,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'registeredAt': registeredAt?.toIso8601String(),
    };
  }
}
