import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';

class AuthService {
  // Método de login manual consultando a tabela 'usuarios'
  Future<Usuario?> login(String email, String senha, BuildContext context) async {
    try {
      // Consultar a tabela 'usuarios' para encontrar um usuário com o e-mail fornecido
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email.trim())
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado.')),
        );
        return null; // Usuário não encontrado
      }

      // Converter a resposta para um objeto Usuario
      final usuario = Usuario.fromJson(response);

      // Comparar a senha fornecida com a senha armazenada
      if (usuario.senha == senha.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!')),
        );
        return usuario; // Login bem-sucedido
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha incorretos.')),
        );
        return null; // Senha incorreta
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // Buscar dados do usuário pelo e-mail
  Future<Usuario?> getUserData(String email) async {
    try {
      final userData = await Supabase.instance.client
          .from('usuarios')
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

  // Buscar lista de status
  Future<List<Status>> getStatuses() async {
    try {
      final response = await Supabase.instance.client.from('Status_').select();
      return response.map((json) => Status.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar status: $e');
      throw Exception('Erro ao carregar status: $e');
    }
  }

  // Buscar planner para um usuário em uma data específica
  Future<List<Planner>> getPlanner(int userId, DateTime date) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      final response = await Supabase.instance.client
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

  // Buscar horários de trabalho para um usuário em um dia da semana
  Future<List<HorarioTrabalho>> getHorarioTrabalho(int userId, int diaSemana) async {
    try {
      final response = await Supabase.instance.client
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

  // Criar um novo registro no Planner
  Future<void> createPlanner(Planner planner) async {
    try {
      final status = await _getStatusIdFromStatus(planner.status);
      if (status == null) {
        throw Exception('Status inválido: ${planner.status}');
      }
      final dateOnly = planner.data.toIso8601String().split('T')[0];
      await Supabase.instance.client.from('Planner').insert({
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

  // Atualizar um registro no Planner
  Future<void> updatePlanner(Planner planner) async {
    try {
      final status = await _getStatusIdFromStatus(planner.status);
      if (status == null) {
        throw Exception('Status inválido: ${planner.status}');
      }
      final dateOnly = planner.data.toIso8601String().split('T')[0];
      await Supabase.instance.client.from('Planner').update({
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

  // Obter o ID de um status a partir do nome
  Future<int?> _getStatusIdFromStatus(String status) async {
    final statuses = await getStatuses();
    final statusObj = statuses.firstWhere(
      (s) => s.status == status,
      orElse: () => Status(id: 1, status: 'DISPONIVEL'), // ID padrão
    );
    return statusObj.id;
  }
}