class Usuario {
  final int id;
  final String email;
  final String senha;
  final String? nome;
  final String? status;
  final String? setor;
  final String? horarioiniciotrabalho; // Corrigido para 'horarioiniciotrabalho'
  final String? horariofimtrabalho; // Corrigido para 'horariofimtrabalho'
  final String? horarioalmocoinicio; // Corrigido para 'horarioalmocoinicio'
  final String? horarioalmocofim; // Corrigido para 'horarioalmocofim'

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
    };
  }
}