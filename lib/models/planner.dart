class Planner {
  final int id;
  final int usuarioId;
  final DateTime data;
  final int statusId;
  final String? horario1;
  final String? informacao1;
  final String? horario2;
  final String? informacao2;
  final String? horario3;
  final String? informacao3;
  final String? horario4;
  final String? informacao4;
  final String? horario5;
  final String? informacao5;
  final String? horario6;
  final String? informacao6;
  final String? horario7;
  final String? informacao7;
  final String? horario8;
  final String? informacao8;
  final String? horario9;
  final String? informacao9;
  final String? horario10;
  final String? informacao10;

  Planner({
    required this.id,
    required this.usuarioId,
    required this.data,
    required this.statusId,
    this.horario1,
    this.informacao1,
    this.horario2,
    this.informacao2,
    this.horario3,
    this.informacao3,
    this.horario4,
    this.informacao4,
    this.horario5,
    this.informacao5,
    this.horario6,
    this.informacao6,
    this.horario7,
    this.informacao7,
    this.horario8,
    this.informacao8,
    this.horario9,
    this.informacao9,
    this.horario10,
    this.informacao10,
  });

  factory Planner.fromJson(Map<String, dynamic> json) {
    return Planner(
      id: json['id'] as int,
      usuarioId: json['usuarioid'] as int,
      data: DateTime.parse(json['data'] as String),
      statusId: json['statusid'] as int,
      horario1: json['horario1'] as String?,
      informacao1: json['informacao1'] as String?,
      horario2: json['horario2'] as String?,
      informacao2: json['informacao2'] as String?,
      horario3: json['horario3'] as String?,
      informacao3: json['informacao3'] as String?,
      horario4: json['horario4'] as String?,
      informacao4: json['informacao4'] as String?,
      horario5: json['horario5'] as String?,
      informacao5: json['informacao5'] as String?,
      horario6: json['horario6'] as String?,
      informacao6: json['informacao6'] as String?,
      horario7: json['horario7'] as String?,
      informacao7: json['informacao7'] as String?,
      horario8: json['horario8'] as String?,
      informacao8: json['informacao8'] as String?,
      horario9: json['horario9'] as String?,
      informacao9: json['informacao9'] as String?,
      horario10: json['horario10'] as String?,
      informacao10: json['informacao10'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioid': usuarioId,
      'data': data.toIso8601String().split('T')[0],
      'statusid': statusId,
      'horario1': horario1,
      'informacao1': informacao1,
      'horario2': horario2,
      'informacao2': informacao2,
      'horario3': horario3,
      'informacao3': informacao3,
      'horario4': horario4,
      'informacao4': informacao4,
      'horario5': horario5,
      'informacao5': informacao5,
      'horario6': horario6,
      'informacao6': informacao6,
      'horario7': horario7,
      'informacao7': informacao7,
      'horario8': horario8,
      'informacao8': informacao8,
      'horario9': horario9,
      'informacao9': informacao9,
      'horario10': horario10,
      'informacao10': informacao10,
    };
  }
}