import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../models/user_period.dart';
import 'login_screen.dart';
import 'painel_screen.dart';
import 'dart:math'; // Adicionado para usar min()
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class StatusDPScreen extends StatefulWidget {
  final Usuario usuario;

  const StatusDPScreen({super.key, required this.usuario});

  @override
  State<StatusDPScreen> createState() => _StatusDPScreenState();
}

class _StatusDPScreenState extends State<StatusDPScreen> {
  late Usuario _usuario;
  List<Status> _statuses = [];
  String? _selectedStatus;
  List<UserPeriod> _userPeriods = [];
  List<Planner> _planner = [];
  List<HorarioTrabalho> _horarioTrabalho = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime =
      const TimeOfDay(hour: 8, minute: 30); // Forçado para 08:30
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 0);
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  late dynamic _subscription; // Para gerenciar as assinaturas em tempo real
  Timer? _plannerRefreshTimer; // Timer para recarregar o planner
  Timer? _statusRefreshTimer; // Timer para atualizar o status

  // Variáveis para replicação
  TimeOfDay? _sourceTime; // Horário de origem para replicação
  String? _sourceInfo; // Informação do horário de origem

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _selectedStatus = _usuario.status;
    _loadInitialData();
    _setupRealtimeSubscriptions(); // Configurar assinaturas em tempo real
    _startPlannerRefreshTimer(); // Iniciar o timer de recarregamento apenas para planner
    _startStatusRefreshTimer(); // Iniciar o timer de atualização do status
  }

  @override
  void dispose() {
    // Cancelar os timers e as assinaturas ao sair da tela
    _plannerRefreshTimer?.cancel();
    _statusRefreshTimer?.cancel();
    Supabase.instance.client.removeChannel(_subscription);
    super.dispose();
  }

  // Iniciar o timer para recarregar o planner a cada 5 segundos (sem atualizar horarioTrabalho)
  void _startPlannerRefreshTimer() {
    _plannerRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _loadPlanner();
    });
  }

  // Iniciar o timer para atualizar o status a cada 3 segundos
  void _startStatusRefreshTimer() {
    _statusRefreshTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _refreshStatus();
    });
  }

  // Função para recarregar o status do usuário
  Future<void> _refreshStatus() async {
    try {
      final updatedUser = await _authService.getUserById(_usuario.id);
      if (mounted) {
        setState(() {
          _selectedStatus = updatedUser.status;
          _usuario = updatedUser; // Atualizar o usuário completo
        });
      }
    } catch (e) {
      print('Erro ao atualizar status: $e');
      _showError('Erro ao atualizar status: $e');
    }
  }

  // Configurar assinaturas em tempo real para as tabelas planner e horarios_trabalho
  void _setupRealtimeSubscriptions() {
    _subscription = Supabase.instance.client
        .channel('public:*')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'planner',
          callback: (payload) => _handlePlannerChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'horarios_trabalho',
          callback: (payload) => _handleHorarioTrabalhoChange(payload),
        )
        .subscribe();
  }

  // Manipular mudanças na tabela planner
  void _handlePlannerChange(PostgresChangePayload payload) {
    if (!mounted) return;
    print('Evento recebido na tabela planner: ${payload.eventType}');
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final newPlanner = Planner.fromJson(payload.newRecord!);
        if (newPlanner.usuarioId == _usuario.id) {
          print('Novo planner inserido para o usuário: ${newPlanner.id}');
          _planner = [
            newPlanner
          ]; // Substitui, já que só queremos o planner do usuário
        }
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedPlanner = Planner.fromJson(payload.newRecord!);
        if (updatedPlanner.usuarioId == _usuario.id) {
          print('Planner atualizado para o usuário: ${updatedPlanner.id}');
          _planner = [updatedPlanner];
        }
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord!['id'] as int;
        if (_planner.isNotEmpty && _planner.first.id == deletedId) {
          print('Planner deletado para o usuário: $deletedId');
          _planner = [];
        }
      }
    });
  }

  // Manipular mudanças na tabela horarios_trabalho
  void _handleHorarioTrabalhoChange(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final newHorario = HorarioTrabalho.fromJson(payload.newRecord!);
        if (newHorario.usuarioId == _usuario.id &&
            newHorario.diaSemana == _selectedDate.weekday) {
          _horarioTrabalho = [newHorario];
          _updateTimesFromHorario(newHorario);
        }
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedHorario = HorarioTrabalho.fromJson(payload.newRecord!);
        if (updatedHorario.usuarioId == _usuario.id &&
            updatedHorario.diaSemana == _selectedDate.weekday) {
          _horarioTrabalho = [updatedHorario];
          _updateTimesFromHorario(updatedHorario);
        }
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord!['id'] as int;
        _horarioTrabalho.removeWhere((h) => h.id == deletedId);
        // Resetar para valores padrão do usuário se o horário foi deletado
        if (_horarioTrabalho.isEmpty) {
          _resetToDefaultTimes();
        }
      }
    });
  }

  // Resetar os horários para os valores padrão do cadastro do usuário
  void _resetToDefaultTimes() {
    _startTime = _parseTimeOfDay(
        _usuario.horarioiniciotrabalho, const TimeOfDay(hour: 8, minute: 30));
    _endTime = _parseTimeOfDay(
        _usuario.horariofimtrabalho, const TimeOfDay(hour: 17, minute: 0));
    _lunchStartTime = _parseTimeOfDay(
        _usuario.horarioalmocoinicio, const TimeOfDay(hour: 12, minute: 0));
    _lunchEndTime = _parseTimeOfDay(
        _usuario.horarioalmocofim, const TimeOfDay(hour: 13, minute: 0));
    debugPrint(
        'Horários resetados para os padrões do usuário: Início ${_startTime.format(context)}, Fim ${_endTime.format(context)}');
  }

  // Atualizar os tempos (_startTime, _endTime, etc.) com base no horário recebido
  void _updateTimesFromHorario(HorarioTrabalho ht) {
    _startTime = _parseTimeOfDay(
        ht.horarioInicio,
        _parseTimeOfDay(_usuario.horarioiniciotrabalho,
            const TimeOfDay(hour: 8, minute: 30)));
    _endTime = _parseTimeOfDay(
        ht.horarioFim,
        _parseTimeOfDay(
            _usuario.horariofimtrabalho, const TimeOfDay(hour: 17, minute: 0)));
    _lunchStartTime = _parseTimeOfDay(
        ht.horarioAlmocoInicio,
        _parseTimeOfDay(_usuario.horarioalmocoinicio,
            const TimeOfDay(hour: 12, minute: 0)));
    _lunchEndTime = _parseTimeOfDay(
        ht.horarioAlmocoFim,
        _parseTimeOfDay(
            _usuario.horarioalmocofim, const TimeOfDay(hour: 13, minute: 0)));
    debugPrint(
        'Horário de Início Atualizado: ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final statuses = await _authService.getStatuses();
      final userPeriods = await _authService.getUserPeriods(_usuario.id);
      await _loadPlanner();
      await _loadHorarioTrabalho();
      setState(() {
        _statuses = statuses;
        _userPeriods = userPeriods;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlanner() async {
    try {
      final planner = await _authService.getPlanner(_usuario.id);
      setState(() {
        _planner = planner;
      });
    } catch (e) {
      _showError('Erro ao carregar planner: $e');
    }
  }

  Future<void> _loadHorarioTrabalho() async {
    try {
      // Primeiro, carregar os horários padrão do usuário
      _resetToDefaultTimes();

      // Em seguida, carregar quaisquer alterações salvas para o dia selecionado
      final horarioTrabalho = await _authService.getHorarioTrabalho(
          _usuario.id, _selectedDate.weekday);
      setState(() {
        _horarioTrabalho = horarioTrabalho;
        if (horarioTrabalho.isNotEmpty) {
          final ht = horarioTrabalho.first;
          _updateTimesFromHorario(ht);
        }
      });
    } catch (e) {
      _showError('Erro ao carregar horário de trabalho: $e');
      // Em caso de erro, manter os horários padrão do usuário
      _resetToDefaultTimes();
    }
  }

  TimeOfDay _parseTimeOfDay(String? timeString, TimeOfDay defaultTime) {
    if (timeString == null || timeString.isEmpty) return defaultTime;
    final parts = timeString.split(':');
    if (parts.length != 2) return defaultTime;
    final hour = int.tryParse(parts[0]) ?? defaultTime.hour;
    final minute = int.tryParse(parts[1]) ?? defaultTime.minute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveOrUpdateStatus() async {
    try {
      await _authService.updateUserStatus(_usuario.id, _selectedStatus!);
      setState(() {
        _usuario = _usuario.copyWith(
          id: _usuario.id,
          nome: _usuario.nome,
          email: _usuario.email,
          setor: _usuario.setor,
          status: _selectedStatus,
          senha: _usuario.senha,
          photoUrl: _usuario.photoUrl,
          horarioiniciotrabalho: _usuario.horarioiniciotrabalho,
          horariofimtrabalho: _usuario.horariofimtrabalho,
          horarioalmocoinicio: _usuario.horarioalmocoinicio,
          horarioalmocofim: _usuario.horarioalmocofim,
        );
      });
    } catch (e) {
      _showError('Erro ao atualizar status: $e');
    }
  }

  Future<void> _saveOrUpdatePlanner(
      TimeOfDay time, DateTime date, String informacao) async {
    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
      final timeInMinutes = time.hour * 60;
      final timeEndInMinutes = (time.hour + 1) * 60;
      final now = DateTime.now();
      final currentTimeInMinutes = now.hour * 60 + now.minute;

      if (DateFormat('yyyy-MM-dd').format(now) ==
              DateFormat('yyyy-MM-dd').format(date) &&
          currentTimeInMinutes >= timeEndInMinutes) {
        _showError('Não é possível agendar horários já passados.');
        return;
      }

      if (_planner.isEmpty) {
        final newPlanner = Planner(id: 0, usuarioId: _usuario.id, statusId: 0);
        await _authService.upsertPlanner(newPlanner, '00:00', date, '');
        await _loadPlanner();
      }

      final planner = _planner.first;
      final entries = planner.getEntries();
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(date);

      // Verificar se já existe uma reserva para o horário e data
      final existingEntryIndex = entries.indexWhere((entry) =>
          entry['horario'] == timeString &&
          entry['data'] != null &&
          DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) ==
              selectedDateStr);

      if (existingEntryIndex != -1) {
        // Se existe uma reserva, deletar a entrada existente antes de criar uma nova
        await _authService.deletePlannerEntry(planner, existingEntryIndex);
        await _loadPlanner();
      }

      // Criar uma nova entrada com a informação atualizada
      await _authService.upsertPlanner(planner, timeString, date, informacao);
      await _loadPlanner();
    } catch (e) {
      _showError('Erro ao salvar reserva: $e');
    }
  }

  Future<void> _updateHorarioTrabalhoAutomatically({
    TimeOfDay? newStartTime,
    TimeOfDay? newEndTime,
    TimeOfDay? newLunchStartTime,
    TimeOfDay? newLunchEndTime,
  }) async {
    try {
      final horarioTrabalho = HorarioTrabalho(
        id: _horarioTrabalho.isNotEmpty ? _horarioTrabalho.first.id : 0,
        usuarioId: _usuario.id,
        diaSemana: _selectedDate.weekday,
        horarioInicio: newStartTime != null
            ? '${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}'
            : '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        horarioFim: newEndTime != null
            ? '${newEndTime.hour.toString().padLeft(2, '0')}:${newEndTime.minute.toString().padLeft(2, '0')}'
            : '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        horarioAlmocoInicio: newLunchStartTime != null
            ? '${newLunchStartTime.hour.toString().padLeft(2, '0')}:${newLunchStartTime.minute.toString().padLeft(2, '0')}'
            : '${_lunchStartTime.hour.toString().padLeft(2, '0')}:${_lunchStartTime.minute.toString().padLeft(2, '0')}',
        horarioAlmocoFim: newLunchEndTime != null
            ? '${newLunchEndTime.hour.toString().padLeft(2, '0')}:${newLunchEndTime.minute.toString().padLeft(2, '0')}'
            : '${_lunchEndTime.hour.toString().padLeft(2, '0')}:${_lunchEndTime.minute.toString().padLeft(2, '0')}',
      );

      await _authService.upsertHorarioTrabalho(horarioTrabalho);
      // A atualização será tratada pela assinatura em tempo real, não precisamos chamar _loadHorarioTrabalho aqui
    } catch (e) {
      _showError('Erro ao atualizar horário de trabalho: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> _getEntriesForDate() {
    if (_planner.isEmpty) return [];
    final planner = _planner.first;
    final entries = planner.getEntries();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return entries
        .asMap()
        .entries
        .where((entry) =>
            entry.value['horario'] != null &&
            entry.value['data'] != null &&
            DateFormat('yyyy-MM-dd').format(entry.value['data'] as DateTime) ==
                selectedDateStr)
        .map((entry) => {
              'index': entry.key,
              'horario': entry.value['horario'] as String,
              'informacao': entry.value['informacao'] as String? ?? '',
            })
        .toList();
  }

  List<String> _getInformacoesForTime(TimeOfDay time) {
    if (_planner.isEmpty) return [];
    final planner = _planner.first;
    final entries = planner.getEntries();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    return entries
        .where((entry) =>
            entry['horario'] == timeString &&
            entry['data'] != null &&
            DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) ==
                selectedDateStr)
        .map((entry) => entry['informacao'] as String? ?? '')
        .toList();
  }

  bool _isUserUnavailable(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _userPeriods.any((period) {
      final startDate = DateTime(
          period.startDate.year, period.startDate.month, period.startDate.day);
      final endDate = DateTime(
          period.endDate.year, period.endDate.month, period.endDate.day);
      return (dateOnly.isAfter(startDate) ||
              dateOnly.isAtSameMomentAs(startDate)) &&
          (dateOnly.isBefore(endDate) || dateOnly.isAtSameMomentAs(endDate));
    });
  }

  String? _getPeriodInfoForTime(TimeOfDay time) {
    final date = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final period = _userPeriods.firstWhere(
      (period) {
        final startDate = DateTime(period.startDate.year,
            period.startDate.month, period.startDate.day);
        final endDate = DateTime(
            period.endDate.year, period.endDate.month, period.endDate.day);
        return (dateOnly.isAfter(startDate) ||
                dateOnly.isAtSameMomentAs(startDate)) &&
            (dateOnly.isBefore(endDate) || dateOnly.isAtSameMomentAs(endDate));
      },
      orElse: () => UserPeriod(
          id: 0,
          usuarioId: 0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          info: ''),
    );
    return period.id != 0 ? period.info : null;
  }

  Color _getColorForGrid(TimeOfDay time) {
    final informacoes = _getInformacoesForTime(time);
    final date = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final isUnavailable = _isUserUnavailable(date);
    final timeInMinutes = time.hour * 60;
    final timeEndInMinutes = (time.hour + 1) * 60;
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final isPastHour = DateFormat('yyyy-MM-dd').format(now) ==
            DateFormat('yyyy-MM-dd').format(_selectedDate) &&
        currentTimeInMinutes >= timeEndInMinutes;

    if (isPastHour) {
      return Colors.grey;
    }
    if (isUnavailable) {
      return Colors.orange;
    }
    if (informacoes.isNotEmpty) {
      return Colors.redAccent;
    }
    if (timeInMinutes >= (_lunchStartTime.hour * 60 + _lunchStartTime.minute) &&
        timeInMinutes < (_lunchEndTime.hour * 60 + _lunchEndTime.minute)) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  Future<void> _selectTime(BuildContext context, String field) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: field == 'start'
          ? _startTime
          : field == 'end'
              ? _endTime
              : field == 'lunchStart'
                  ? _lunchStartTime
                  : _lunchEndTime,
    );
    if (picked != null) {
      setState(() {
        if (field == 'start') {
          _startTime = picked;
          _updateHorarioTrabalhoAutomatically(newStartTime: picked);
        } else if (field == 'lunchStart') {
          _lunchStartTime = picked;
          _updateHorarioTrabalhoAutomatically(newLunchStartTime: picked);
        } else if (field == 'lunchEnd') {
          _lunchEndTime = picked;
          _updateHorarioTrabalhoAutomatically(newLunchEndTime: picked);
        } else if (field == 'end') {
          _endTime = picked;
          _updateHorarioTrabalhoAutomatically(newEndTime: picked);
        }
      });
    }
  }

  List<TimeOfDay> _getAvailableHours() {
    // Calcular a hora de início, arredondando para a próxima hora cheia se houver minutos
    int startHour = _startTime.hour;
    if (_startTime.minute > 0) {
      startHour++;
    }
    debugPrint(
        'Start Hour Calculado: $startHour (a partir de _startTime: ${_startTime.hour}:${_startTime.minute})');

    // Calcular a hora de fim, considerando apenas a hora cheia anterior ao término
    int endHour = _endTime.hour;
    // Se o expediente termina em uma hora cheia (ex.: 18:00), o último horário exibido deve ser a hora anterior (17:00)
    // Se houver minutos (ex.: 18:30), também ajustamos para a hora anterior (17:00)
    endHour--; // Sempre pegamos a hora cheia anterior ao término

    // Calcular os minutos de início e fim do almoço
    int lunchStartMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
    int lunchEndMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;

    List<TimeOfDay> hours = [];
    for (int h = startHour; h <= endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;

      // Ajustar a lógica do intervalo de almoço considerando os minutos
      // Ex.: Se o almoço começa às 13:30, o horário das 13:00 não deve ser exibido
      // Se o almoço termina às 15:00, o próximo horário deve ser 15:00
      if (timeInMinutes >= (lunchStartMinutes - (lunchStartMinutes % 60)) &&
          timeInMinutes < lunchEndMinutes) {
        continue;
      }

      hours.add(time);
    }

    // Se o almoço termina em uma hora cheia (ex.: 15:00), garantir que essa hora seja incluída
    if (lunchEndMinutes % 60 == 0) {
      final lunchEndHour = _lunchEndTime.hour;
      if (lunchEndHour <= endHour &&
          !hours.any((time) => time.hour == lunchEndHour)) {
        hours.add(TimeOfDay(hour: lunchEndHour, minute: 0));
      }
    }

    // Ordenar os horários para garantir a sequência correta
    hours.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return hours;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'DISPONIVEL':
        return Colors.green;
      case 'AUSENTE':
        return Colors.orange;
      case 'ALMOCO':
        return const Color.fromARGB(255, 176, 158, 1);
      case 'OCUPADO':
        return Colors.red;
      default:
        return const Color.fromARGB(255, 105, 181, 248);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'DISPONIVEL':
        return Icons.check_circle;
      case 'AUSENTE':
        return Icons.lock;
      case 'ALMOCO':
        return Icons.local_dining;
      case 'OCUPADO':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  void _goToPainel() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PainelScreen(usuarioLogado: widget.usuario)),
    ).then((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _requestUserI() async {
    DateTime? startDate;
    DateTime? endDate;
    final infoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Solicitar Período de Indisponibilidade'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2026),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Text(
                        startDate == null
                            ? 'Selecionar Data Inicial'
                            : 'Data Inicial: ${DateFormat('dd/MM/yyyy').format(startDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2025),
                          lastDate: DateTime(2026),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'Selecionar Data Final'
                            : 'Data Final: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextField(
                      controller: infoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (ex.: Férias, Licença)',
                      ),
                      maxLength: 20,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (startDate == null ||
                        endDate == null ||
                        infoController.text.isEmpty) {
                      _showError('Por favor, preencha todos os campos.');
                      return;
                    }

                    if (endDate!.isBefore(startDate!)) {
                      _showError(
                          'A data final não pode ser anterior à data inicial.');
                      return;
                    }

                    try {
                      final newPeriod = UserPeriod(
                        id: 0,
                        usuarioId: _usuario.id,
                        startDate: startDate!,
                        endDate: endDate!,
                        info: infoController.text,
                      );

                      await _authService.addUserPeriod(newPeriod);
                      _showError('Solicitação de período enviada com sucesso!');
                      await _loadInitialData();
                      Navigator.pop(context);
                    } catch (e) {
                      _showError('Erro ao solicitar período: $e');
                    }
                  },
                  child: const Text('Solicitar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removePeriod(int periodId) async {
    try {
      await _authService.deleteUserPeriod(periodId);
      _showError('Período removido com sucesso!');
      final updatedPeriods = await _authService.getUserPeriods(_usuario.id);
      setState(() {
        _userPeriods = updatedPeriods;
      });
    } catch (e) {
      _showError('Erro ao remover período: $e');
    }
  }

  String _getGravatarUrl(String email) {
    final emailTrimmed = email.trim().toLowerCase();
    final emailBytes = utf8.encode(emailTrimmed);
    final emailHash = md5.convert(emailBytes).toString();
    return 'https://www.gravatar.com/avatar/$emailHash?s=200&d=identicon';
  }

  // Método para exibir o menu de status no bottom sheet
  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final scaleFactor = min(MediaQuery.of(context).size.width / 400, 1.5);
        return Padding(
          padding: EdgeInsets.all(16.0 * scaleFactor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atualizar Status',
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16 * scaleFactor),
              Wrap(
                spacing: 8 * scaleFactor,
                runSpacing: 8 * scaleFactor,
                children: _statuses.map((status) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _selectedStatus = status.status;
                      });
                      await _saveOrUpdateStatus();
                      Navigator.pop(
                          context); // Fechar o bottom sheet após selecionar
                    },
                    icon: Icon(
                      _getStatusIcon(status.status),
                      size: 16 * scaleFactor,
                      color: Colors.white,
                    ),
                    label: Text(
                      status.status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scaleFactor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedStatus == status.status
                          ? _getStatusColor(status.status)
                          : Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scaleFactor),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scaleFactor,
                        vertical: 8 * scaleFactor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16 * scaleFactor),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fechar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14 * scaleFactor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para exibir o diálogo de seleção de horários para replicação
  Future<void> _showReplicationDialog(
      TimeOfDay sourceTime, String sourceInfo) async {
    final availableHours = _getAvailableHours();
    // Filtrar para excluir apenas o horário de origem
    final selectableHours =
        availableHours.where((time) => time.hour != sourceTime.hour).toList();
    final List<TimeOfDay> selectedTimes = [];

    if (selectableHours.isEmpty) {
      _showError('Não há horários disponíveis para replicar.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final scaleFactor =
                min(MediaQuery.of(context).size.width / 400, 1.5);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scaleFactor),
              ),
              backgroundColor: const Color(0xFF16213E),
              title: Text(
                'Replicar Informação de ${sourceTime.hour}:00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scaleFactor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: selectableHours.map((time) {
                    final isPastHour = DateFormat('yyyy-MM-dd')
                                .format(DateTime.now()) ==
                            DateFormat('yyyy-MM-dd').format(_selectedDate) &&
                        (time.hour * 60 + time.minute) <=
                            (DateTime.now().hour * 60 + DateTime.now().minute);
                    final isUnavailable = _isUserUnavailable(DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        time.hour));

                    return CheckboxListTile(
                      title: Text(
                        '${time.hour}:00',
                        style: TextStyle(
                          color: isPastHour || isUnavailable
                              ? Colors.grey
                              : Colors.white,
                          fontSize: 12 * scaleFactor,
                        ),
                      ),
                      value: selectedTimes.contains(time),
                      onChanged: isPastHour || isUnavailable
                          ? null
                          : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedTimes.add(time);
                                } else {
                                  selectedTimes.remove(time);
                                }
                              });
                            },
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12 * scaleFactor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedTimes.isEmpty) {
                      _showError(
                          'Selecione pelo menos um horário para replicar.');
                      return;
                    }
                    // Replicar a informação para os horários selecionados
                    for (final time in selectedTimes) {
                      await _saveOrUpdatePlanner(
                          time, _selectedDate, sourceInfo);
                    }
                    Navigator.pop(context);
                    _showError('Informação replicada com sucesso!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                    ),
                  ),
                  child: Text(
                    'Replicar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * scaleFactor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final availableHours = _getAvailableHours();
    debugPrint(
        'Horários Disponíveis: ${availableHours.map((time) => time.hour).toList()}');
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final photoUrl = _usuario.photoUrl ?? _getGravatarUrl(_usuario.email);

    // Obter as dimensões da tela para responsividade
    final screenWidth = MediaQuery.of(context).size.width;
    // Fator de escala com limite máximo para evitar elementos muito grandes em desktop
    final scaleFactor = min(screenWidth / 400, 1.5); // Limitado a 1.5
    // Tamanhos base ajustados pelo fator de escala (dimensões originais restauradas)
    final baseWidth = 80 * scaleFactor; // Restaurado de 60 para 80
    final baseHeight = 60 * scaleFactor; // Restaurado de 50 para 60
    final largerWidth = 90 * scaleFactor; // Restaurado de 70 para 90
    final largerHeight = 80 * scaleFactor; // Restaurado de 60 para 80

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _showStatusMenu,
        backgroundColor: _getStatusColor(_selectedStatus),
        child: Icon(
          _getStatusIcon(_selectedStatus),
          color: Colors.white,
          size: 36 * scaleFactor, // Aumentado de 24 para 36
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0F3460),
        padding: EdgeInsets.symmetric(
            vertical: 4 * scaleFactor, horizontal: 10 * scaleFactor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _goToPainel,
                icon: Icon(
                  Icons.dashboard,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 16 * scaleFactor,
                ),
                label: Text(
                  'Painel',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scaleFactor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 29, 142, 255),
                  padding: EdgeInsets.symmetric(vertical: 6 * scaleFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6 * scaleFactor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * scaleFactor),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                icon: Icon(
                  Icons.exit_to_app,
                  color: Colors.white,
                  size: 16 * scaleFactor,
                ),
                label: Text(
                  'Sair',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scaleFactor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 6 * scaleFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6 * scaleFactor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(10.0 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Container(
                  padding: EdgeInsets.all(10.0 * scaleFactor),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F3460),
                        Color(0xFF16213E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10 * scaleFactor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18 * scaleFactor,
                            backgroundImage: NetworkImage(photoUrl),
                            backgroundColor: Colors.grey,
                          ),
                          SizedBox(width: 6 * scaleFactor),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo, ${_usuario.nome ?? _usuario.email}',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Setor: ${_usuario.setor ?? "Não especificado"}',
                                style: TextStyle(
                                  fontSize: 12 * scaleFactor,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        _getStatusIcon(_selectedStatus),
                        size: 20 * scaleFactor,
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12 * scaleFactor),

                // Seção de Períodos de Indisponibilidade
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meus Períodos de Indisponibilidade',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _requestUserI,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 12 * scaleFactor,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Indisponibilidade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10 * scaleFactor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6 * scaleFactor),
                        ),
                        elevation: 5,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scaleFactor,
                          vertical: 4 * scaleFactor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scaleFactor),
                if (_userPeriods.isEmpty)
                  Text(
                    'Nenhum período de indisponibilidade registrado.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10 * scaleFactor,
                    ),
                  )
                else
                  ..._userPeriods.map((period) {
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6 * scaleFactor),
                      ),
                      child: ListTile(
                        title: Text(
                          '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12 * scaleFactor,
                          ),
                        ),
                        subtitle: Text(
                          period.info ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10 * scaleFactor,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 12 * scaleFactor,
                          ),
                          onPressed: () => _removePeriod(period.id),
                        ),
                      ),
                    );
                  }),
                SizedBox(height: 12 * scaleFactor),

                // Seção de Planner (Agenda)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Minha Agenda para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 30 * scaleFactor,
                      ),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2026),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                          await _loadHorarioTrabalho();
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 4 * scaleFactor),
                Builder(
                  builder: (context) {
                    final filteredEntries = _getEntriesForDate();

                    if (filteredEntries.isEmpty) {
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4.0 * scaleFactor),
                        child: Text(
                          'Nenhuma reserva para este dia.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10 * scaleFactor,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: filteredEntries.map((entry) {
                        final index = entry['index'] as int;
                        final horario = entry['horario'] as String;
                        final informacao = entry['informacao'] as String;
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(6 * scaleFactor),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.schedule,
                              color: Colors.white70,
                              size: 12 * scaleFactor,
                            ),
                            title: Text(
                              '$horario${informacao.isNotEmpty ? ": $informacao" : ""}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * scaleFactor,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 12 * scaleFactor,
                              ),
                              onPressed: () async {
                                if (_planner.isNotEmpty) {
                                  final planner = _planner.first;
                                  await _authService.deletePlannerEntry(
                                      planner, index);
                                  await _loadPlanner();
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 12 * scaleFactor),

                // Seção de Horário de Trabalho
                Container(
                  padding: EdgeInsets.all(6 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horário de Trabalho (Dia ${_selectedDate.weekday})',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Wrap(
                        spacing: 8 *
                            scaleFactor, // Espaço horizontal entre os elementos
                        runSpacing:
                            4 * scaleFactor, // Espaço vertical entre as linhas
                        children: [
                          GestureDetector(
                            onTap: () => _selectTime(context, 'start'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.white70,
                                  size: 12 * scaleFactor,
                                ),
                                SizedBox(width: 3 * scaleFactor),
                                Text(
                                  'Início: ${_startTime.format(context)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'lunchStart'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_dining,
                                  color: Colors.white70,
                                  size: 12 * scaleFactor,
                                ),
                                SizedBox(width: 3 * scaleFactor),
                                Text(
                                  'Almoço: ${_lunchStartTime.format(context)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'lunchEnd'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_dining,
                                  color: Colors.white70,
                                  size: 12 * scaleFactor,
                                ),
                                SizedBox(width: 3 * scaleFactor),
                                Text(
                                  'Fim Almoço: ${_lunchEndTime.format(context)}',
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                        255, 244, 244, 244),
                                    fontSize: 10 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'end'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.white70,
                                  size: 12 * scaleFactor,
                                ),
                                SizedBox(width: 3 * scaleFactor),
                                Text(
                                  'Fim: ${_endTime.format(context)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12 * scaleFactor),

                // Seção de Agendamento (Horários Disponíveis)
                Container(
                  padding: EdgeInsets.all(4 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horários Disponíveis',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      if (availableHours.isEmpty)
                        Text(
                          'Nenhum horário disponível. Verifique os horários de trabalho.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10 * scaleFactor,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 1 *
                              scaleFactor, // Espaço horizontal entre os blocos
                          runSpacing: 4 *
                              scaleFactor, // Espaço vertical entre as linhas
                          children: availableHours.asMap().entries.map((entry) {
                            final index = entry.key;
                            final time = entry.value;
                            // Calcular startHour para verificação
                            int startHour = _startTime.hour;
                            if (_startTime.minute > 0) startHour++;
                            // Ignorar horários antes de startHour
                            if (time.hour < startHour) {
                              debugPrint(
                                  'Ignorando horário ${time.hour}:00 (antes de startHour: $startHour)');
                              return const SizedBox
                                  .shrink(); // Não exibe o horário
                            }
                            // Log para depuração
                            debugPrint('Exibindo horário: ${time.hour}:00');
                            final informacoes = _getInformacoesForTime(time);
                            final date = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                time.hour);
                            final isUnavailable = _isUserUnavailable(date);
                            final periodInfo = _getPeriodInfoForTime(time);
                            final timeInMinutes = time.hour * 60;
                            final timeEndInMinutes = (time.hour + 1) * 60;
                            final now = DateTime.now();
                            final currentTimeInMinutes =
                                now.hour * 60 + now.minute;
                            final isPastHour =
                                DateFormat('yyyy-MM-dd').format(now) ==
                                        DateFormat('yyyy-MM-dd')
                                            .format(_selectedDate) &&
                                    currentTimeInMinutes >= timeEndInMinutes;

                            // Determinar o tamanho do bloco com base na presença de informações
                            final hasInfo =
                                informacoes.isNotEmpty || periodInfo != null;
                            final blockWidth =
                                hasInfo ? largerWidth : baseWidth;
                            final blockHeight =
                                hasInfo ? largerHeight : baseHeight;

                            return GestureDetector(
                              onTap: isPastHour || isUnavailable
                                  ? null
                                  : () {
                                      final controller = TextEditingController(
                                        text: informacoes.isNotEmpty
                                            ? informacoes.first
                                            : '',
                                      );
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10 * scaleFactor),
                                            ),
                                            backgroundColor:
                                                const Color(0xFF16213E),
                                            title: Text(
                                              informacoes.isEmpty
                                                  ? 'Adicionar às ${time.hour}:00'
                                                  : 'Editar às ${time.hour}:00',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14 * scaleFactor,
                                              ),
                                            ),
                                            content: TextField(
                                              controller: controller,
                                              maxLength: 10,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12 * scaleFactor,
                                              ),
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Informação (máx. 10 caracteres)',
                                                labelStyle: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10 * scaleFactor,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8 * scaleFactor),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: const BorderSide(
                                                      color: Colors.white30),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8 * scaleFactor),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: const BorderSide(
                                                      color: Colors.green),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8 * scaleFactor),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12 * scaleFactor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (controller.text.isEmpty) {
                                                    _showError(
                                                        'Insira uma informação para a reserva.');
                                                    return;
                                                  }
                                                  // Salvar o horário de origem e a informação
                                                  setState(() {
                                                    _sourceTime = time;
                                                    _sourceInfo =
                                                        controller.text;
                                                  });
                                                  await _saveOrUpdatePlanner(
                                                      time,
                                                      _selectedDate,
                                                      controller.text);
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8 * scaleFactor),
                                                  ),
                                                ),
                                                child: Text(
                                                  informacoes.isEmpty
                                                      ? 'Adicionar'
                                                      : 'Salvar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12 * scaleFactor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (controller.text.isEmpty) {
                                                    _showError(
                                                        'Insira uma informação para replicar.');
                                                    return;
                                                  }
                                                  // Salvar automaticamente o horário clicado antes de abrir o diálogo de replicação
                                                  await _saveOrUpdatePlanner(
                                                      time,
                                                      _selectedDate,
                                                      controller.text);
                                                  // Atualizar _sourceInfo com o texto atual
                                                  setState(() {
                                                    _sourceTime = time;
                                                    _sourceInfo =
                                                        controller.text;
                                                  });
                                                  // Chamar o diálogo de replicação e aguardar sua conclusão
                                                  await _showReplicationDialog(
                                                      time, controller.text);
                                                  // Após a replicação, fechar o diálogo principal
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8 * scaleFactor),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Replicar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12 * scaleFactor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                              child: Container(
                                width: blockWidth,
                                height: blockHeight,
                                decoration: BoxDecoration(
                                  color: _getColorForGrid(time),
                                  borderRadius:
                                      BorderRadius.circular(6 * scaleFactor),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        '${time.hour}:00',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (hasInfo)
                                      Positioned(
                                        bottom: 4 * scaleFactor,
                                        left: 4 * scaleFactor,
                                        right: 4 * scaleFactor,
                                        child: Text(
                                          informacoes.isNotEmpty
                                              ? informacoes.first
                                              : periodInfo!,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10 * scaleFactor,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
