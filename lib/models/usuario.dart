class Usuario {
  final int id;
  final String? nome;
  final String email;
  final String? status;
  final String? setor;
  final String? horarioInicioTrabalho;
  final String? horarioFimTrabalho;
  final String? horarioAlmocoInicio;
  final String? horarioAlmocoFim;
  final String? horarioGestaoInicio;
  final String? horarioGestaoFim;

  Usuario({
    required this.id,
    this.nome,
    required this.email,
    this.status,
    this.setor,
    this.horarioInicioTrabalho,
    this.horarioFimTrabalho,
    this.horarioAlmocoInicio,
    this.horarioAlmocoFim,
    this.horarioGestaoInicio,
    this.horarioGestaoFim,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nome: json['nome'] as String?,
      email: json['email'] as String,
      status: json['status'] as String?,
      setor: json['setor'] as String?,
      horarioInicioTrabalho: json['horarioInicioTrabalho'] as String?,
      horarioFimTrabalho: json['horarioFimTrabalho'] as String?,
      horarioAlmocoInicio: json['horarioAlmocoInicio'] as String?,
      horarioAlmocoFim: json['horarioAlmocoFim'] as String?,
      horarioGestaoInicio: json['horarioGestaoInicio'] as String?,
      horarioGestaoFim: json['horarioGestaoFim'] as String?,
    );
  }
}