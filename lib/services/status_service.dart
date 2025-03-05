import 'package:http/http.dart' as http;
import 'dart:convert';

class StatusService {
  final String apiUrl = 'https://8467-177-105-135-154.ngrok-free.app/api/Status_';

  Future<List<Map<String, dynamic>>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Resposta da API Status: StatusCode=${response.statusCode}, Body=${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> statuses = jsonDecode(response.body);
        if (statuses.isEmpty) {
          print('Lista de status vazia retornada pela API');
          return [];
        }
        final List<Map<String, dynamic>> formattedStatuses = statuses.map((status) {
          return {
            'id': status['id'] as int? ?? 0, // Usa int? para tratar null, com valor padrão 0
            'status': status['status'] as String, // Certifique-se de que é String
          };
        }).toList();
        print('Status carregados: $formattedStatuses');
        return formattedStatuses;
      } else {
        print('Erro HTTP ao carregar status: ${response.statusCode}');
        throw Exception('Falha ao carregar status: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar status: $e');
      throw Exception('Erro ao buscar status: $e');
    }
  }
}