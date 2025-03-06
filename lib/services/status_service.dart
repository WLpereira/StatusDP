import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:status_dp_app/models/status.dart';

class StatusService {
  static const String apiUrl = 'http://localhost:5000'; // Ou use o endereço do ngrok, ex.: 'https://<seu-endereco-ngrok>'

  Future<List<Status>> getStatuses() async {
    final Uri uri = Uri.parse('$apiUrl/api/Status');

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Resposta da API Status: StatusCode=${response.statusCode}, Body=${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> statuses = jsonDecode(response.body);
        if (statuses.isEmpty) {
          print('Lista vazia retornada pela API');
          return [];
        }

        final List<Status> formattedStatuses = statuses.map((status) {
          return Status(
            id: status['id'] as int? ?? 0, // Usar 0 como valor padrão se nulo
            status: status['status'] as String? ?? 'DISPONIVEL', // Usar "DISPONIVEL" como fallback
          );
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