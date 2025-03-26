import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../models/user_period.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'painel_screen.dart';

class StatusDPScreen extends StatefulWidget {
  final Usuario usuario;

  const StatusDPScreen({super.key, required this.usuario});

  @override
  State<StatusDPScreen> createState() => _StatusDPScreenState();
}

class _StatusDPScreenState extends State<StatusDPScreen> {
  final AuthService _authService = AuthService();
  late Usuario _usuario;
  List<Status> _statuses = [];
  List<Planner> _planner = [];
  List<HorarioTrabalho> _horariosTrabalho = [];
  List<UserPeriod> _userPeriods = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;
  bool _isLoading = true;

  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _loadStatuses();
      await _loadUserData();
      await _loadPlanner();
      await _loadHorarioTrabalho();
      final periods = await _authService.getUserPeriods(_usuario.id);
      setState(() {
        _userPeriods = periods;
        _selectedStatus = _usuario.status ?? 'DISPONIVEL';
      });
    } catch (e) {
      _showError('Erro ao carregar dados iniciais: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _authService.getStatuses();
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      _showError('Erro ao carregar status: $e');
      setState(() {
        _statuses = [
          Status(id: 1, status: 'DISPONIVEL'),
          Status(id: 2, status: 'AUSENTE'),
          Status(id: 3, status: 'ALMOCO'),
        ];
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData(_usuario.email);
      setState(() {
        _usuario = userData ?? _usuario;
      });
    } catch (e) {
      _showError('Erro ao carregar dados do usuário: $e');
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
      final horarios = await _authService.getHorarioTrabalho(_usuario.id, _selectedDate.weekday);
      setState(() {
        _horariosTrabalho = horarios;
        if (horarios.isNotEmpty) {
          final horario = horarios.first;
          _startTime = _parseTimeOfDay(horario.horarioInicio ?? _usuario.horarioiniciotrabalho ?? '06:00');
          _lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? _usuario.horarioalmocoinicio ?? '12:00');
          _lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? _usuario.horarioalmocofim ?? '13:30');
          _endTime = _parseTimeOfDay(horario.horarioFim ?? _usuario.horariofimtrabalho ?? '18:00');
        } else {
          _startTime = _parseTimeOfDay(_usuario.horarioiniciotrabalho ?? '06:00');
          _lunchStartTime = _parseTimeOfDay(_usuario.horarioalmocoinicio ?? '12:00');
          _lunchEndTime = _parseTimeOfDay(_usuario.horarioalmocofim ?? '13:30');
          _endTime = _parseTimeOfDay(_usuario.horariofimtrabalho ?? '18:00');
        }
      });
    } catch (e) {
      _showError('Erro ao carregar horários de trabalho: $e');
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color.fromARGB(255, 244, 167, 104),
        ),
      );
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Color _getColorForGrid(TimeOfDay time) {
    final informacoes = _getInformacoesForTime(time);
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final isUnavailable = _isUserUnavailable(date);
    return isUnavailable
        ? Colors.orangeAccent.withOpacity(0.8)
        : (informacoes.isNotEmpty ? const Color.fromARGB(255, 239, 116, 112) : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5));
  }

  List<String?> _getInformacoesForTime(TimeOfDay time) {
    if (_planner.isEmpty) {
      return [];
    }

    final plannerEntry = _planner.first;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return plannerEntry
        .getEntries()
        .where((entry) =>
            entry['horario'] == timeString &&
            entry['data'] != null &&
            DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) == selectedDateStr)
        .map((entry) => entry['informacao'] as String?)
        .toList();
  }

  String? _getPeriodInfoForTime(TimeOfDay time) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final normalizedDate = _normalizeDate(date);
    final period = _userPeriods.cast<UserPeriod?>().firstWhere(
          (p) {
            if (p == null) return false;
            final normalizedStartDate = _normalizeDate(p.startDate);
            final normalizedEndDate = _normalizeDate(p.endDate);
            return (normalizedDate.isAfter(normalizedStartDate) ||
                    normalizedDate.isAtSameMomentAs(normalizedStartDate)) &&
                (normalizedDate.isBefore(normalizedEndDate.add(const Duration(days: 1))) ||
                    normalizedDate.isAtSameMomentAs(normalizedEndDate));
          },
          orElse: () => null,
        );
    if (period != null) {
      return '${period.info} (${DateFormat('dd/MM').format(period.startDate)}-${DateFormat('dd/MM').format(period.endDate)})';
    }
    return null;
  }

  bool _isUserUnavailable(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _userPeriods.any((period) {
      final normalizedStartDate = _normalizeDate(period.startDate);
      final normalizedEndDate = _normalizeDate(period.endDate);
      return (normalizedDate.isAfter(normalizedStartDate) ||
              normalizedDate.isAtSameMomentAs(normalizedStartDate)) &&
          (normalizedDate.isBefore(normalizedEndDate.add(const Duration(days: 1))) ||
              normalizedDate.isAtSameMomentAs(normalizedEndDate));
    });
  }

  bool _isValidStatus(String? status) {
    if (status == null) return false;
    return _statuses.map((s) => s.status).contains(status);
  }

  Future<void> _saveOrUpdateStatus() async {
    if (_selectedStatus == null || !_isValidStatus(_selectedStatus)) {
      _showError('Por favor, selecione um status válido.');
      return;
    }

    try {
      await _authService.updateUserStatus(_usuario.id, _selectedStatus!);
      _showError('Status atualizado com sucesso!');
      await _loadUserData();
    } catch (e) {
      _showError('Erro ao atualizar status: $e');
    }
  }

  Future<void> _saveOrUpdatePlanner(TimeOfDay time, DateTime date, String? informacao) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    final timeInMinutes = time.hour * 60;
    final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
    final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;
    final endInMinutes = _endTime.hour * 60 + _endTime.minute;

    if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
      _showError('Não é possível agendar durante o horário de almoço.');
      return;
    }

    if (timeInMinutes >= endInMinutes) {
      _showError('Não é possível agendar após o fim do expediente.');
      return;
    }

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(date) &&
        timeInMinutes <= currentTimeInMinutes) {
      _showError('Não é possível agendar horários já passados.');
      return;
    }

    if (informacao == null || informacao.isEmpty) {
      _showError('Por favor, insira uma informação para a reserva.');
      return;
    }

    try {
      final planner = _planner.isNotEmpty
          ? _planner.first
          : Planner(
              id: -1,
              usuarioId: _usuario.id,
              statusId: _statuses.isNotEmpty ? _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id : 1,
            );

      await _authService.upsertPlanner(planner, timeString, date, informacao);
      _showError('Reserva adicionada com sucesso!');
      await _loadPlanner();
    } catch (e) {
      _showError('Erro ao adicionar reserva: $e');
    }
  }

  Future<void> _updateHorarioTrabalhoAutomatically({
    TimeOfDay? newStartTime,
    TimeOfDay? newLunchStartTime,
    TimeOfDay? newLunchEndTime,
    TimeOfDay? newEndTime,
  }) async {
    final horario = HorarioTrabalho(
      id: _horariosTrabalho.isNotEmpty ? _horariosTrabalho.first.id : -1,
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
      usuario: null,
    );

    try {
      await _authService.upsertHorarioTrabalho(horario);
      _showError('Horário de trabalho salvo com sucesso!');
      await _loadHorarioTrabalho();
      await _loadPlanner();
    } catch (e) {
      _showError('Erro ao salvar horário de trabalho: $e');
    }
  }

  Future<void> _selectTime(BuildContext context, String field) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: field == 'start'
          ? _startTime
          : field == 'lunchStart'
              ? _lunchStartTime
              : field == 'lunchEnd'
                  ? _lunchEndTime
                  : _endTime,
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
    int startHour = _startTime.hour;
    if (_startTime.minute > 0) startHour++;

    int endHour = _endTime.hour;
    if (_endTime.minute > 0) endHour--;

    int lunchStartHour = _lunchStartTime.hour;
    int lunchEndHour = _lunchEndTime.hour;
    if (_lunchEndTime.minute > 0) lunchEndHour++;

    List<TimeOfDay> hours = [];
    for (int h = startHour; h <= endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;
      final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
      final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;

      if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
        continue;
      }

      hours.add(time);
    }
    return hours;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'DISPONIVEL':
        return Colors.green;
      case 'AUSENTE':
        return Colors.orange;
      case 'ALMOCO':
        return Colors.yellow;
      default:
        return Colors.white;
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
      default:
        return Icons.help;
    }
  }

  void _goToPainel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PainelScreen(usuarioLogado: widget.usuario)),
    ).then((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _requestUserPeriod() async {
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
                    if (startDate == null || endDate == null || infoController.text.isEmpty) {
                      _showError('Por favor, preencha todos os campos.');
                      return;
                    }

                    if (endDate!.isBefore(startDate!)) {
                      _showError('A data final não pode ser anterior à data inicial.');
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
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      extendBody: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 100,
                    color: Colors.white,
                  ),
                  Icon(
                    _getStatusIcon(_selectedStatus),
                    size: 40,
                    color: _getStatusColor(_selectedStatus),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Bem-vindo, ${_usuario.nome ?? _usuario.email}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Setor: ${_usuario.setor ?? "Não especificado"}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // Seção de Status
              const Text(
                'Atualizar Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _isValidStatus(_selectedStatus) ? _selectedStatus : null,
                  hint: const Text(
                    'Alterar Status',
                    style: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) async {
                    if (newValue != null && _isValidStatus(newValue)) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                      await _saveOrUpdateStatus(); // Salva automaticamente ao selecionar
                    }
                  },
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status.status,
                      child: Text(status.status),
                    );
                  }).toSet().toList(),
                ),
              ),
              const SizedBox(height: 40),

              // Seção de Períodos de Indisponibilidade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meus Períodos de Indisponibilidade',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _requestUserPeriod,
                    tooltip: 'Solicitar Período de Indisponibilidade',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_userPeriods.isEmpty)
                const Text(
                  'Nenhum período de indisponibilidade registrado.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ..._userPeriods.map((period) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}: ${period.info}',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _removePeriod(period.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 40),

              // Seção de Planner (Agenda)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Minha Agenda para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
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
                    child: const Text(
                      'Selecionar Data',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_planner.isNotEmpty) ...[
                ..._planner.map((p) {
                  final entries = p.getEntries();
                  final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final filteredEntries = entries
                      .asMap()
                      .entries
                      .where((entry) =>
                          entry.value['horario'] != null &&
                          entry.value['data'] != null &&
                          DateFormat('yyyy-MM-dd').format(entry.value['data'] as DateTime) == selectedDateStr)
                      .map((entry) => {'index': entry.key, 'entry': entry.value})
                      .toList();

                  if (filteredEntries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Nenhuma reserva para este dia.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: filteredEntries.map((item) {
                          final index = item['index'] as int;
                          final entry = item['entry'] as Map<String, dynamic>;
                          final horario = entry['horario'] as String;
                          final informacao = entry['informacao'] as String?;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$horario${informacao != null ? ": $informacao" : ""}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () async {
                                  await _authService.deletePlannerEntry(p, index);
                                  await _loadPlanner();
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),
              ] else
                const Text(
                  'Nenhuma reserva registrada.',
                  style: TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 16),

              // Seção de Horário de Trabalho
              Text(
                'Horário de Trabalho (Dia ${_selectedDate.weekday})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _selectTime(context, 'start'),
                    child: Text(
                      'Início: ${_startTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectTime(context, 'lunchStart'),
                    child: Text(
                      'Almoço Início: ${_lunchStartTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectTime(context, 'lunchEnd'),
                    child: Text(
                      'Almoço Fim: ${_lunchEndTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _selectTime(context, 'end'),
                    child: Text(
                      'Fim: ${_endTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seção de Agendamento (Grid de Horários)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (availableHours.isEmpty)
                      const Text(
                        'Nenhum horário disponível. Verifique os horários de trabalho.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 2.0,
                          runSpacing: 2.0,
                          children: availableHours.map((time) {
                            final informacoes = _getInformacoesForTime(time);
                            final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
                            final isUnavailable = _isUserUnavailable(date);
                            final periodInfo = _getPeriodInfoForTime(time);
                            final timeInMinutes = time.hour * 60;
                            final isPastHour = DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
                                timeInMinutes <= currentTimeInMinutes;

                            return GestureDetector(
                              onTap: (isPastHour || isUnavailable)
                                  ? null
                                  : () {
                                      if (timeInMinutes >= (_lunchStartTime.hour * 60 + _lunchStartTime.minute) &&
                                          timeInMinutes < (_lunchEndTime.hour * 60 + _lunchEndTime.minute)) {
                                        _showError('Não é possível agendar durante o horário de almoço.');
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final controller = TextEditingController();
                                          return AlertDialog(
                                            title: Text('Adicionar Reserva em ${time.hour.toString().padLeft(2, '0')}:00'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: controller,
                                                    maxLength: 10,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Informação da Reserva (máx. 10 caracteres)',
                                                    ),
                                                  ),
                                                  if (informacoes.isNotEmpty) ...[
                                                    const SizedBox(height: 10),
                                                    const Text('Minhas Reservas Existentes:'),
                                                    ...informacoes.asMap().entries.map((entry) {
                                                      final index = entry.key;
                                                      final info = entry.value;
                                                      return Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              info ?? 'Sem informação',
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete, size: 20),
                                                            onPressed: () async {
                                                              if (_planner.isNotEmpty) {
                                                                final planner = _planner.first;
                                                                final entries = planner.getEntries();
                                                                final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                                                final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
                                                                final entryIndex = entries.indexWhere((e) =>
                                                                    e['horario'] == timeString &&
                                                                    e['data'] != null &&
                                                                    DateFormat('yyyy-MM-dd').format(e['data'] as DateTime) == selectedDateStr &&
                                                                    e['informacao'] == info);
                                                                if (entryIndex != -1) {
                                                                  await _authService.deletePlannerEntry(planner, entryIndex);
                                                                  await _loadPlanner();
                                                                  Navigator.pop(context);
                                                                  setState(() {});
                                                                }
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    }),
                                                  ],
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
                                                  if (controller.text.isNotEmpty) {
                                                    await _saveOrUpdatePlanner(time, _selectedDate, controller.text);
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Adicionar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 40) / 5 - 2,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: _getColorForGrid(time),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isUnavailable
                                            ? Icons.lock
                                            : (informacoes.isNotEmpty ? Icons.check : Icons.add),
                                        color: isUnavailable
                                            ? Colors.black
                                            : (informacoes.isNotEmpty ? Colors.white : Colors.black),
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${time.hour.toString().padLeft(2, '0')}:00',
                                        style: TextStyle(
                                          color: isUnavailable ? Colors.black : (informacoes.isNotEmpty ? Colors.white : Colors.white),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          shadows: isUnavailable || informacoes.isNotEmpty
                                              ? [
                                                  const Shadow(
                                                    color: Colors.black26,
                                                    offset: Offset(1.0, 1.0),
                                                    blurRadius: 2.0,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isUnavailable && periodInfo != null)
                                        Text(
                                          periodInfo,
                                          style: const TextStyle(color: Colors.black, fontSize: 10),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        )
                                      else if (informacoes.isNotEmpty)
                                        Text(
                                          informacoes.first ?? '',
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Navegação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _goToPainel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: Colors.green.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Painel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: Colors.redAccent.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Sair',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}  