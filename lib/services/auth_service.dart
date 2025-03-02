import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String apiUrl = 'https://c4b9-2804-431-c7e6-9b27-5136-b699-6ffa-f9d3.ngrok-free.app/api/Usuarios';

  Future<bool> login(String email, String password) async {
    try {
      print('Buscando usuários na API...');

      // Faz uma requisição GET para obter todos os usuários
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Resposta da API: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        // Converte a resposta JSON em uma lista de usuários
        final List<dynamic> usuarios = jsonDecode(response.body);

        // Verifica se há um usuário com o e-mail e senha fornecidos
        final usuario = usuarios.firstWhere(
          (usuario) =>
              usuario['email'] == email && usuario['senha'] == password, // Use 'email' e 'senha' em minúsculas
          orElse: () => null,
        );

        if (usuario != null) {
          print('Usuário encontrado: $usuario');
          return true; // Login bem-sucedido
        } else {
          print('Usuário não encontrado ou senha incorreta.');
          return false; // Login falhou
        }
      } else {
        throw Exception('Falha ao buscar usuários: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }
}