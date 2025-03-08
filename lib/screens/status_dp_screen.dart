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

  // Horários padrão (padrão inicial: 08:30, 12:00, 13:30, 18:00)
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30); // Início padrão
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0); // Início almoço
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 30); // Fim almoço
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0); // Fim expediente

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _loadStatuses();
    _loadUserData();
    _loadPlanner();
    _loadHorarioTrabalho();
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _authService.getStatuses();
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      _showError('Erro ao carregar status: $e');
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
        // Se houver horário salvo, atualizar os valores padrão
        if (horarios.isNotEmpty) {
          final horario = horarios.first;
          _startTime = _parseTimeOfDay(horario.horarioInicio ?? '08:30');
          _lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? '12:00');
          _lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? '13:30');
          _endTime = _parseTimeOfDay(horario.horarioFim ?? '18:00');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getStatusForTime(TimeOfDay time) {
    final timeInMinutes = time.hour * 60;
    final startInMinutes = _startTime.hour * 60 + _startTime.minute;
    final endInMinutes = _endTime.hour * 60 + _endTime.minute;
    final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
    final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;

    // Verificar se o slot está fora do expediente
    final slotEndInMinutes = timeInMinutes + 60;
    if (startInMinutes >= slotEndInMinutes || endInMinutes <= timeInMinutes) {
      return 'FORA DO EXPEDIENTE';
    }

    // Verificar se o slot está no horário de almoço
    if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
      return 'ALMOÇO';
    }

    // Buscar o planner para a hora específica
    final plannerEntry = _planner.firstWhere(
      (p) {
        final plannerHour = int.parse(p.hora.split(':')[0]);
        final plannerMinute = int.parse(p.hora.split(':')[1]);
        return plannerHour == time.hour && plannerMinute == 0; // Apenas horas cheias
      },
      orElse: () => Planner(
        id: -1,
        usuarioId: -1,
        data: DateTime.now(),
        hora: '',
        statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id,
        informacao: null,
      ),
    );

    if (plannerEntry.id != -1) {
      final status = _statuses.firstWhere((s) => s.id == plannerEntry.statusId);
      return status.status;
    }

    return 'DISPONIVEL';
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'DISPONIVEL':
        return Colors.grey.withOpacity(0.5);
      case 'AUSENTE':
        return Colors.red.withOpacity(0.5);
      case 'ALMOÇO':
        return Colors.green.withOpacity(0.5);
      case 'GESTAO':
        return Colors.blue.withOpacity(0.5);
      case 'FORA DO EXPEDIENTE':
        return Colors.black.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  bool _isValidStatus(String? status) {
    if (status == null) return false;
    return _statuses.map((s) => s.status).contains(status);
  }

  Future<void> _saveOrUpdateStatus() async {
    if (_selectedTime == null) {
      _showError('Por favor, selecione uma hora na grade.');
      return;
    }
    if (_selectedStatus == null || !_isValidStatus(_selectedStatus)) {
      _showError('Por favor, selecione um status válido.');
      return;
    }

    final timeInMinutes = _selectedTime!.hour * 60;
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

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      0, // Apenas horas cheias
    );

    final statusId = _statuses.firstWhere((s) => s.status == _selectedStatus).id;

    final existingPlanner = _planner.firstWhere(
      (p) {
        final plannerHour = int.parse(p.hora.split(':')[0]);
        final plannerMinute = int.parse(p.hora.split(':')[1]);
        final plannerDate = DateTime.parse(p.data.toString());
        return plannerHour == _selectedTime!.hour &&
            plannerMinute == 0 &&
            plannerDate.day == _selectedDate.day &&
            plannerDate.month == _selectedDate.month &&
            plannerDate.year == _selectedDate.year;
      },
      orElse: () => Planner(
        id: -1,
        usuarioId: -1,
        data: DateTime.now(),
        hora: '',
        statusId: statusId,
        informacao: null,
      ),
    );

    try {
      final updatedPlanner = Planner(
        id: existingPlanner.id != -1 ? existingPlanner.id : 0,
        usuarioId: _usuario.id,
        data: selectedDateTime,
        hora: '${_selectedTime!.hour.toString().padLeft(2, '0')}:00',
        statusId: statusId,
        informacao: existingPlanner.informacao,
      );

      await _authService.upsertPlanner(updatedPlanner);
      _showError('Status salvo com sucesso!');

      await _loadPlanner();
    } catch (e) {
      _showError('Erro ao salvar/atualizar status: $e');
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
    // Calcular o horário de início na hora cheia mais próxima ou igual
    int startHour = _startTime.hour;
    if (_startTime.minute > 0) startHour++; // Começar na próxima hora cheia se houver minutos

    // Horário de fim é a hora cheia anterior ao fim do expediente
    int endHour = _endTime.hour;

    // Converter horários de almoço para horas cheias
    int lunchStartHour = _lunchStartTime.hour;
    int lunchEndHour = _lunchEndTime.hour;

    List<TimeOfDay> hours = [];
    for (int h = startHour; h < endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;
      final lunchStartInMinutes = _lunchStartTime.hour * 60 + _lunchStartTime.minute;
      final lunchEndInMinutes = _lunchEndTime.hour * 60 + _lunchEndTime.minute;

      // Excluir horários que caem dentro do intervalo de almoço
      if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
        continue;
      }

      hours.add(time);
    }

    // Adicionar mensagem de depuração se a lista estiver vazia
    if (hours.isEmpty) {
      print('Aviso: Nenhum horário disponível. startHour: $startHour, endHour: $endHour, lunch: $lunchStartHour-$lunchEndHour');
    }

    return hours;
  }

  @override
  Widget build(BuildContext context) {
    final availableHours = _getAvailableHours();

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
              const Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.white,
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
                final status = _statuses.firstWhere((s) => s.id == p.statusId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        '${p.hora} - ${status.status}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        p.informacao ?? 'Sem informações',
                        style: const TextStyle(color: Colors.white70),
                      ),
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
                          final status = _getStatusForTime(time);

                          return GestureDetector(
                            onTap: () {
                              if (status == 'ALMOÇO' || status == 'FORA DO EXPEDIENTE') {
                                _showError(status == 'ALMOÇO'
                                    ? 'Não é possível agendar durante o horário de almoço.'
                                    : 'Não é possível agendar fora do expediente.');
                                return;
                              }
                              setState(() {
                                _selectedTime = time;
                                _selectedStatus = status;
                              });
                              _showError('Hora selecionada: ${time.format(context)}');
                            },
                            child: Container(
                              width: (MediaQuery.of(context).size.width - 40) / 5 - 2,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getColorForStatus(status),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      status == 'AUSENTE'
                                          ? Icons.lock
                                          : status == 'ALMOÇO'
                                              ? Icons.fastfood
                                              : status == 'FORA DO EXPEDIENTE'
                                                  ? Icons.block
                                                  : Icons.check,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${time.hour.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              ElevatedButton(
                onPressed: _saveOrUpdateStatus,
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
                  'Salvar Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
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