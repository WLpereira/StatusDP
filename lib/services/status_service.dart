import 'package:http/http.dart' as http;
import 'dart:convert';

class StatusService {
  final String apiUrl = 'https://c4b9-2804-431-c7e6-9b27-5136-b699-6ffa-f9d3.ngrok-free.app/api/Status_'; // URL da tabela "Status_"

  Future<List<Map<String, dynamic>>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> statuses = jsonDecode(response.body);
        return statuses.map((status) {
          return {
            'id': status['id'], // Mapeia a coluna id (minúsculo)
            'status': status['status'], // Mapeia a coluna status (minúsculo)
          };
        }).toList();
      } else {
        throw Exception('Falha ao carregar status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar status: $e');
    }
  }
}