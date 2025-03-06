class Planner {
  final int id;
  final int usuarioId;
  final DateTime data;
  final String hora;
  final String status;
  final String? informacao;

  Planner({
    required this.id,
    required this.usuarioId,
    required this.data,
    required this.hora,
    required this.status,
    this.informacao,
  });

  factory Planner.fromJson(Map<String, dynamic> json) {
    return Planner(
      id: json['id'] as int,
      usuarioId: json['usuarioId'] as int,
      data: DateTime.parse(json['data'] as String),
      hora: json['hora'] as String,
      status: json['status'] as String,
      informacao: json['informacao'] as String?,
    );
  }
}