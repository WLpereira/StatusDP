import 'package:status_dp_app/models/usuario.dart';

class HorarioTrabalho {
  final int id;
  final int usuarioId;
  final int diaSemana;
  final String horarioInicio;
  final String horarioFim;
  final String? horarioAlmocoInicio;
  final String? horarioAlmocoFim;
  final Usuario? usuario; // Alterado para Usuario? e opcional

  HorarioTrabalho({
    required this.id,
    required this.usuarioId,
    required this.diaSemana,
    required this.horarioInicio,
    required this.horarioFim,
    this.horarioAlmocoInicio,
    this.horarioAlmocoFim,
    this.usuario,
  });

  factory HorarioTrabalho.fromJson(Map<String, dynamic> json) {
    return HorarioTrabalho(
      id: json['id'] as int,
      usuarioId: json['usuarioid'] as int, // Corrigido para 'usuarioid' (nome da coluna no banco)
      diaSemana: json['diasemana'] as int, // Corrigido para 'diasemana'
      horarioInicio: json['horarioinicio'] as String, // Corrigido para 'horarioinicio'
      horarioFim: json['horariofim'] as String, // Corrigido para 'horariofim'
      horarioAlmocoInicio: json['horarioalmocoinicio'] as String?,
      horarioAlmocoFim: json['horarioalmocofim'] as String?,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario'] as Map<String, dynamic>) : null,
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