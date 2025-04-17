import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../models/user_period.dart';
import 'package:intl/intl.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Usuario?> login(String email, String password) async {
    try {
      // Busca o usuário diretamente na tabela usuarios
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('senha', password)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      final usuario = Usuario.fromJson(response.first);
      return usuario;
    } catch (e) {
      if (e.toString().contains('not found')) {
        return null;
      }
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<Usuario?> getUserData(String email) async {
    try {
      final response = await _supabase
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
      await _supabase
          .from('usuarios')
          .update({'status': status})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao atualizar status do usuário: $e');
    }
  }

  Future<void> createUsuario(Usuario usuario) async {
    try {
      await _supabase.from('usuarios').insert({
        'email': usuario.email,
        'nome': usuario.nome,
        'setor': usuario.setor,
        'senha': usuario.senha,
        'status': usuario.status,
        'horarioiniciotrabalho': usuario.horarioiniciotrabalho,
        'horariofimtrabalho': usuario.horariofimtrabalho,
        'horarioalmocoinicio': usuario.horarioalmocoinicio,
        'horarioalmocofim': usuario.horarioalmocofim,
      });
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  Future<void> updateUsuario(Usuario usuario) async {
    try {
      await _supabase.from('usuarios').update({
        'email': usuario.email,
        'nome': usuario.nome,
        'setor': usuario.setor,
        'senha': usuario.senha,
        'status': usuario.status,
        'horarioiniciotrabalho': usuario.horarioiniciotrabalho,
        'horariofimtrabalho': usuario.horariofimtrabalho,
        'horarioalmocoinicio': usuario.horarioalmocoinicio,
        'horarioalmocofim': usuario.horarioalmocofim,
      }).eq('id', usuario.id);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<void> deleteUsuario(int userId) async {
    try {
      // Remove o usuário da tabela 'usuarios' com base no ID
      await _supabase
          .from('usuarios')
          .delete()
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao excluir usuário: $e');
    }
  }

  Future<Usuario> getUserById(int id) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id', id)
          .single();

      if (response == null) {
        throw Exception('Usuário não encontrado para o ID: $id');
      }

      return Usuario.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  Future<void> deleteUserPeriod(int periodId) async {
    try {
      await _supabase
          .from('user_periods')
          .delete()
          .eq('id', periodId);
    } catch (e) {
      throw Exception('Erro ao remover período: $e');
    }
  }

  Future<List<Status>> getStatuses() async {
    try {
      final response = await _supabase.from('status_').select();
      return (response as List).map((json) => Status.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar status: $e');
    }
  }

  Future<List<Planner>> getPlanner(int usuarioId) async {
    try {
      final response = await _supabase
          .from('planner')
          .select()
          .eq('usuarioid', usuarioId);

      return (response as List).map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar planner: $e');
    }
  }

  Future<List<HorarioTrabalho>> getHorarioTrabalho(int usuarioId, int diaSemana) async {
    try {
      final response = await _supabase
          .from('horariotrabalho')
          .select()
          .eq('usuarioid', usuarioId)
          .eq('diasemana', diaSemana);

      return (response as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar horários de trabalho: $e');
    }
  }

  Future<Planner> _getOrCreatePlanner(int usuarioId, int statusId) async {
    try {
      final plannerResponse = await _supabase
          .from('planner')
          .select()
          .eq('usuarioid', usuarioId)
          .maybeSingle();

      if (plannerResponse != null) {
        return Planner.fromJson(plannerResponse);
      }

      final newPlannerResponse = await _supabase
          .from('planner')
          .insert({
            'usuarioid': usuarioId,
            'statusid': statusId,
          })
          .select()
          .single();

      return Planner.fromJson(newPlannerResponse);
    } catch (e) {
      throw Exception('Erro ao buscar ou criar planner: $e');
    }
  }

  Future<void> upsertPlanner(Planner planner, String horario, DateTime data, String? informacao) async {
    try {
      // Busca ou cria o planner para o usuário
      final existingPlanner = await _getOrCreatePlanner(planner.usuarioId, planner.statusId);

      // Obtém todas as entradas atuais
      final entries = existingPlanner.getEntries();

      // Verifica se já existe uma reserva no mesmo horário e data
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(data);
      final hasConflict = entries.any((entry) =>
          entry['horario'] == horario &&
          entry['data'] != null &&
          DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) == selectedDateStr);

      if (hasConflict) {
        throw Exception('Já existe uma reserva neste horário e data.');
      }

      // Conta quantas entradas não nulas existem (considera apenas o campo 'horario')
      int nonNullEntries = entries.where((entry) => entry['horario'] != null).length;

      int indexToUpdate;
      Planner updatedPlanner = existingPlanner; // Variável para armazenar o planner atualizado
      if (nonNullEntries < 30) {
        // Se há menos de 30 entradas, encontra o primeiro slot vazio
        indexToUpdate = entries.indexWhere((entry) => entry['horario'] == null);
        if (indexToUpdate == -1) {
          // Se não houver slot vazio, usa o próximo índice (deve ser menor que 30)
          indexToUpdate = nonNullEntries;
        }
      } else {
        // Se já há 30 entradas, sobrescreve a partir do primeiro slot (horario1)
        // Desloca todas as entradas uma posição para trás e adiciona a nova no último slot
        final List<Map<String, dynamic>> newEntries = [];
        for (int i = 1; i < 30; i++) {
          newEntries.add(entries[i]);
        }
        newEntries.add({'horario': horario, 'data': data, 'informacao': informacao});

        // Atualiza todas as entradas, deslocando-as
        for (int i = 0; i < 29; i++) {
          updatedPlanner = updatedPlanner.updateEntry(
            i,
            horario: newEntries[i]['horario'],
            data: newEntries[i]['data'],
            informacao: newEntries[i]['informacao'],
          );
        }
        indexToUpdate = 29; // Último slot (horario30)
      }

      // Atualiza o slot escolhido
      updatedPlanner = updatedPlanner.updateEntry(
        indexToUpdate,
        horario: horario,
        data: data,
        informacao: informacao,
      );

      // Salva o planner atualizado no banco de dados
      await _supabase
          .from('planner')
          .update(updatedPlanner.toJson())
          .eq('id', updatedPlanner.id);
    } catch (e) {
      throw Exception('Erro ao salvar planner: $e');
    }
  }

  Future<void> deletePlannerEntry(Planner planner, int index) async {
    try {
      // Atualiza o slot para null
      final updatedPlanner = planner.updateEntry(
        index,
        horario: null,
        data: null,
        informacao: null,
      );

      // Salva o planner atualizado no banco de dados
      await _supabase
          .from('planner')
          .update(updatedPlanner.toJson())
          .eq('id', updatedPlanner.id);
    } catch (e) {
      throw Exception('Erro ao remover entrada do planner: $e');
    }
  }

  Future<void> upsertHorarioTrabalho(HorarioTrabalho horario) async {
    try {
      await _supabase.from('horariotrabalho').upsert(horario.toJson());
    } catch (e) {
      throw Exception('Erro ao salvar horário de trabalho: $e');
    }
  }

  Future<List<Usuario>> getAllUsuarios() async {
    try {
      final response = await _supabase.from('usuarios').select();
      return (response as List).map((json) => Usuario.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<void> createStatus(Status status) async {
    try {
      await _supabase.from('status_').insert({
        'status': status.status,
      });
    } catch (e) {
      throw Exception('Erro ao criar status: $e');
    }
  }

  Future<void> updateStatus(Status status) async {
    try {
      await _supabase.from('status_').update({
        'status': status.status,
      }).eq('id', status.id);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  Future<List<Planner>> getAllPlanners() async {
    try {
      final response = await _supabase.from('planner').select();
      return (response as List).map((json) => Planner.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar planners: $e');
    }
  }

  Future<List<HorarioTrabalho>> getAllHorariosTrabalho() async {
    try {
      final response = await _supabase.from('horariotrabalho').select();
      return (response as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar horários de trabalho: $e');
    }
  }

  Future<void> saveUserPeriod(UserPeriod period) async {
    try {
      await _supabase.from('user_periods').insert(period.toJson());
    } catch (e) {
      throw Exception('Erro ao salvar período: $e');
    }
  }

  Future<List<UserPeriod>> getUserPeriods(int usuarioId) async {
    try {
      final response = await _supabase
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
      final response = await _supabase.from('user_periods').select();
      return (response as List).map((json) => UserPeriod.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar todos os períodos: $e');
    }
  }

  Future<void> addUserPeriod(UserPeriod newPeriod) async {
    try {
      final existingPeriods = await getUserPeriods(newPeriod.usuarioId);

      final newStart = DateTime(newPeriod.startDate.year, newPeriod.startDate.month, newPeriod.startDate.day);
      final newEnd = DateTime(newPeriod.endDate.year, newPeriod.endDate.month, newPeriod.endDate.day);

      for (var period in existingPeriods) {
        final periodStart = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
        final periodEnd = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);

        if (!(newEnd.isBefore(periodStart) || newStart.isAfter(periodEnd))) {
          throw Exception(
              'Não é possível cadastrar: o período se sobrepõe a um período existente (${DateFormat('dd/MM/yyyy').format(period.startDate)}-${DateFormat('dd/MM/yyyy').format(period.endDate)}).');
        }
      }

      await saveUserPeriod(newPeriod);
    } catch (e) {
      throw Exception('Erro ao adicionar período de indisponibilidade: $e');
    }
  }
}