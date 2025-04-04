class Status {
  final int id;
  final String status;

  Status({
    required this.id,
    required this.status,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }
}