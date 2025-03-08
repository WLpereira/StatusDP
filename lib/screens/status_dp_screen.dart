import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

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
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;
  TimeOfDay? _selectedTime;
  bool _isLoading = true; // Adicionado para controlar o estado de carregamento

  // Horários padrão (padrão inicial: 08:30, 12:00, 13:30, 18:00)
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _loadInitialData();
  }

  // Carrega todos os dados iniciais de forma assíncrona
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadStatuses();
      await _loadUserData();
      await _loadPlanner();
      await _loadHorarioTrabalho();
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
        _selectedStatus = _usuario.status ?? 'DISPONIVEL';
      });
    } catch (e) {
      _showError('Erro ao carregar status: $e');
      setState(() {
        _statuses = [
          Status(id: 1, status: 'DISPONIVEL'),
          Status(id: 2, status: 'AUSENTE'),
          Status(id: 3, status: 'GESTAO'),
        ];
        _selectedStatus = 'DISPONIVEL';
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
          _startTime = _parseTimeOfDay(horario.horarioInicio ?? _usuario.horarioiniciotrabalho ?? '08:30');
          _lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? _usuario.horarioalmocoinicio ?? '12:00');
          _lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? _usuario.horarioalmocofim ?? '13:30');
          _endTime = _parseTimeOfDay(horario.horarioFim ?? _usuario.horariofimtrabalho ?? '18:00');
        } else {
          _startTime = _parseTimeOfDay(_usuario.horarioiniciotrabalho ?? '08:30');
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
        SnackBar(content: Text(message)),
      );
    }
  }

  // Nova função para determinar a cor do grid com base na presença de informação
  Color _getColorForGrid(TimeOfDay time) {
    final informacao = _getInformacaoForTime(time);
    return informacao != null ? Colors.greenAccent : Colors.grey.withOpacity(0.5);
  }

  String? _getInformacaoForTime(TimeOfDay time) {
    final plannerEntry = _planner.firstWhere(
      (p) => DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () {
        if (_statuses.isEmpty) {
          return Planner(
            id: -1,
            usuarioId: -1,
            data: DateTime.now(),
            statusId: 1,
          );
        }
        return Planner(
          id: -1,
          usuarioId: -1,
          data: _selectedDate,
          statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id,
        );
      },
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
    final endInMinutes = _endTime.hour * 60 + _endTime.minute;

    if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
      _showError('Não é possível agendar durante o horário de almoço.');
      return;
    }
    if (timeInMinutes >= endInMinutes) {
      _showError('Não é possível agendar após o fim do expediente.');
      return;
    }

    // Verificar se o horário já passou
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
        timeInMinutes <= currentTimeInMinutes) {
      _showError('Não é possível editar horários já passados.');
      return;
    }

    // Buscar um Planner existente para a data selecionada
    Planner existingPlanner = _planner.firstWhere(
      (p) => DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () {
        if (_statuses.isEmpty) {
          return Planner(
            id: -1,
            usuarioId: -1,
            data: DateTime.now(),
            statusId: 1,
          );
        }
        return Planner(
          id: -1,
          usuarioId: -1,
          data: _selectedDate,
          statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id,
        );
      },
    );

    // Criar listas para os horários e informações existentes
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

    // Procurar o índice do horário que está sendo editado
    int index = horarios.indexOf(timeString);

    if (index != -1) {
      // Se o horário já existe, atualizar a informação correspondente
      informacoes[index] = informacao;
    } else {
      // Se o horário não existe, encontrar um slot vazio para adicionar
      index = horarios.indexWhere((h) => h == null);
      if (index != -1) {
        horarios[index] = timeString;
        informacoes[index] = informacao;
      } else {
        _showError('Não há mais slots disponíveis para agendamento.');
        return;
      }
    }

    // Criar o objeto Planner com os dados atualizados
    Map<String, dynamic> plannerData = {
      'id': existingPlanner.id != -1 ? existingPlanner.id : 0,
      'usuarioid': _usuario.id,
      'data': DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toIso8601String().split('T')[0],
      'statusid': existingPlanner.statusId, // Status não afeta o grid
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
        } else if (field == 'lunchStart') {
          _lunchStartTime = picked;
        } else if (field == 'lunchEnd') {
          _lunchEndTime = picked;
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

    List<TimeOfDay> hours = [];
    for (int h = startHour; h <= endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;
      final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
      final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;

      if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
        continue;
      }

      if (h == _endTime.hour) {
        continue;
      }

      hours.add(time);
    }

    if (hours.isEmpty) {
      print('Aviso: Nenhum horário disponível. startHour: $startHour, endHour: $endHour, lunch: $lunchStartHour-$lunchEndHour');
    }

    return hours;
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
                  // Ícone para indicar o status atual
                  Icon(
                    _selectedStatus == 'DISPONIVEL'
                        ? Icons.check_circle
                        : _selectedStatus == 'AUSENTE'
                            ? Icons.lock
                            : _selectedStatus == 'GESTAO'
                                ? Icons.business
                                : Icons.help,
                    size: 40,
                    color: Colors.white,
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
                      'Almoço: ${_lunchStartTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectTime(context, 'lunchEnd'),
                    child: Text(
                      'Fim Almoço: ${_lunchEndTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectTime(context, 'end'),
                    child: Text(
                      'Fim Expediente: ${_endTime.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                      Wrap(
                        spacing: 2.0,
                        runSpacing: 2.0,
                        children: availableHours.map((time) {
                          final informacao = _getInformacaoForTime(time);
                          final timeInMinutes = time.hour * 60;
                          final isPastHour = DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
                              timeInMinutes <= currentTimeInMinutes;

                          return GestureDetector(
                            onTap: isPastHour
                                ? null
                                : () {
                                    if (informacao != null || timeInMinutes >= (_lunchStartTime.hour * 60 + _lunchStartTime.minute) &&
                                        timeInMinutes < (_lunchEndTime.hour * 60 + _lunchEndTime.minute)) {
                                      _showError('Não é possível agendar ou editar este horário.');
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
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      informacao != null ? Icons.check : Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${time.hour.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (informacao != null)
                                      Text(
                                        informacao,
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                  dropdownColor: Colors.white.withOpacity(0.1),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}