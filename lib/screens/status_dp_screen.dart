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
      print('Status carregados: $statuses');
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
      });
    } catch (e) {
      _showError('Erro ao carregar horários de trabalho: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getStatusForTime(TimeOfDay time) {
    // Buscar o planner para a hora específica
    final plannerEntry = _planner.firstWhere(
      (p) {
        final plannerHour = int.parse(p.hora.split(':')[0]);
        final plannerMinute = int.parse(p.hora.split(':')[1]);
        return plannerHour == time.hour && plannerMinute == time.minute;
      },
      orElse: () => Planner(
        id: -1,
        usuarioId: -1,
        data: DateTime.now(),
        hora: '',
        statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL', orElse: () => Status(id: 1, status: 'DISPONIVEL')).id,
        informacao: null,
      ),
    );

    // Obter o status a partir do statusId
    if (plannerEntry.id != -1) {
      final status = _statuses.firstWhere((s) => s.id == plannerEntry.statusId, orElse: () => Status(id: 1, status: 'DISPONIVEL'));
      return status.status;
    }

    // Verificar horário de trabalho
    final horario = _horariosTrabalho.firstWhere(
      (h) {
        final startHour = int.parse(h.horarioInicio.split(':')[0]);
        final endHour = int.parse(h.horarioFim.split(':')[0]);
        return time.hour >= startHour && time.hour <= endHour;
      },
      orElse: () => HorarioTrabalho(
        id: -1,
        usuarioId: -1,
        diaSemana: 1,
        horarioInicio: '09:00',
        horarioFim: '17:00',
        horarioAlmocoInicio: '12:00',
        horarioAlmocoFim: '13:00',
        usuario: null,
      ),
    );

    if (horario.id != -1) {
      final almocoStartHour = int.parse(horario.horarioAlmocoInicio?.split(':')[0] ?? '12');
      final almocoStartMinute = int.parse(horario.horarioAlmocoInicio?.split(':')[1] ?? '0');
      final almocoEndHour = int.parse(horario.horarioAlmocoFim?.split(':')[0] ?? '13');
      final almocoEndMinute = int.parse(horario.horarioAlmocoFim?.split(':')[1] ?? '0');

      final timeInMinutes = time.hour * 60 + time.minute;
      final almocoStartInMinutes = almocoStartHour * 60 + almocoStartMinute;
      final almocoEndInMinutes = almocoEndHour * 60 + almocoEndMinute;

      if (timeInMinutes >= almocoStartInMinutes && timeInMinutes < almocoEndInMinutes) {
        return 'ALMOCO';
      }
      return 'DISPONIVEL';
    }
    return 'LICENÇA';
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'DISPONIVEL':
        return Colors.grey.withOpacity(0.5);
      case 'LICENÇA':
        return Colors.red.withOpacity(0.5);
      case 'ALMOCO':
        return Colors.green.withOpacity(0.5);
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

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final statusId = _statuses.firstWhere((s) => s.status == _selectedStatus, orElse: () => Status(id: 1, status: 'DISPONIVEL')).id;

    final existingPlanner = _planner.firstWhere(
      (p) {
        final plannerHour = int.parse(p.hora.split(':')[0]);
        final plannerMinute = int.parse(p.hora.split(':')[1]);
        final plannerDate = DateTime.parse(p.data.toString());
        return plannerHour == _selectedTime!.hour &&
            plannerMinute == _selectedTime!.minute &&
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
        hora: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
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

  @override
  Widget build(BuildContext context) {
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
                        _loadPlanner();
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
                final status = _statuses.firstWhere((s) => s.id == p.statusId, orElse: () => Status(id: 1, status: 'DISPONIVEL'));
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
                'Horários de Trabalho (Dia ${_selectedDate.weekday})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._horariosTrabalho.map((h) => Padding(
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
                          'Horário: ${h.horarioInicio} - ${h.horarioFim}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Almoço: ${h.horarioAlmocoInicio ?? "Não definido"} - ${h.horarioAlmocoFim ?? "Não definido"}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(9, (index) {
                        final hour = 9 + index;
                        return Text(
                          '$hour:00',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 2.0,
                      runSpacing: 2.0,
                      children: List.generate(18, (index) {
                        final hour = 9 + (index ~/ 2);
                        final minute = (index % 2) == 0 ? 0 : 30;
                        final time = TimeOfDay(hour: hour, minute: minute);
                        final status = _getStatusForTime(time);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTime = time;
                              _selectedStatus = status;
                            });
                            _showError('Hora selecionada: ${time.format(context)}');
                          },
                          child: Container(
                            width: (MediaQuery.of(context).size.width - 40) / 9 - 2,
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
                                    status == 'LICENÇA' ? Icons.lock : status == 'ALMOCO' ? Icons.fastfood : Icons.check,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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