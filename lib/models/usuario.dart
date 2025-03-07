class Usuario {
  final int id;
  final String email;
  final String senha; // Novo campo
  final String? nome;
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
    required this.email,
    required this.senha,
    this.nome,
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
      email: json['email'] as String,
      senha: json['senha'] as String, // Novo campo
      nome: json['nome'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'senha': senha, // Novo campo
      'nome': nome,
      'status': status,
      'setor': setor,
      'horarioInicioTrabalho': horarioInicioTrabalho,
      'horarioFimTrabalho': horarioFimTrabalho,
      'horarioAlmocoInicio': horarioAlmocoInicio,
      'horarioAlmocoFim': horarioAlmocoFim,
      'horarioGestaoInicio': horarioGestaoInicio,
      'horarioGestaoFim': horarioGestaoFim,
    };
  }
}