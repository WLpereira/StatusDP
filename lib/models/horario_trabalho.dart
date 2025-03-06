class HorarioTrabalho {
  final int id;
  final int usuarioId;
  final int diaSemana; // 1 = Segunda, 7 = Domingo
  final String horarioInicio;
  final String horarioFim;
  final String? horarioAlmocoInicio;
  final String? horarioAlmocoFim;
  final String? horarioGestaoInicio;
  final String? horarioGestaoFim;

  HorarioTrabalho({
    required this.id,
    required this.usuarioId,
    required this.diaSemana,
    required this.horarioInicio,
    required this.horarioFim,
    this.horarioAlmocoInicio,
    this.horarioAlmocoFim,
    this.horarioGestaoInicio,
    this.horarioGestaoFim,
  });

  factory HorarioTrabalho.fromJson(Map<String, dynamic> json) {
    return HorarioTrabalho(
      id: json['id'] as int,
      usuarioId: json['usuarioId'] as int,
      diaSemana: json['diaSemana'] as int,
      horarioInicio: json['horarioInicio'] as String,
      horarioFim: json['horarioFim'] as String,
      horarioAlmocoInicio: json['horarioAlmocoInicio'] as String?,
      horarioAlmocoFim: json['horarioAlmocoFim'] as String?,
      horarioGestaoInicio: json['horarioGestaoInicio'] as String?,
      horarioGestaoFim: json['horarioGestaoFim'] as String?,
    );
  }
}