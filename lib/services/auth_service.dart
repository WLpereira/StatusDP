import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';

class AuthService {
  Future<Usuario?> login(String email, String senha, BuildContext context) async {
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email.trim())
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado.')),
        );
        return null;
      }

      final usuario = Usuario.fromJson(response);

      if (usuario.senha == senha.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!')),
        );
        return usuario;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha incorretos.')),
        );
        return null;
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
      throw Exception('Erro ao fazer login: $e');
    }
  }

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

  Future<List<Status>> getStatuses() async {
    try {
      final response = await Supabase.instance.client.from('status_').select();
      return response.map((json) => Status.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar status: $e');
      throw Exception('Erro ao carregar status: $e');
    }
  }

  Future<void> updateUserStatus(int userId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'status': newStatus})
          .eq('id', userId);
    } catch (e) {
      print('Erro ao atualizar status do usuário: $e');
      throw Exception('Erro ao atualizar status do usuário: $e');
    }
  }

  Future<List<Planner>> getPlanner(int userId, DateTime date) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      final response = await Supabase.instance.client
          .from('planner')
          .select()
          .eq('usuarioid', userId)
          .eq('data', dateOnly);
      return response.map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar planner: $e');
      throw Exception('Erro ao carregar planner: $e');
    }
  }

  Future<List<HorarioTrabalho>> getHorarioTrabalho(int userId, int diaSemana) async {
    try {
      final response = await Supabase.instance.client
          .from('horariotrabalho')
          .select()
          .eq('usuarioid', userId)
          .eq('diasemana', diaSemana);
      return response.map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar horários de trabalho: $e');
      throw Exception('Erro ao carregar horários de trabalho: $e');
    }
  }

  Future<void> upsertHorarioTrabalho(HorarioTrabalho horario) async {
    try {
      await Supabase.instance.client.from('horariotrabalho').upsert(horario.toJson());
    } catch (e) {
      print('Erro ao salvar horário de trabalho: $e');
      throw Exception('Erro ao salvar horário de trabalho: $e');
    }
  }

  Future<void> upsertPlanner(Planner planner) async {
    try {
      final plannerData = planner.toJson();
      await Supabase.instance.client.from('planner').upsert(plannerData);
    } catch (e) {
      print('Erro ao salvar registro no planner: $e');
      throw Exception('Erro ao salvar registro no planner: $e');
    }
  }

  Future<int?> _getStatusIdFromStatus(String status) async {
    final statuses = await getStatuses();
    final statusObj = statuses.firstWhere(
      (s) => s.status == status,
      orElse: () => Status(id: 1, status: 'DISPONIVEL'),
    );
    return statusObj.id;
  }

  Future<Status?> _getStatusFromId(int statusId) async {
    final statuses = await getStatuses();
    return statuses.firstWhere(
      (s) => s.id == statusId,
      orElse: () => Status(id: 1, status: 'DISPONIVEL'),
    );
  }
}