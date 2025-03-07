import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../services/auth_service.dart';

class PlannerScreen extends StatefulWidget {
  final Usuario usuario;

  const PlannerScreen({super.key, required this.usuario});

  @override
  _PlannerScreenState createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final AuthService _authService = AuthService();
  DateTime _selectedDate = DateTime.now();
  List<Status> _statuses = [];
  int? _selectedStatusId; // Alterado para int? para refletir statusId
  List<Planner> _plannerEntries = [];
  List<HorarioTrabalho> _horarioTrabalho = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _lunchStart = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEnd = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final statuses = await _authService.getStatuses();
    setState(() {
      _statuses = statuses;
      _selectedStatusId = _statuses.firstWhere((s) => s.status == (widget.usuario.status ?? 'DISPONIVEL'), orElse: () => Status(id: 1, status: 'DISPONIVEL')).id;
    });

    final diaSemana = _selectedDate.weekday;
    final horarios = await _authService.getHorarioTrabalho(widget.usuario.id, diaSemana);
    setState(() {
      _horarioTrabalho = horarios;
      if (horarios.isNotEmpty) {
        final horario = horarios.first;
        _startTime = _parseTimeOfDay(horario.horarioInicio);
        _lunchStart = _parseTimeOfDay(horario.horarioAlmocoInicio ?? '12:00');
        _lunchEnd = _parseTimeOfDay(horario.horarioAlmocoFim ?? '13:30');
        _endTime = _parseTimeOfDay(horario.horarioFim);
      } else {
        _startTime = _parseTimeOfDay(widget.usuario.horarioiniciotrabalho ?? '08:30');
        _lunchStart = _parseTimeOfDay(widget.usuario.horarioalmocoinicio ?? '12:00');
        _lunchEnd = _parseTimeOfDay(widget.usuario.horarioalmocofim ?? '13:30');
        _endTime = _parseTimeOfDay(widget.usuario.horariofimtrabalho ?? '18:00');
      }
    });

    await _loadPlanner();
  }

  Future<void> _loadPlanner() async {
    final plannerEntries = await _authService.getPlanner(widget.usuario.id, _selectedDate);
    setState(() {
      _plannerEntries = plannerEntries;
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadInitialData();
    }
  }

  Future<void> _selectTime(BuildContext context, String field) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: field == 'start' ? _startTime : field == 'lunchStart' ? _lunchStart : field == 'lunchEnd' ? _lunchEnd : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (field == 'start') {
          _startTime = picked;
          final startMinutes = picked.hour * 60 + picked.minute;
          final endMinutes = startMinutes + 8 * 60;
          final endHour = (endMinutes ~/ 60) % 24;
          final endMinute = endMinutes % 60;
          _endTime = TimeOfDay(hour: endHour, minute: endMinute);
        } else if (field == 'lunchStart') {
          _lunchStart = picked;
        } else if (field == 'lunchEnd') {
          _lunchEnd = picked;
        }
      });
    }
  }

  Future<void> _saveHorarioTrabalho() async {
    final horario = HorarioTrabalho(
      id: _horarioTrabalho.isNotEmpty ? _horarioTrabalho.first.id : 0,
      diaSemana: _selectedDate.weekday,
      horarioInicio: _formatTimeOfDay(_startTime),
      horarioFim: _formatTimeOfDay(_endTime),
      usuarioId: widget.usuario.id,
      horarioAlmocoInicio: _formatTimeOfDay(_lunchStart),
      horarioAlmocoFim: _formatTimeOfDay(_lunchEnd),
    );
    await _authService.upsertHorarioTrabalho(horario);
    await _loadInitialData();
  }

  List<String> _generateTimeSlots() {
    final List<String> slots = [];
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final lunchStartMinutes = _lunchStart.hour * 60 + _lunchStart.minute;
    final lunchEndMinutes = _lunchEnd.hour * 60 + _lunchEnd.minute;

    for (int minutes = startMinutes; minutes < endMinutes; minutes += 30) {
      final hour = (minutes ~/ 60) % 24;
      final minute = minutes % 60;
      if (minutes >= lunchStartMinutes && minutes < lunchEndMinutes) continue;
      slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    }
    return slots;
  }

  Future<void> _updatePlanner(String time, String? info) async {
    final existingEntry = _plannerEntries.firstWhere(
      (entry) => entry.hora == time,
      orElse: () => Planner(
        id: 0,
        data: _selectedDate,
        hora: time,
        usuarioId: widget.usuario.id,
        statusId: _selectedStatusId ?? 1, // Usar statusId
        informacao: info,
      ),
    );

    if (info != null && info.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informação limitada a 10 caracteres!')),
      );
      return;
    }

    final updatedEntry = Planner(
      id: existingEntry.id,
      data: _selectedDate,
      hora: time,
      usuarioId: widget.usuario.id,
      statusId: _selectedStatusId ?? 1, // Usar statusId
      informacao: info,
    );

    await _authService.upsertPlanner(updatedEntry);
    await _loadPlanner();
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 40),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo, ${widget.usuario.nome ?? 'Usuário'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Setor: ${widget.usuario.setor ?? 'Não informado'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Planner para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text(
                    'Selecionar Data',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Horário de Trabalho',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _selectTime(context, 'start'),
                      child: Text(
                        'Início: ${_formatTimeOfDay(_startTime)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, 'lunchStart'),
                      child: Text(
                        'Almoço: ${_formatTimeOfDay(_lunchStart)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, 'lunchEnd'),
                      child: Text(
                        'Fim Almoço: ${_formatTimeOfDay(_lunchEnd)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.5,
                ),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final time = timeSlots[index];
                  final plannerEntry = _plannerEntries.firstWhere(
                    (entry) => entry.hora == time,
                    orElse: () => Planner(
                      id: 0,
                      data: _selectedDate,
                      hora: time,
                      usuarioId: widget.usuario.id,
                      statusId: _selectedStatusId ?? 1,
                      informacao: '',
                    ),
                  );

                  return Card(
                    color: Colors.white.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          plannerEntry.informacao ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () async {
                            final controller = TextEditingController(text: plannerEntry.informacao ?? '');
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Editar $time'),
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
                                      await _updatePlanner(time, controller.text.isEmpty ? null : controller.text);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Salvar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: _selectedStatusId,
                  hint: const Text('Alterar Status', style: TextStyle(color: Colors.white70)),
                  dropdownColor: Colors.blueGrey,
                  items: _statuses.map((status) {
                    return DropdownMenuItem<int>(
                      value: status.id,
                      child: Text(status.status, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatusId = value;
                      });
                      _authService.updateUserStatus(widget.usuario.id, _statuses.firstWhere((s) => s.id == value).status);
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: _saveHorarioTrabalho,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Salvar Horários'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}