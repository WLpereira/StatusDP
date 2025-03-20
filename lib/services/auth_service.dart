import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../models/user_period.dart';
import 'package:intl/intl.dart';

class AuthService {
  Future<Usuario?> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('senha', password)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Usuario.fromJson(response.first);
    } catch (e) {
      if (e.toString().contains('not found')) {
        return null;
      }
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<Usuario?> getUserData(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Usuario.fromJson(response.first);
    } catch (e) {
      if (e.toString().contains('not found')) {
        return null;
      }
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }

  Future<void> updateUserStatus(int userId, String status) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'status': status})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao atualizar status do usuário: $e');
    }
  }

  Future<void> deleteUserPeriod(int periodId) async {
    try {
      await Supabase.instance.client
          .from('user_periods')
          .delete()
          .eq('id', periodId);
    } catch (e) {
      throw Exception('Erro ao remover período: $e');
    }
  }

  Future<List<Status>> getStatuses() async {
    try {
      final response = await Supabase.instance.client.from('status_').select();
      return (response as List).map((json) => Status.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar status: $e');
    }
  }

  Future<List<Planner>> getPlanner(int usuarioId, DateTime date) async {
    try {
      final response = await Supabase.instance.client
          .from('planner')
          .select()
          .eq('usuarioid', usuarioId)
          .eq('data', date.toIso8601String().split('T')[0]);

      return (response as List).map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar planner: $e');
    }
  }

  Future<List<HorarioTrabalho>> getHorarioTrabalho(int usuarioId, int diaSemana) async {
    try {
      final response = await Supabase.instance.client
          .from('horariotrabalho')
          .select()
          .eq('usuarioid', usuarioId)
          .eq('diasemana', diaSemana);

      return (response as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar horários de trabalho: $e');
    }
  }

  Future<void> upsertPlanner(Planner planner) async {
    try {
      await Supabase.instance.client.from('planner').upsert(planner.toJson());
    } catch (e) {
      throw Exception('Erro ao salvar planner: $e');
    }
  }

  Future<void> upsertHorarioTrabalho(HorarioTrabalho horario) async {
    try {
      await Supabase.instance.client.from('horariotrabalho').upsert(horario.toJson());
    } catch (e) {
      throw Exception('Erro ao salvar horário de trabalho: $e');
    }
  }

  Future<List<Usuario>> getAllUsuarios() async {
    try {
      final response = await Supabase.instance.client.from('usuarios').select();
      return (response as List).map((json) => Usuario.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<void> createUsuario(Usuario usuario) async {
    try {
      await Supabase.instance.client.from('usuarios').insert({
        'email': usuario.email,
        'nome': usuario.nome,
        'setor': usuario.setor,
        'senha': usuario.senha,
        'status': usuario.status,
        'horarioiniciotrabalho': usuario.horarioiniciotrabalho,
        'horariofimtrabalho': usuario.horariofimtrabalho,
        'horarioalmocoinicio': usuario.horarioalmocoinicio,
        'horarioalmocofim': usuario.horarioalmocofim,
        'horariogestaoinicio': usuario.horariogestaoinicio,
        'horariogestaofim': usuario.horariogestaofim,
      });
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  Future<void> updateUsuario(Usuario usuario) async {
    try {
      await Supabase.instance.client.from('usuarios').update({
        'email': usuario.email,
        'nome': usuario.nome,
        'setor': usuario.setor,
        'senha': usuario.senha,
        'status': usuario.status,
        'horarioiniciotrabalho': usuario.horarioiniciotrabalho,
        'horariofimtrabalho': usuario.horariofimtrabalho,
        'horarioalmocoinicio': usuario.horarioalmocoinicio,
        'horarioalmocofim': usuario.horarioalmocofim,
        'horariogestaoinicio': usuario.horariogestaoinicio,
        'horariogestaofim': usuario.horariogestaofim,
      }).eq('id', usuario.id);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<void> createStatus(Status status) async {
    try {
      await Supabase.instance.client.from('status_').insert({
        'status': status.status,
      });
    } catch (e) {
      throw Exception('Erro ao criar status: $e');
    }
  }

  Future<void> updateStatus(Status status) async {
    try {
      await Supabase.instance.client.from('status_').update({
        'status': status.status,
      }).eq('id', status.id);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  Future<List<Planner>> getAllPlanners() async {
    try {
      final response = await Supabase.instance.client.from('planner').select();
      return (response as List).map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar planners: $e');
    }
  }

  Future<List<HorarioTrabalho>> getAllHorariosTrabalho() async {
    try {
      final response = await Supabase.instance.client.from('horariotrabalho').select();
      return (response as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar horários de trabalho: $e');
    }
  }

  Future<void> saveUserPeriod(UserPeriod period) async {
    try {
      await Supabase.instance.client.from('user_periods').insert(period.toJson());
    } catch (e) {
      throw Exception('Erro ao salvar período: $e');
    }
  }

  Future<List<UserPeriod>> getUserPeriods(int usuarioId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_periods')
          .select()
          .eq('usuarioid', usuarioId);

      return (response as List).map((json) => UserPeriod.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar períodos: $e');
    }
  }

  Future<List<UserPeriod>> getAllUserPeriods() async {
    try {
      final response = await Supabase.instance.client.from('user_periods').select();
      return (response as List).map((json) => UserPeriod.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar todos os períodos: $e');
    }
  }

  // Novo método para adicionar um período de indisponibilidade com verificação de sobreposição
  Future<void> addUserPeriod(UserPeriod newPeriod) async {
    try {
      // Obtém todos os períodos de indisponibilidade existentes para o usuário
      final existingPeriods = await getUserPeriods(newPeriod.usuarioId);

      // Normaliza as datas do novo período
      final newStart = DateTime(newPeriod.startDate.year, newPeriod.startDate.month, newPeriod.startDate.day);
      final newEnd = DateTime(newPeriod.endDate.year, newPeriod.endDate.month, newPeriod.endDate.day);

      // Verifica se há sobreposição com períodos existentes
      for (var period in existingPeriods) {
        final periodStart = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
        final periodEnd = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);

        // Verifica se há sobreposição de datas
        if (!(newEnd.isBefore(periodStart) || newStart.isAfter(periodEnd))) {
          throw Exception(
              'Não é possível cadastrar: o período se sobrepõe a um período existente (${DateFormat('dd/MM/yyyy').format(period.startDate)}-${DateFormat('dd/MM/yyyy').format(period.endDate)}).');
        }
      }

      // Se não houver sobreposição, salva o novo período
      await saveUserPeriod(newPeriod);
    } catch (e) {
      throw Exception('Erro ao adicionar período de indisponibilidade: $e');
    }
  }
}