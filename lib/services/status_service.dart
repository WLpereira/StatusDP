import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/status.dart';

class StatusService {
  static const String apiUrl = 'http://localhost:5000/api/Status'; // Corrigido para o endpoint correto

  Future<List<Status>> getStatuses() async {
    final Uri uri = Uri.parse(apiUrl);

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
            id: status['id'] as int? ?? 0,
            status: status['status'] as String? ?? 'DISPONIVEL',
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