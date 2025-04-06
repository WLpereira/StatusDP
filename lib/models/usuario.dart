class Usuario {
  final int id;
  final String email;
  final String senha;
  final String? nome;
  final String? status;
  final String? setor;
  final String? photoUrl; // Novo campo para a URL da foto
  final String? horarioiniciotrabalho;
  final String? horariofimtrabalho;
  final String? horarioalmocoinicio;
  final String? horarioalmocofim;

  Usuario({
    required this.id,
    required this.email,
    required this.senha,
    this.nome,
    this.status,
    this.setor,
    this.photoUrl,
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
      photoUrl: json['photo_url'] as String?,
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
      'photo_url': photoUrl,
      'horarioiniciotrabalho': horarioiniciotrabalho,
      'horariofimtrabalho': horariofimtrabalho,
      'horarioalmocoinicio': horarioalmocoinicio,
      'horarioalmocofim': horarioalmocofim,
    };
  }

  Usuario copyWith({
    int? id,
    String? email,
    String? senha,
    String? nome,
    String? status,
    String? setor,
    String? photoUrl,
    String? horarioiniciotrabalho,
    String? horariofimtrabalho,
    String? horarioalmocoinicio,
    String? horarioalmocofim,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      nome: nome ?? this.nome,
      status: status ?? this.status,
      setor: setor ?? this.setor,
      photoUrl: photoUrl ?? this.photoUrl,
      horarioiniciotrabalho: horarioiniciotrabalho ?? this.horarioiniciotrabalho,
      horariofimtrabalho: horariofimtrabalho ?? this.horariofimtrabalho,
      horarioalmocoinicio: horarioalmocoinicio ?? this.horarioalmocoinicio,
      horarioalmocofim: horarioalmocofim ?? this.horarioalmocofim,
    );
  }
}