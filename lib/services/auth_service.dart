import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';

class AuthService {
  // Inicializar o Supabase com as credenciais do painel
  Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: 'https://zfmyccxgynlmdspzjith.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmbXljY3hneW5sbWRzcHpqaXRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NDMyMjAsImV4cCI6MjA1NjQxOTIyMH0.IzYoSygScIOGtuMV6VvBi1HY5LhRAu5g-lUpzjKpJiM',
    );
    print('Supabase inicializado com sucesso');
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<Usuario?> login(String email, String senha) async {
    try {
      // Consultar a tabela Usuarios para encontrar um usuário com o e-mail fornecido
      final response = await _client
          .from('Usuarios')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        print('Usuário não encontrado para o e-mail: $email');
        return null; // Usuário não encontrado
      }

      // Converter a resposta para um objeto Usuario
      final usuario = Usuario.fromJson(response);

      // Comparar a senha fornecida com a senha armazenada
      if (usuario.senha == senha) {
        return usuario; // Login bem-sucedido
      } else {
        print('Senha incorreta para o e-mail: $email');
        return null; // Senha incorreta
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<Usuario?> getUserData(String email) async {
    try {
      final userData = await _client
          .from('Usuarios')
          .select()
          .eq('email', email)
          .maybeSingle();
      if (userData != null) {
        return Usuario.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }

  Future<List<Status>> getStatuses() async {
    try {
      final response = await _client.from('Status_').select();
      return response.map((json) => Status.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar status: $e');
      throw Exception('Erro ao carregar status: $e');
    }
  }

  Future<List<Planner>> getPlanner(int userId, DateTime date) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      final response = await _client
          .from('Planner')
          .select()
          .eq('usuarioId', userId)
          .eq('data', dateOnly);
      return response.map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar planner: $e');
      throw Exception('Erro ao carregar planner: $e');
    }
  }

  Future<List<HorarioTrabalho>> getHorarioTrabalho(int userId, int diaSemana) async {
    try {
      final response = await _client
          .from('HorarioTrabalho')
          .select()
          .eq('usuarioId', userId)
          .eq('diaSemana', diaSemana);
      return response.map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar horários de trabalho: $e');
      throw Exception('Erro ao carregar horários de trabalho: $e');
    }
  }

  Future<void> createPlanner(Planner planner) async {
    try {
      final status = await _getStatusIdFromStatus(planner.status);
      if (status == null) {
        throw Exception('Status inválido: ${planner.status}');
      }
      final dateOnly = planner.data.toIso8601String().split('T')[0];
      await _client.from('Planner').insert({
        'usuarioId': planner.usuarioId,
        'data': dateOnly,
        'hora': planner.hora,
        'statusId': status,
        'informacao': planner.informacao,
      });
    } catch (e) {
      print('Erro ao criar registro no planner: $e');
      throw Exception('Erro ao criar registro no planner: $e');
    }
  }

  Future<void> updatePlanner(Planner planner) async {
    try {
      final status = await _getStatusIdFromStatus(planner.status);
      if (status == null) {
        throw Exception('Status inválido: ${planner.status}');
      }
      final dateOnly = planner.data.toIso8601String().split('T')[0];
      await _client.from('Planner').update({
        'usuarioId': planner.usuarioId,
        'data': dateOnly,
        'hora': planner.hora,
        'statusId': status,
        'informacao': planner.informacao,
      }).eq('id', planner.id);
    } catch (e) {
      print('Erro ao atualizar registro no planner: $e');
      throw Exception('Erro ao atualizar registro no planner: $e');
    }
  }

  Future<int?> _getStatusIdFromStatus(String status) async {
    final statuses = await getStatuses();
    final statusObj = statuses.firstWhere(
      (s) => s.status == status,
      orElse: () => Status(id: 0, status: 'DISPONIVEL'),
    );
    return statusObj.id;
  }
}