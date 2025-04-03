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
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 0);
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _selectedStatus = _usuario.status;
    _loadInitialData();
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
      final horarioTrabalho = await _authService.getHorarioTrabalho(_usuario.id, _selectedDate.weekday);
      setState(() {
        _horarioTrabalho = horarioTrabalho;
        if (horarioTrabalho.isNotEmpty) {
          final ht = horarioTrabalho.first;
          _startTime = _parseTimeOfDay(ht.horarioInicio, const TimeOfDay(hour: 8, minute: 0));
          _endTime = _parseTimeOfDay(ht.horarioFim, const TimeOfDay(hour: 17, minute: 0));
          _lunchStartTime = _parseTimeOfDay(ht.horarioAlmocoInicio, const TimeOfDay(hour: 12, minute: 0));
          _lunchEndTime = _parseTimeOfDay(ht.horarioAlmocoFim, const TimeOfDay(hour: 13, minute: 0));
        }
      });
    } catch (e) {
      _showError('Erro ao carregar horário de trabalho: $e');
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
        _usuario = Usuario(
          id: _usuario.id,
          nome: _usuario.nome,
          email: _usuario.email,
          setor: _usuario.setor,
          status: _selectedStatus,
          senha: _usuario.senha,
        );
      });
    } catch (e) {
      _showError('Erro ao atualizar status: $e');
    }
  }

  Future<void> _saveOrUpdatePlanner(TimeOfDay time, DateTime date, String informacao) async {
    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
      final timeInMinutes = time.hour * 60;
      final timeEndInMinutes = (time.hour + 1) * 60; // Fim da janela do horário (ex.: 9:59 para 9:00)
      final now = DateTime.now();
      final currentTimeInMinutes = now.hour * 60 + now.minute;

      // Verifica se o horário está no passado (apenas após o fim da janela do horário)
      if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(date) &&
          currentTimeInMinutes >= timeEndInMinutes) {
        _showError('Não é possível agendar horários já passados.');
        return;
      }

      if (_planner.isEmpty) {
        // Cria um novo Planner se não existir
        final newPlanner = Planner(id: 0, usuarioId: _usuario.id, statusId: 0);
        await _authService.upsertPlanner(newPlanner, '00:00', date, '');
        await _loadPlanner(); // Recarrega a lista de planners
      }

      final planner = _planner.first;
      final entries = planner.getEntries();
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(date);

      // Verifica se já existe uma entrada para o horário e data
      final existingEntryIndex = entries.indexWhere((entry) =>
          entry['horario'] == timeString &&
          entry['data'] != null &&
          DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) == selectedDateStr);

      if (existingEntryIndex != -1) {
        // Se existe uma entrada, atualiza a informação existente
        entries[existingEntryIndex]['informacao'] = informacao;
        await _authService.deletePlannerEntry(planner, existingEntryIndex); // Remove a entrada antiga
        await _authService.upsertPlanner(planner, timeString, date, informacao); // Adiciona a nova entrada atualizada
      } else {
        // Se não existe, cria uma nova entrada
        await _authService.upsertPlanner(planner, timeString, date, informacao);
      }

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
      await _loadHorarioTrabalho();
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
            DateFormat('yyyy-MM-dd').format(entry['data'] as DateTime) == selectedDateStr)
        .map((entry) => entry['informacao'] as String? ?? '')
        .toList();
  }

  bool _isUserUnavailable(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _userPeriods.any((period) {
      final startDate = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final endDate = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      return (dateOnly.isAfter(startDate) || dateOnly.isAtSameMomentAs(startDate)) &&
          (dateOnly.isBefore(endDate) || dateOnly.isAtSameMomentAs(endDate));
    });
  }

  String? _getPeriodInfoForTime(TimeOfDay time) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final period = _userPeriods.firstWhere(
      (period) {
        final startDate = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
        final endDate = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
        return (dateOnly.isAfter(startDate) || dateOnly.isAtSameMomentAs(startDate)) &&
            (dateOnly.isBefore(endDate) || dateOnly.isAtSameMomentAs(endDate));
      },
      orElse: () => UserPeriod(id: 0, usuarioId: 0, startDate: DateTime.now(), endDate: DateTime.now(), info: ''),
    );
    return period.id != 0 ? period.info : null;
  }

  Color _getColorForGrid(TimeOfDay time) {
    final informacoes = _getInformacoesForTime(time);
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
    final isUnavailable = _isUserUnavailable(date);
    final timeInMinutes = time.hour * 60;
    final timeEndInMinutes = (time.hour + 1) * 60;
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final isPastHour = DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
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
      bottomNavigationBar: Container(
        color: const Color(0xFF0F3460),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _goToPainel,
                icon: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'Painel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3460),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(
                  Icons.exit_to_app,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'Sair',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F3460),
                        Color(0xFF16213E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo, ${_usuario.nome ?? _usuario.email}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Setor: ${_usuario.setor ?? "Não especificado"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        _getStatusIcon(_selectedStatus),
                        size: 30,
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                Wrap(
                  spacing: 10,
                  children: _statuses.map((status) {
                    return ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _selectedStatus = status.status;
                        });
                        await _saveOrUpdateStatus();
                      },
                      icon: Icon(
                        _getStatusIcon(status.status),
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        status.status,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedStatus == status.status
                            ? _getStatusColor(status.status)
                            : Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

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
                    ElevatedButton.icon(
                      onPressed: _requestUserI,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Indisponibilidade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
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
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                        subtitle: Text(
                          period.info ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePeriod(period.id),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),

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
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white70),
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

                    return Column(
                      children: filteredEntries.map((item) {
                        final index = item['index'] as int;
                        final entry = item['entry'] as Map<String, dynamic>;
                        final horario = entry['horario'] as String;
                        final informacao = entry['informacao'] as String?;
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.schedule, color: Colors.white70),
                            title: Text(
                              '$horario${informacao != null ? ": $informacao" : ""}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _authService.deletePlannerEntry(p, index);
                                await _loadPlanner();
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ] else
                  const Text(
                    'Nenhuma reserva registrada.',
                    style: TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 20),

                // Seção de Horário de Trabalho
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () => _selectTime(context, 'start'),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  'Início: ${_startTime.format(context)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'lunchStart'),
                            child: Row(
                              children: [
                                const Icon(Icons.local_dining, color: Colors.white70, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  'Almoço: ${_lunchStartTime.format(context)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'lunchEnd'),
                            child: Row(
                              children: [
                                const Icon(Icons.local_dining, color: Colors.white70, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  'Fim Almoço: ${_lunchEndTime.format(context)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, 'end'),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  'Fim: ${_endTime.format(context)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Seção de Agendamento (Grid de Horários)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Horários Disponíveis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (availableHours.isEmpty)
                        const Text(
                          'Nenhum horário disponível. Verifique os horários de trabalho.',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: availableHours.length,
                          itemBuilder: (context, index) {
                            final time = availableHours[index];
                            final informacoes = _getInformacoesForTime(time);
                            final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour);
                            final isUnavailable = _isUserUnavailable(date);
                            final periodInfo = _getPeriodInfoForTime(time);
                            final timeInMinutes = time.hour * 60;
                            final timeEndInMinutes = (time.hour + 1) * 60; // Fim da janela do horário (ex.: 9:59 para 9:00)
                            final now = DateTime.now();
                            final currentTimeInMinutes = now.hour * 60 + now.minute;
                            final isPastHour = DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
                                currentTimeInMinutes >= timeEndInMinutes; // Bloqueia apenas após o fim da janela do horário

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
                                          final controller = TextEditingController(
                                            text: informacoes.isNotEmpty ? informacoes.first : '', // Preenche com a reserva existente, se houver
                                          );
                                          return AlertDialog(
                                            title: Text('Adicionar/Editar Reserva em ${time.hour.toString().padLeft(2, '0')}:00'),
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
                                                              info.isNotEmpty ? info : 'Sem informação',
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
                                                                  controller.text = ''; // Limpa o campo após exclusão
                                                                  Navigator.pop(context); // Fecha o diálogo para reabrir com dados atualizados
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
                                                  final informacao = controller.text.trim();
                                                  if (informacao.isEmpty) {
                                                    _showError('Por favor, insira uma informação para a reserva.');
                                                    return;
                                                  }
                                                  await _saveOrUpdatePlanner(time, _selectedDate, informacao);
                                                  Navigator.pop(context);
                                                  setState(() {});
                                                },
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getColorForGrid(time),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        '${time.hour.toString().padLeft(2, '0')}:00',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isUnavailable && periodInfo != null)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Tooltip(
                                          message: periodInfo,
                                          child: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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