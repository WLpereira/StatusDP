class HorarioTrabalho {
  final int id;
  final int usuarioId;
  final int diaSemana;
  final String? horarioInicio;
  final String? horarioFim;
  final String? horarioAlmocoInicio;
  final String? horarioAlmocoFim;
  final dynamic usuario;

  HorarioTrabalho({
    required this.id,
    required this.usuarioId,
    required this.diaSemana,
    this.horarioInicio,
    this.horarioFim,
    this.horarioAlmocoInicio,
    this.horarioAlmocoFim,
    this.usuario,
  });

  factory HorarioTrabalho.fromJson(Map<String, dynamic> json) {
    return HorarioTrabalho(
      id: json['id'],
      usuarioId: json['usuarioid'],
      diaSemana: json['diasemana'],
      horarioInicio: json['horarioinicio'],
      horarioFim: json['horariofim'],
      horarioAlmocoInicio: json['horarioalmocoinicio'],
      horarioAlmocoFim: json['horarioalmocofim'],
      usuario: json['usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioid': usuarioId,
      'diasemana': diaSemana,
      'horarioinicio': horarioInicio,
      'horariofim': horarioFim,
      'horarioalmocoinicio': horarioAlmocoInicio,
      'horarioalmocofim': horarioAlmocoFim,
    };
  }
}