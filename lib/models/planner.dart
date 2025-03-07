class Planner {
  final int id;
  final int usuarioId;
  final DateTime data;
  final String hora;
  final int statusId; // Alterado de String status para int statusId
  final String? informacao;

  Planner({
    required this.id,
    required this.usuarioId,
    required this.data,
    required this.hora,
    required this.statusId,
    this.informacao,
  });

  factory Planner.fromJson(Map<String, dynamic> json) {
    return Planner(
      id: json['id'] as int,
      usuarioId: json['usuarioid'] as int,
      data: DateTime.parse(json['data'] as String),
      hora: json['hora'] as String,
      statusId: json['statusid'] as int, // Corrigido para 'statusid'
      informacao: json['informacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioid': usuarioId,
      'data': data.toIso8601String().split('T')[0],
      'hora': hora,
      'statusid': statusId,
      'informacao': informacao,
    };
  }
}