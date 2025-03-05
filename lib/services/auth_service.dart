import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String apiUrl = 'https://8467-177-105-135-154.ngrok-free.app/api/Usuarios';

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

  // Método para buscar os dados do usuário (nome e setor) após o login
  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?email=$email'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usuarios = jsonDecode(response.body);
        if (usuarios.isNotEmpty) {
          final usuario = usuarios.first;
          return {
            'nome': usuario['nome'] ?? 'Usuário', // Use 'nome' conforme sua API
            'setor': usuario['setor'] ?? 'Não especificado', // Use 'setor' conforme sua API
          };
        }
        return null;
      } else {
        throw Exception('Falha ao buscar dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }
}