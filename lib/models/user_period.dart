class UserPeriod {
  final int id;
  final int usuarioId;
  final DateTime startDate;
  final DateTime endDate;
  final String info;

  UserPeriod({
    required this.id,
    required this.usuarioId,
    required this.startDate,
    required this.endDate,
    required this.info,
  });

  factory UserPeriod.fromJson(Map<String, dynamic> json) {
    return UserPeriod(
      id: json['id'] as int,
      usuarioId: json['usuarioid'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      info: json['info'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioid': usuarioId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'info': info,
    };
  }
}