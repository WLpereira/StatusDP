import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000'; // Ou use o endereço do ngrok, ex.: 'https://8467-177-105-135-154.ngrok-free.app'

  Future<Usuario?> login(String email, String senha) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/Usuarios'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Resposta da API Login: StatusCode=${response.statusCode}, Body=${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usuarios = jsonDecode(response.body);
        final usuario = usuarios.firstWhere(
          (user) => user['email'] == email && user['senha'] == senha,
          orElse: () => null,
        );

        if (usuario != null) {
          return Usuario.fromJson(usuario);
        } else {
          return null; // Credenciais inválidas
        }
      } else {
        throw Exception('Falha ao fazer login: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<Usuario?> getUserData(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Usuarios?email=$email'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> usuarios = jsonDecode(response.body);
      if (usuarios.isNotEmpty) {
        return Usuario.fromJson(usuarios.first);
      }
      return null;
    } else {
      throw Exception('Falha ao buscar dados do usuário: ${response.statusCode}');
    }
  }

  Future<List<Status>> getStatuses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> statuses = jsonDecode(response.body);
      return statuses.map((json) => Status.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar status: ${response.statusCode}');
    }
  }

  Future<List<Planner>> getPlanner(int userId, DateTime date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Planner?userId=$userId&date=${date.toIso8601String().split('T')[0]}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> plannerList = jsonDecode(response.body);
      return plannerList.map((json) => Planner.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar o planner: ${response.statusCode}');
    }
  }

  Future<List<HorarioTrabalho>> getHorarioTrabalho(int userId, int diaSemana) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/HorarioTrabalho/user/$userId/day/$diaSemana'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> horarios = jsonDecode(response.body);
      return horarios.map((json) => HorarioTrabalho.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar horários de trabalho: ${response.statusCode}');
    }
  }
}