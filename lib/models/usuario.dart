class Usuario {
  final int id;
  final String email;
  final String senha;
  final String? nome;
  final String? status;
  final String? setor;
  final String? horarioiniciotrabalho;
  final String? horariofimtrabalho;
  final String? horarioalmocoinicio;
  final String? horarioalmocofim;
  final String? horariogestaoinicio;
  final String? horariogestaofim;

  Usuario({
    required this.id,
    required this.email,
    required this.senha,
    this.nome,
    this.status,
    this.setor,
    this.horarioiniciotrabalho,
    this.horariofimtrabalho,
    this.horarioalmocoinicio,
    this.horarioalmocofim,
    this.horariogestaoinicio,
    this.horariogestaofim,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String,
      senha: json['senha'] as String,
      nome: json['nome'] as String?,
      status: json['status'] as String?,
      setor: json['setor'] as String?,
      horarioiniciotrabalho: json['horarioiniciotrabalho'] as String?,
      horariofimtrabalho: json['horariofimtrabalho'] as String?,
      horarioalmocoinicio: json['horarioalmocoinicio'] as String?,
      horarioalmocofim: json['horarioalmocofim'] as String?,
      horariogestaoinicio: json['horariogestaoinicio'] as String?,
      horariogestaofim: json['horariogestaofim'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'senha': senha,
      'nome': nome,
      'status': status,
      'setor': setor,
      'horarioiniciotrabalho': horarioiniciotrabalho,
      'horariofimtrabalho': horariofimtrabalho,
      'horarioalmocoinicio': horarioalmocoinicio,
      'horarioalmocofim': horarioalmocofim,
      'horariogestaoinicio': horariogestaoinicio,
      'horariogestaofim': horariogestaofim,
    };
  }
}