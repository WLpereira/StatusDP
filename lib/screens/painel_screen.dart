import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../models/user_period.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'status_dp_screen.dart';
import 'admin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PainelScreen extends StatefulWidget {
  final Usuario usuarioLogado;

  const PainelScreen({super.key, required this.usuarioLogado});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final AuthService _authService = AuthService();
  List<Usuario> _usuarios = [];
  List<Status> _statuses = [];
  List<Planner> _planners = [];
  List<HorarioTrabalho> _horariosTrabalho = [];
  List<UserPeriod> _userPeriods = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _loadStatuses();
      await _loadUsuarios();
      await _loadPlanners();
      await _loadHorariosTrabalho();
      await _loadUserPeriods();
    } catch (e, stackTrace) {
      print('Erro ao carregar dados iniciais: $e\n$stackTrace');
      _showMessage('Erro ao carregar dados: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _authService.getStatuses();
      if (mounted) {
        setState(() {
          _statuses = statuses;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar statuses: $e\n$stackTrace');
      _showMessage('Erro ao carregar status: $e', isError: true);
    }
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await _authService.getAllUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar usuários: $e\n$stackTrace');
      _showMessage('Erro ao carregar usuários: $e', isError: true);
    }
  }

  Future<void> _loadPlanners() async {
    try {
      final planners = await _authService.getAllPlanners();
      if (mounted) {
        setState(() {
          _planners = planners;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar planners: $e\n$stackTrace');
      _showMessage('Erro ao carregar planners: $e', isError: true);
    }
  }

  Future<void> _loadHorariosTrabalho() async {
    try {
      final horarios = await _authService.getAllHorariosTrabalho();
      if (mounted) {
        setState(() {
          _horariosTrabalho = horarios;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar horários de trabalho: $e\n$stackTrace');
      _showMessage('Erro ao carregar horários de trabalho: $e', isError: true);
    }
  }

  Future<void> _loadUserPeriods() async {
    try {
      final periods = await _authService.getAllUserPeriods();
      if (mounted) {
        setState(() {
          _userPeriods = periods;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar períodos: $e\n$stackTrace');
      _showMessage('Erro ao carregar períodos: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  int _getNextPlannerId() {
    if (_planners.isEmpty) {
      return 1;
    }
    final maxId = _planners.map((p) => p.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  List<Map<String, dynamic>> _getPlannerEntriesForUserAndDate(int usuarioId) {
    try {
      final planner = _planners.firstWhere(
        (p) => p.usuarioId == usuarioId,
        orElse: () => Planner(
          id: _getNextPlannerId(),
          usuarioId: usuarioId,
          statusId: 1,
        ),
      );

      final entries = planner.getEntries();
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      return entries
          .asMap()
          .entries
          .where((entry) =>
              entry.value['horario'] != null &&
              entry.value['data'] != null &&
              DateFormat('yyyy-MM-dd').format(entry.value['data'] as DateTime) == selectedDateStr)
          .map((entry) => {
                'index': entry.key,
                'horario': entry.value['horario'],
                'informacao': entry.value['informacao'],
                'data': entry.value['data'],
              })
          .toList();
    } catch (e, stackTrace) {
      print('Erro ao obter entradas do planner: $e\n$stackTrace');
      return [];
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Map<String, dynamic>> _getAvailableHoursForUser(int usuarioId) {
    try {
      final horario = _horariosTrabalho.firstWhere(
        (h) => h.usuarioId == usuarioId && h.diaSemana == _selectedDate.weekday,
        orElse: () {
          final usuario = _usuarios.firstWhere(
            (u) => u.id == usuarioId,
            orElse: () => Usuario(
              id: usuarioId,
              email: '',
              senha: '',
              horarioiniciotrabalho: '06:00',
              horariofimtrabalho: '18:00',
              horarioalmocoinicio: '12:00',
              horarioalmocofim: '13:30',
            ),
          );
          return HorarioTrabalho(
            id: -1,
            usuarioId: usuarioId,
            diaSemana: _selectedDate.weekday,
            horarioInicio: usuario.horarioiniciotrabalho ?? '06:00',
            horarioFim: usuario.horariofimtrabalho ?? '18:00',
            horarioAlmocoInicio: usuario.horarioalmocoinicio ?? '12:00',
            horarioAlmocoFim: usuario.horarioalmocofim ?? '13:30',
          );
        },
      );

      final String startTimeStr = horario.horarioInicio ?? '06:00';
      final String endTimeStr = horario.horarioFim ?? '18:00';
      final String lunchStartTimeStr = horario.horarioAlmocoInicio ?? '12:00';
      final String lunchEndTimeStr = horario.horarioAlmocoFim ?? '13:30';

      final startTime = _parseTimeOfDay(startTimeStr);
      final endTime = _parseTimeOfDay(endTimeStr);
      final lunchStartTime = _parseTimeOfDay(lunchStartTimeStr);
      final lunchEndTime = _parseTimeOfDay(lunchEndTimeStr);

      int startHour = startTime.hour;
      if (startTime.minute > 0) startHour++;

      int endHour = endTime.hour;
      if (endTime.minute > 0) endHour--;

      int lunchStartHour = lunchStartTime.hour;
      int lunchEndHour = lunchEndTime.hour;
      if (lunchEndTime.minute > 0) lunchEndHour++;

      List<Map<String, dynamic>> hours = [];
      for (int h = startHour; h <= endHour; h++) {
        final time = TimeOfDay(hour: h, minute: 0);
        final timeInMinutes = h * 60;
        final lunchStartInMinutes = lunchStartTime.hour * 60 + lunchStartTime.minute;
        final lunchEndInMinutes = lunchEndTime.hour * 60 + lunchEndTime.minute;

        if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
          continue;
        }

        final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, h);
        final normalizedDate = _normalizeDate(date);
        final isUnavailable = _userPeriods.any((period) {
          final normalizedStartDate = _normalizeDate(period.startDate);
          final normalizedEndDate = _normalizeDate(period.endDate);
          return period.usuarioId == usuarioId &&
              (normalizedDate.isAfter(normalizedStartDate) ||
                  normalizedDate.isAtSameMomentAs(normalizedStartDate)) &&
              (normalizedDate.isBefore(normalizedEndDate.add(const Duration(days: 1))) ||
                  normalizedDate.isAtSameMomentAs(normalizedEndDate));
        });

        hours.add({
          'time': time,
          'isUnavailable': isUnavailable,
          'endHour': endHour,
        });
      }
      return hours;
    } catch (e, stackTrace) {
      print('Erro ao obter horários disponíveis: $e\n$stackTrace');
      return [];
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e, stackTrace) {
      print('Erro ao parsear TimeOfDay: $e\n$stackTrace');
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  bool _podeEditar(int usuarioId, Map<String, dynamic> hour, Map<String, dynamic>? entry) {
    if (widget.usuarioLogado.email == 'adm@dataplace.com.br') {
      return true;
    }

    if (widget.usuarioLogado.id != usuarioId) {
      return false;
    }

    if (entry == null) return true;

    final DateTime agora = DateTime.now();
    final DateTime? data = _selectedDate;
    final String? horario = entry['horario'] as String?;

    if (data == null || horario == null) return false;

    final List<String> horarioPartes = horario.split(':');
    final DateTime dataHorario = DateTime(
      data.year,
      data.month,
      data.day,
      int.parse(horarioPartes[0]),
      int.parse(horarioPartes[1]),
    );

    if (dataHorario.isBefore(agora)) {
      return false;
    }

    final time = hour['time'] as TimeOfDay;
    final endHour = hour['endHour'] as int;
    if (time.hour == endHour) {
      return false;
    }

    return true;
  }

  Future<void> _addOrUpdatePlanner(int usuarioId, TimeOfDay time, Map<String, dynamic>? existingEntry) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    final date = _selectedDate;

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(date) &&
        (time.hour * 60) <= currentTimeInMinutes) {
      _showMessage('Não é possível agendar horários passados.', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: existingEntry?['informacao'] as String?);
        return AlertDialog(
          title: Text(existingEntry == null
              ? 'Adicionar Reserva em ${time.hour.toString().padLeft(2, '0')}:00'
              : 'Editar Reserva em ${time.hour.toString().padLeft(2, '0')}:00'),
          content: TextField(
            controller: controller,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Informação da Reserva (máx. 10 caracteres)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  _showMessage('Por favor, insira uma informação para a reserva.', isError: true);
                  return;
                }

                try {
                  final planner = _planners.firstWhere(
                    (p) => p.usuarioId == usuarioId,
                    orElse: () {
                      final defaultStatus = _statuses.firstWhere(
                        (s) => s.status == 'DISPONIVEL',
                        orElse: () => Status(id: 1, status: 'DISPONIVEL'),
                      );
                      return Planner(
                        id: _getNextPlannerId(),
                        usuarioId: usuarioId,
                        statusId: defaultStatus.id,
                      );
                    },
                  );

                  if (existingEntry != null) {
                    final index = existingEntry['index'] as int;
                    final updatedPlanner = planner.updateEntry(
                      index,
                      horario: timeString,
                      data: date,
                      informacao: controller.text,
                    );

                    await Supabase.instance.client
                        .from('planner')
                        .update(updatedPlanner.toJson())
                        .eq('id', updatedPlanner.id);
                    _showMessage('Reserva atualizada com sucesso!');
                  } else {
                    await _authService.upsertPlanner(planner, timeString, date, controller.text);
                    _showMessage('Reserva adicionada com sucesso!');
                  }

                  await _loadPlanners();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e, stackTrace) {
                  print('Erro ao adicionar/atualizar planner: $e\n$stackTrace');
                  String errorMessage = 'Erro ao adicionar/atualizar reserva. Tente novamente.';
                  if (e.toString().contains('Já existe uma reserva')) {
                    errorMessage = e.toString().replaceFirst('Exception: ', '');
                  } else if (e.toString().contains('PostgresException')) {
                    errorMessage = 'Erro no banco de dados. Verifique os dados e tente novamente.';
                  }
                  _showMessage(errorMessage, isError: true);
                }
              },
              child: Text(existingEntry == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removePlannerEntry(int usuarioId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente remover esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final planner = _planners.firstWhere(
        (p) => p.usuarioId == usuarioId,
        orElse: () {
          final defaultStatus = _statuses.firstWhere(
            (s) => s.status == 'DISPONIVEL',
            orElse: () => Status(id: 1, status: 'DISPONIVEL'),
          );
          return Planner(
            id: _getNextPlannerId(),
            usuarioId: usuarioId,
            statusId: defaultStatus.id,
          );
        },
      );

      await _authService.deletePlannerEntry(planner, index);
      _showMessage('Reserva removida com sucesso!');
      await _loadPlanners();
    } catch (e, stackTrace) {
      print('Erro ao remover planner: $e\n$stackTrace');
      _showMessage('Erro ao remover reserva: $e', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final Map<String, List<Usuario>> usersBySector = {
      'Suporte': _usuarios.where((u) => u.setor == 'Suporte').toList(),
      'ADM': _usuarios.where((u) => u.setor == 'ADM').toList(),
      'DEV': _usuarios.where((u) => u.setor == 'DEV').toList(),
      'Externo': _usuarios.where((u) => u.setor == 'Externo').toList(),
    };

    final Map<String, Color> sectorColors = {
      'Suporte': Colors.green,
      'ADM': Colors.blue,
      'DEV': Colors.purple,
      'Externo': Colors.orange,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.dashboard,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Painel de Status e Agenda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
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
                    await _loadInitialData();
                  }
                },
                child: const Text(
                  'Selecionar Data',
                  style: TextStyle(color: Color.fromARGB(179, 162, 215, 0)),
                ),
              ),
              const SizedBox(height: 20),

              ...usersBySector.entries.map((entry) {
                final sector = entry.key;
                final users = entry.value;
                if (users.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sector (${users.length} usuários)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: sectorColors[sector] ?? Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final usuario = users[index];
                        final plannerEntries = _getPlannerEntriesForUserAndDate(usuario.id);
                        final availableHours = _getAvailableHoursForUser(usuario.id);
                        final status = _statuses.firstWhere(
                          (s) => s.status == usuario.status,
                          orElse: () => Status(id: -1, status: 'Desconhecido'),
                        );

                        final screenWidth = MediaQuery.of(context).size.width;
                        const leadingWidth = 40.0;
                        const paddingAndMargins = 32.0;
                        const nameAndStatusWidth = 200.0;
                        final trailingWidth = screenWidth - leadingWidth - nameAndStatusWidth - paddingAndMargins;

                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sectorColors[sector] ?? Colors.grey,
                              child: Text(
                                usuario.nome?.substring(0, 1) ?? usuario.email.substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              usuario.nome ?? usuario.email,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Status: ${status.status}',
                              style: TextStyle(
                                color: _getStatusColor(status.status),
                              ),
                            ),
                            trailing: SizedBox(
                              width: trailingWidth,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: availableHours.map((hour) {
                                    final time = hour['time'] as TimeOfDay;
                                    final isUnavailable = hour['isUnavailable'] as bool;
                                    final entry = plannerEntries.firstWhere(
                                      (entry) =>
                                          entry['horario'] == '${time.hour.toString().padLeft(2, '0')}:00',
                                      orElse: () => {},
                                    );
                                    final isReserved = entry.isNotEmpty;

                                    return GestureDetector(
                                      onTap: () {
                                        if (isUnavailable) return;
                                        if (!_podeEditar(usuario.id, hour, isReserved ? entry : null)) {
                                          _showMessage(
                                            'Você não pode editar esta reserva.',
                                            isError: true,
                                          );
                                          return;
                                        }
                                        _addOrUpdatePlanner(
                                          usuario.id,
                                          time,
                                          isReserved ? entry : null,
                                        );
                                      },
                                      onLongPress: isReserved && _podeEditar(usuario.id, hour, entry)
                                          ? () {
                                              _removePlannerEntry(usuario.id, entry['index']);
                                            }
                                          : null,
                                      child: Container(
                                        width: 80.0,
                                        margin: const EdgeInsets.only(left: 4.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                        decoration: BoxDecoration(
                                          color: isUnavailable
                                              ? Colors.red.withOpacity(0.5)
                                              : (isReserved ? Colors.greenAccent : Colors.grey.withOpacity(0.5)),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${time.hour.toString().padLeft(2, '0')}:00',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (isReserved)
                                              Text(
                                                entry['informacao'] ?? 'Sem informação',
                                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      _showMessage('Voltando para a tela anterior...');
                      if (widget.usuarioLogado.email == 'adm@dataplace.com.br') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminScreen(usuario: widget.usuarioLogado),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatusDPScreen(usuario: widget.usuarioLogado),
                          ),
                        );
                      }
                    }
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
                    'Voltar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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