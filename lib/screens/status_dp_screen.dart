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
  TimeOfDay _gestaoStartTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _gestaoEndTime = const TimeOfDay(hour: 15, minute: 0);

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
          Status(id: 4, status: 'GESTAO'),
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
      final planner = await _authService.getPlanner(_usuario.id, _selectedDate);
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
          _gestaoStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? _usuario.horariogestaoinicio ?? '14:00');
          _gestaoEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? _usuario.horariogestaofim ?? '15:00');
        } else {
          _startTime = _parseTimeOfDay(_usuario.horarioiniciotrabalho ?? '06:00');
          _lunchStartTime = _parseTimeOfDay(_usuario.horarioalmocoinicio ?? '12:00');
          _lunchEndTime = _parseTimeOfDay(_usuario.horarioalmocofim ?? '13:30');
          _endTime = _parseTimeOfDay(_usuario.horariofimtrabalho ?? '18:00');
          _gestaoStartTime = _parseTimeOfDay(_usuario.horariogestaoinicio ?? '14:00');
          _gestaoEndTime = _parseTimeOfDay(_usuario.horariogestaofim ?? '15:00');
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
          backgroundColor: const Color.fromARGB(255, 234, 106, 1),
        ),
      );
    }
  }

  Color _getColorForGrid(TimeOfDay time) {
    final informacao = _getInformacaoForTime(time);
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final isUnavailable = _isUserUnavailable(date);
    return isUnavailable ? Colors.orangeAccent.withOpacity(0.8) : (informacao != null ? Colors.greenAccent : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5));
  }

  String? _getInformacaoForTime(TimeOfDay time) {
    final plannerEntry = _planner.firstWhere(
      (p) => DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () => Planner(
        id: -1,
        usuarioId: _usuario.id,
        data: _selectedDate,
        statusId: _statuses.isNotEmpty ? _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id : 1,
      ),
    );

    if (plannerEntry.id != -1) {
      if (plannerEntry.horario1 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao1;
      if (plannerEntry.horario2 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao2;
      if (plannerEntry.horario3 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao3;
      if (plannerEntry.horario4 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao4;
      if (plannerEntry.horario5 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao5;
      if (plannerEntry.horario6 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao6;
      if (plannerEntry.horario7 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao7;
      if (plannerEntry.horario8 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao8;
      if (plannerEntry.horario9 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao9;
      if (plannerEntry.horario10 == '${time.hour.toString().padLeft(2, '0')}:00') return plannerEntry.informacao10;
    }
    return null;
  }

  String? _getPeriodInfoForTime(TimeOfDay time) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final period = _userPeriods.cast<UserPeriod?>().firstWhere(
          (p) => p != null && date.isAfter(p.startDate.subtract(const Duration(days: 1))) && date.isBefore(p.endDate.add(const Duration(days: 1))),
          orElse: () => null,
        );
    if (period != null) {
      return '${period.info} (${DateFormat('dd/MM').format(period.startDate)}-${DateFormat('dd/MM').format(period.endDate)})';
    }
    return null;
  }

  bool _isUserUnavailable(DateTime date) {
    return _userPeriods.any((period) =>
        date.isAfter(period.startDate.subtract(const Duration(days: 1))) && date.isBefore(period.endDate.add(const Duration(days: 1))));
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

  Future<void> _saveOrUpdatePlanner(TimeOfDay time, String? informacao) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    final timeInMinutes = time.hour * 60;
    final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
    final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;
    final gestaoStartInMinutes = _gestaoStartTime.hour * 60 + _gestaoStartTime.minute;
    final gestaoEndInMinutes = _gestaoEndTime.hour * 60 + _gestaoEndTime.minute;
    final endInMinutes = _endTime.hour * 60 + _endTime.minute;

    if ((timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) ||
        (timeInMinutes >= gestaoStartInMinutes && timeInMinutes < gestaoEndInMinutes)) {
      _showError('Não é possível agendar durante o horário de almoço ou gestão.');
      return;
    }

    if (timeInMinutes >= endInMinutes) {
      _showError('Não é possível agendar após o fim do expediente.');
      return;
    }

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
        timeInMinutes <= currentTimeInMinutes) {
      _showError('Não é possível editar horários já passados.');
      return;
    }

    Planner existingPlanner = _planner.firstWhere(
      (p) => DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () => Planner(
        id: -1,
        usuarioId: _usuario.id,
        data: _selectedDate,
        statusId: _statuses.isNotEmpty ? _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id : 1,
      ),
    );

    List<String?> horarios = [
      existingPlanner.horario1,
      existingPlanner.horario2,
      existingPlanner.horario3,
      existingPlanner.horario4,
      existingPlanner.horario5,
      existingPlanner.horario6,
      existingPlanner.horario7,
      existingPlanner.horario8,
      existingPlanner.horario9,
      existingPlanner.horario10,
    ];
    List<String?> informacoes = [
      existingPlanner.informacao1,
      existingPlanner.informacao2,
      existingPlanner.informacao3,
      existingPlanner.informacao4,
      existingPlanner.informacao5,
      existingPlanner.informacao6,
      existingPlanner.informacao7,
      existingPlanner.informacao8,
      existingPlanner.informacao9,
      existingPlanner.informacao10,
    ];

    int index = horarios.indexOf(timeString);
    if (index == -1) {
      index = horarios.indexWhere((h) => h == null);
      if (index == -1) {
        _showError('Limite de 10 horários atingido. Substitua um horário existente.');
        return;
      }
      horarios[index] = timeString;
    }
    informacoes[index] = informacao;

    Map<String, dynamic> plannerData = {
      'id': existingPlanner.id != -1 ? existingPlanner.id : 0,
      'usuarioid': _usuario.id,
      'data': DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toIso8601String().split('T')[0],
      'statusid': existingPlanner.statusId,
      'horario1': horarios[0],
      'informacao1': informacoes[0],
      'horario2': horarios[1],
      'informacao2': informacoes[1],
      'horario3': horarios[2],
      'informacao3': informacoes[2],
      'horario4': horarios[3],
      'informacao4': informacoes[3],
      'horario5': horarios[4],
      'informacao5': informacoes[4],
      'horario6': horarios[5],
      'informacao6': informacoes[5],
      'horario7': horarios[6],
      'informacao7': informacoes[6],
      'horario8': horarios[7],
      'informacao8': informacoes[7],
      'horario9': horarios[8],
      'informacao9': informacoes[8],
      'horario10': horarios[9],
      'informacao10': informacoes[9],
    };

    try {
      await _authService.upsertPlanner(Planner(
        id: plannerData['id'],
        usuarioId: plannerData['usuarioid'],
        data: DateTime.parse(plannerData['data']),
        statusId: plannerData['statusid'],
        horario1: plannerData['horario1'],
        informacao1: plannerData['informacao1'],
        horario2: plannerData['horario2'],
        informacao2: plannerData['informacao2'],
        horario3: plannerData['horario3'],
        informacao3: plannerData['informacao3'],
        horario4: plannerData['horario4'],
        informacao4: plannerData['informacao4'],
        horario5: plannerData['horario5'],
        informacao5: plannerData['informacao5'],
        horario6: plannerData['horario6'],
        informacao6: plannerData['informacao6'],
        horario7: plannerData['horario7'],
        informacao7: plannerData['informacao7'],
        horario8: plannerData['horario8'],
        informacao8: plannerData['informacao8'],
        horario9: plannerData['horario9'],
        informacao9: plannerData['informacao9'],
        horario10: plannerData['horario10'],
        informacao10: plannerData['informacao10'],
      ));
      _showError('Informação salva com sucesso!');
      await _loadPlanner();
    } catch (e) {
      _showError('Erro ao salvar informação: $e');
    }
  }

  Future<void> _updateHorarioTrabalho() async {
    final horario = HorarioTrabalho(
      id: _horariosTrabalho.isNotEmpty ? _horariosTrabalho.first.id : -1,
      usuarioId: _usuario.id,
      diaSemana: _selectedDate.weekday,
      horarioInicio: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      horarioFim: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      horarioAlmocoInicio: '${_lunchStartTime.hour.toString().padLeft(2, '0')}:${_lunchStartTime.minute.toString().padLeft(2, '0')}',
      horarioAlmocoFim: '${_lunchEndTime.hour.toString().padLeft(2, '0')}:${_lunchEndTime.minute.toString().padLeft(2, '0')}',
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
                  : field == 'gestaoStart'
                      ? _gestaoStartTime
                      : field == 'gestaoEnd'
                          ? _gestaoEndTime
                          : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (field == 'start') {
          _startTime = picked;
        } else if (field == 'lunchStart') {
          _lunchStartTime = picked;
        } else if (field == 'lunchEnd') {
          _lunchEndTime = picked;
        } else if (field == 'gestaoStart') {
          _gestaoStartTime = picked;
        } else if (field == 'gestaoEnd') {
          _gestaoEndTime = picked;
        } else if (field == 'end') {
          _endTime = picked;
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

    int gestaoStartHour = _gestaoStartTime.hour;
    int gestaoEndHour = _gestaoEndTime.hour;
    if (_gestaoEndTime.minute > 0) gestaoEndHour++;

    List<TimeOfDay> hours = [];
    for (int h = startHour; h <= endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;
      final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
      final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;
      final gestaoStartInMinutes = _gestaoStartTime.hour * 60 + _gestaoStartTime.minute;
      final gestaoEndInMinutes = _gestaoEndTime.hour * 60 + _gestaoEndTime.minute;

      if ((timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) ||
          (timeInMinutes >= gestaoStartInMinutes && timeInMinutes < gestaoEndInMinutes)) {
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
      case 'GESTAO':
        return Colors.blueAccent;
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
      case 'GESTAO':
        return Icons.business;
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
                        id: 0, // Mantemos como 0, mas o toJson não o incluirá no JSON
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
                  onChanged: (String? newValue) {
                    if (newValue != null && _isValidStatus(newValue)) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
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

              // Seção de Planner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Planner para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
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
                        await _loadPlanner();
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
              ..._planner.map((p) {
                final status = _statuses.firstWhere(
                  (s) => s.id == p.statusId,
                  orElse: () => Status(id: 1, status: 'DISPONIVEL'),
                );
                List<String> entries = [];
                if (p.horario1 != null) entries.add('${p.horario1}${p.informacao1 != null ? ": ${p.informacao1}" : ""}');
                if (p.horario2 != null) entries.add('${p.horario2}${p.informacao2 != null ? ": ${p.informacao2}" : ""}');
                if (p.horario3 != null) entries.add('${p.horario3}${p.informacao3 != null ? ": ${p.informacao3}" : ""}');
                if (p.horario4 != null) entries.add('${p.horario4}${p.informacao4 != null ? ": ${p.informacao4}" : ""}');
                if (p.horario5 != null) entries.add('${p.horario5}${p.informacao5 != null ? ": ${p.informacao5}" : ""}');
                if (p.horario6 != null) entries.add('${p.horario6}${p.informacao6 != null ? ": ${p.informacao6}" : ""}');
                if (p.horario7 != null) entries.add('${p.horario7}${p.informacao7 != null ? ": ${p.informacao7}" : ""}');
                if (p.horario8 != null) entries.add('${p.horario8}${p.informacao8 != null ? ": ${p.informacao8}" : ""}');
                if (p.horario9 != null) entries.add('${p.horario9}${p.informacao9 != null ? ": ${p.informacao9}" : ""}');
                if (p.horario10 != null) entries.add('${p.horario10}${p.informacao10 != null ? ": ${p.informacao10}" : ""}');

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
                      children: entries.map((entry) => Text(
                            entry,
                            style: const TextStyle(color: Colors.white),
                          )).toList(),
                    ),
                  ),
                );
              }),
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
                    onTap: () => _selectTime(context, 'gestaoStart'),
                    child: Text(
                      'Gestão Início: ${_gestaoStartTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectTime(context, 'gestaoEnd'),
                    child: Text(
                      'Gestão Fim: ${_gestaoEndTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
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
                            final informacao = _getInformacaoForTime(time);
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
                                      if ((timeInMinutes >= (_lunchStartTime.hour * 60 + _lunchStartTime.minute) &&
                                              timeInMinutes < (_lunchEndTime.hour * 60 + _lunchEndTime.minute)) ||
                                          (timeInMinutes >= (_gestaoStartTime.hour * 60 + _gestaoStartTime.minute) &&
                                              timeInMinutes < (_gestaoEndTime.hour * 60 + _gestaoEndTime.minute))) {
                                        _showError('Não é possível agendar durante o horário de almoço ou gestão.');
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final controller = TextEditingController(text: informacao ?? '');
                                          return AlertDialog(
                                            title: Text('Editar ${time.hour.toString().padLeft(2, '0')}:00'),
                                            content: TextField(
                                              controller: controller,
                                              maxLength: 10,
                                              decoration: const InputDecoration(
                                                labelText: 'Informação (máx. 10 caracteres)',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _saveOrUpdatePlanner(time, controller.text.isEmpty ? null : controller.text);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Salvar'),
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
                                            : (informacao != null ? Icons.check : Icons.add),
                                        color: isUnavailable
                                            ? Colors.black
                                            : (informacao != null ? Colors.white : Colors.black),
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${time.hour.toString().padLeft(2, '0')}:00',
                                        style: TextStyle(
                                          color: isUnavailable ? Colors.black : (informacao != null ? Colors.white : Colors.white),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          shadows: isUnavailable || informacao != null
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
                                      else if (informacao != null)
                                        Text(
                                          informacao,
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

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveOrUpdateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Salvar Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _updateHorarioTrabalho,
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
                      'Salvar Horários',
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