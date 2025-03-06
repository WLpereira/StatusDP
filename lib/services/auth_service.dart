import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:status_dp_app/models/usuario.dart';
import 'package:status_dp_app/models/status.dart';
import 'package:status_dp_app/models/planner.dart';
import 'package:status_dp_app/models/horario_trabalho.dart';
import 'package:status_dp_app/services/status_service.dart'; // Importar StatusService

class AuthService {
  static const String baseUrl = 'http://localhost:5000'; // Ou use o endereço do ngrok, ex.: 'https://<seu-endereco-ngrok>'

  Future<Usuario?> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Usuarios/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'senha': senha,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> userData = jsonDecode(response.body);
      return Usuario.fromJson(userData);
    } else if (response.statusCode == 401) {
      throw Exception('Credenciais inválidas');
    } else {
      throw Exception('Falha ao fazer login: ${response.statusCode}');
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
    final statusService = StatusService();
    return await statusService.getStatuses(); // Usar o StatusService para buscar status
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