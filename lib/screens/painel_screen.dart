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
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
  late dynamic _subscription; // Alterado para RealtimeChannel
  Timer? _plannerRefreshTimer;

  // Lista de emails de administradores que devem redirecionar para AdminScreen
  final List<String> _adminEmails = [
    'adm@dataplace.com.br',
    'admqa@dataplace.com.br',
    'admdev@dataplace.com.br',
    'admadm@dataplace.com.br',
    'admcloud@dataplace.com.br',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtimeSubscriptions();
    _startPlannerRefreshTimer();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_subscription);
    _plannerRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _startPlannerRefreshTimer() {
    _plannerRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _loadPlanners();
    });
  }

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
          table: 'usuarios',
          callback: (payload) => _handleUsuarioChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'status',
          callback: (payload) => _handleStatusChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'horarios_trabalho',
          callback: (payload) => _handleHorarioTrabalhoChange(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_periods',
          callback: (payload) => _handleUserPeriodChange(payload),
        )
        .subscribe();
  }

  void _handlePlannerChange(PostgresChangePayload payload) {
    if (!mounted) return;
    print('Evento recebido na tabela planner: ${payload.eventType}');
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final newPlanner = Planner.fromJson(payload.newRecord!);
        print('Novo planner inserido: ${newPlanner.id}');
        _planners.add(newPlanner);
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedPlanner = Planner.fromJson(payload.newRecord!);
        final index = _planners.indexWhere((p) => p.id == updatedPlanner.id);
        if (index != -1) {
          print('Planner atualizado: ${updatedPlanner.id}');
          _planners[index] = updatedPlanner;
        } else {
          print('Planner não encontrado, adicionando: ${updatedPlanner.id}');
          _planners.add(updatedPlanner);
        }
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord!['id'] as int;
        print('Planner deletado: $deletedId');
        _planners.removeWhere((p) => p.id == deletedId);
      }
    });
  }

  void _handleUsuarioChange(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final newUsuario = Usuario.fromJson(payload.newRecord!);
        if (!_adminEmails.contains(newUsuario.email)) _usuarios.add(newUsuario);
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedUsuario = Usuario.fromJson(payload.newRecord!);
        final index = _usuarios.indexWhere((u) => u.id == updatedUsuario.id);
        if (index != -1) _usuarios[index] = updatedUsuario;
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        _usuarios.removeWhere((u) => u.id == payload.oldRecord!['id'] as int);
      }
    });
  }

  void _handleStatusChange(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        _statuses.add(Status.fromJson(payload.newRecord!));
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedStatus = Status.fromJson(payload.newRecord!);
        final index = _statuses.indexWhere((s) => s.id == updatedStatus.id);
        if (index != -1) _statuses[index] = updatedStatus;
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        _statuses.removeWhere((s) => s.id == payload.oldRecord!['id'] as int);
      }
    });
  }

  void _handleHorarioTrabalhoChange(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        _horariosTrabalho.add(HorarioTrabalho.fromJson(payload.newRecord!));
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedHorario = HorarioTrabalho.fromJson(payload.newRecord!);
        final index = _horariosTrabalho.indexWhere((h) => h.id == updatedHorario.id);
        if (index != -1) _horariosTrabalho[index] = updatedHorario;
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        _horariosTrabalho.removeWhere((h) => h.id == payload.oldRecord!['id'] as int);
      }
    });
  }

  void _handleUserPeriodChange(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        _userPeriods.add(UserPeriod.fromJson(payload.newRecord!));
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final updatedPeriod = UserPeriod.fromJson(payload.newRecord!);
        final index = _userPeriods.indexWhere((p) => p.id == updatedPeriod.id);
        if (index != -1) _userPeriods[index] = updatedPeriod;
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        _userPeriods.removeWhere((p) => p.id == payload.oldRecord!['id'] as int);
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _authService.getStatuses();
      if (mounted) setState(() => _statuses = statuses);
    } catch (e, stackTrace) {
      print('Erro ao carregar statuses: $e\n$stackTrace');
      _showMessage('Erro ao carregar status: $e', isError: true);
    }
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await _authService.getAllUsuarios();
      if (mounted) {
        setState(() => _usuarios = usuarios.where((u) => !_adminEmails.contains(u.email)).toList());
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar usuários: $e\n$stackTrace');
      _showMessage('Erro ao carregar usuários: $e', isError: true);
    }
  }

  Future<void> _loadPlanners() async {
    try {
      final planners = await _authService.getAllPlanners();
      if (mounted) setState(() => _planners = planners);
    } catch (e, stackTrace) {
      print('Erro ao carregar planners: $e\n$stackTrace');
      _showMessage('Erro ao carregar planners: $e', isError: true);
    }
  }

  Future<void> _loadHorariosTrabalho() async {
    try {
      final horarios = await _authService.getAllHorariosTrabalho();
      if (mounted) setState(() => _horariosTrabalho = horarios);
    } catch (e, stackTrace) {
      print('Erro ao carregar horários de trabalho: $e\n$stackTrace');
      _showMessage('Erro ao carregar horários de trabalho: $e', isError: true);
    }
  }

  Future<void> _loadUserPeriods() async {
    try {
      final periods = await _authService.getAllUserPeriods();
      if (mounted) setState(() => _userPeriods = periods);
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
        backgroundColor: isError ? Colors.red : const Color.fromARGB(255, 49, 248, 96),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _getNextPlannerId() => _planners.isEmpty ? 1 : _planners.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

  List<Map<String, dynamic>> _getPlannerEntriesForUserAndDate(int usuarioId) {
    try {
      final planner = _planners.firstWhere(
        (p) => p.usuarioId == usuarioId,
        orElse: () => Planner(id: _getNextPlannerId(), usuarioId: usuarioId, statusId: 1),
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

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

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

      final startTime = _parseTimeOfDay(horario.horarioInicio ?? '06:00');
      final endTime = _parseTimeOfDay(horario.horarioFim ?? '18:00');
      final lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? '12:00');
      final lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? '13:30');

      // Arredondar o horário de início para a próxima hora cheia se houver minutos
      int startHour = startTime.hour + (startTime.minute > 0 ? 1 : 0);
      // Última hora cheia antes do fim (sempre subtrair 1 hora)
      int endHour = endTime.hour - 1;
      // Última hora cheia antes do início do almoço (sempre subtrair 1 hora)
      int lunchStartHour = lunchStartTime.hour - 1;
      // Primeira hora cheia a partir do retorno do almoço
      int lunchEndHour = lunchEndTime.hour + (lunchEndTime.minute > 0 ? 1 : 0);

      List<Map<String, dynamic>> hours = [];
      for (int h = startHour; h <= endHour; h++) {
        // Pular horários após a última hora cheia antes do almoço e antes da primeira hora cheia após o almoço
        if (h > lunchStartHour && h < lunchEndHour) continue;

        final time = TimeOfDay(hour: h, minute: 0);
        final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, h);
        final normalizedDate = _normalizeDate(date);
        final isUnavailable = _userPeriods.any((period) {
          final normalizedStartDate = _normalizeDate(period.startDate);
          final normalizedEndDate = _normalizeDate(period.endDate);
          return period.usuarioId == usuarioId &&
              (normalizedDate.isAfter(normalizedStartDate) || normalizedDate.isAtSameMomentAs(normalizedStartDate)) &&
              (normalizedDate.isBefore(normalizedEndDate.add(const Duration(days: 1))) ||
                  normalizedDate.isAtSameMomentAs(normalizedEndDate));
        });

        hours.add({'time': time, 'isUnavailable': isUnavailable, 'endHour': endHour});
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
    // Verificar se o usuário é administrador
    final isAdmin = _adminEmails.contains(widget.usuarioLogado.email);

    // Usuários comuns só podem editar seus próprios horários
    if (!isAdmin && widget.usuarioLogado.id != usuarioId) {
      return false;
    }

    final time = hour['time'] as TimeOfDay;
    final now = DateTime.now();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(now);

    // Se a data selecionada não for hoje, verificar se é passada ou futura
    if (selectedDateStr != currentDateStr) {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        time.hour,
        0,
      );
      if (selectedDateTime.isBefore(now)) {
        return false; // Não pode editar horários passados de dias anteriores
      }
      return true; // Pode editar horários futuros
    }

    // Se for hoje, verificar a regra de tempo
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final slotHour = time.hour;

    // Não pode editar horários passados
    if (slotHour < currentHour) {
      return false; // Ex.: às 10:50, não pode editar 9:00
    }

    // Pode editar o horário atual até o final da hora (H:59)
    // Ex.: às 10:50, pode editar 10:00
    if (slotHour == currentHour) {
      return true;
    }

    // Pode editar horários futuros
    // Ex.: às 10:50, pode editar 11:00, 14:00, etc.
    if (slotHour > currentHour) {
      return true;
    }

    return false;
  }

  Future<void> _addOrUpdatePlanner(int usuarioId, TimeOfDay time, Map<String, dynamic>? existingEntry) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    final date = _selectedDate;
    final now = DateTime.now();

    // Verificar a regra de tempo antes de permitir a adição/edição
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(now);

    if (selectedDateStr == currentDateStr) {
      final currentHour = now.hour;
      final slotHour = time.hour;

      // Não pode adicionar/editar horários passados
      if (slotHour < currentHour) {
        _showMessage('Não é possível agendar/editar horários passados.', isError: true);
        return;
      }

      // Pode adicionar/editar o horário atual ou futuros
      if (slotHour >= currentHour) {
        // Prosseguir com a adição/edição
      } else {
        _showMessage('Não é possível agendar/editar horários fora da janela de edição.', isError: true);
        return;
      }
    } else {
      final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, 0);
      if (selectedDateTime.isBefore(now)) {
        _showMessage('Não é possível agendar horários passados.', isError: true);
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: existingEntry?['informacao'] as String?);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            existingEntry == null ? 'Adicionar às ${time.hour}:00' : 'Editar às ${time.hour}:00',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLength: 10,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Informação (máx. 10 caracteres)',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white30),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  _showMessage('Insira uma informação para a reserva.', isError: true);
                  return;
                }
                try {
                  Planner planner = _planners.firstWhere(
                    (p) => p.usuarioId == usuarioId,
                    orElse: () => Planner(
                      id: _getNextPlannerId(),
                      usuarioId: usuarioId,
                      statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL',
                          orElse: () => Status(id: 1, status: 'DISPONIVEL')).id,
                    ),
                  );

                  if (existingEntry != null) {
                    // Atualizar uma entrada existente
                    final updatedPlanner = planner.updateEntry(
                      existingEntry['index'] as int,
                      horario: timeString,
                      data: date,
                      informacao: controller.text,
                    );
                    await Supabase.instance.client
                        .from('planner')
                        .update(updatedPlanner.toJson())
                        .eq('id', updatedPlanner.id);
                    // Atualizar localmente a lista _planners
                    setState(() {
                      final index = _planners.indexWhere((p) => p.id == updatedPlanner.id);
                      if (index != -1) {
                        _planners[index] = updatedPlanner;
                      } else {
                        _planners.add(updatedPlanner);
                      }
                    });
                    _showMessage('Reserva atualizada com sucesso!');
                  } else {
                    // Adicionar uma nova entrada
                    await _authService.upsertPlanner(planner, timeString, date, controller.text);
                    // Recarregar os planners para refletir a mudança
                    await _loadPlanners();
                    _showMessage('Reserva adicionada com sucesso!');
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e, stackTrace) {
                  print('Erro ao adicionar/atualizar planner: $e\n$stackTrace');
                  _showMessage(
                      e.toString().contains('Já existe uma reserva')
                          ? e.toString().replaceFirst('Exception: ', '')
                          : 'Erro ao adicionar/atualizar reserva.',
                      isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(existingEntry == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removePlannerEntry(int usuarioId, int index) async {
    final planner = _planners.firstWhere(
      (p) => p.usuarioId == usuarioId,
      orElse: () => Planner(
        id: _getNextPlannerId(),
        usuarioId: usuarioId,
        statusId: _statuses.firstWhere((s) => s.status == 'DISPONIVEL',
            orElse: () => Status(id: 1, status: 'DISPONIVEL')).id,
      ),
    );
    final entries = planner.getEntries();
    final entry = entries[index];
    final horario = entry['horario'] as String?;
    final data = entry['data'] as DateTime?;

    if (horario == null || data == null) {
      _showMessage('Erro: Entrada inválida.', isError: true);
      return;
    }

    final time = TimeOfDay(hour: int.parse(horario.split(':')[0]), minute: 0); // Alterado Zero para 0
    final hour = {'time': time};
    final canEdit = _podeEditar(usuarioId, hour, entry);

    if (!canEdit) {
      _showMessage('Não é possível remover esta reserva (horário passado).', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: const Text('Deseja remover esta reserva?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _authService.deletePlannerEntry(planner, index);
      // Recarregar os planners para refletir a mudança
      await _loadPlanners();
      _showMessage('Reserva removida com sucesso!');
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
        return const Color.fromARGB(255, 185, 167, 1);
      case 'GESTAO':
        return Colors.blueAccent;
      case 'OCUPADO':
        return Colors.red;
      default:
        return const Color.fromARGB(255, 109, 178, 234);
    }
  }

  String _getGravatarUrl(String email) {
    final emailTrimmed = email.trim().toLowerCase();
    final emailBytes = utf8.encode(emailTrimmed);
    final emailHash = md5.convert(emailBytes).toString();
    return 'https://www.gravatar.com/avatar/$emailHash?s=200&d=identicon';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Agrupar usuários por setor e ordenar alfabeticamente dentro de cada setor
    final usersBySector = {
      'Suporte': _usuarios.where((u) => u.setor == 'Suporte').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'Suporte/Consultor': _usuarios.where((u) => u.setor == 'Suporte/Consultor').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'Cloud': _usuarios.where((u) => u.setor == 'Cloud').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'ADM': _usuarios.where((u) => u.setor == 'ADM').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'DEV': _usuarios.where((u) => u.setor == 'DEV').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'Externo': _usuarios.where((u) => u.setor == 'Externo').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
      'QA': _usuarios.where((u) => u.setor == 'QA').toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
    };

    final sectorColors = {
      'Suporte': const Color.fromARGB(255, 229, 120, 4),
      'Suporte/Consultor': const Color.fromARGB(255, 239, 2, 2),
      'Cloud': Colors.blue,
      'ADM': const Color.fromARGB(255, 170, 92, 238),
      'DEV': const Color.fromARGB(255, 0, 99, 27),
      'Externo': const Color.fromARGB(255, 144, 255, 253),
      'QA': const Color.fromARGB(255, 217, 227, 11),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: Colors.white,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'Painel de Status e Agenda',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2026),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: Colors.green),
                                dialogBackgroundColor: const Color(0xFF16213E),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() => _selectedDate = picked);
                            await _loadInitialData();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sectorColors[sector] ?? Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...users.map((usuario) {
                              final plannerEntries = _getPlannerEntriesForUserAndDate(usuario.id);
                              final availableHours = _getAvailableHoursForUser(usuario.id);
                              final status = _statuses.firstWhere(
                                (s) => s.status == usuario.status,
                                orElse: () => Status(id: -1, status: 'Desconhecido'),
                              );
                              final horario = _horariosTrabalho.firstWhere(
                                (h) => h.usuarioId == usuario.id && h.diaSemana == _selectedDate.weekday,
                                orElse: () => HorarioTrabalho(
                                  id: -1,
                                  usuarioId: usuario.id,
                                  diaSemana: _selectedDate.weekday,
                                  horarioInicio: usuario.horarioiniciotrabalho ?? '06:00',
                                  horarioFim: usuario.horariofimtrabalho ?? '18:00',
                                  horarioAlmocoInicio: usuario.horarioalmocoinicio ?? '12:00',
                                  horarioAlmocoFim: usuario.horarioalmocofim ?? '13:30',
                                ),
                              );
                              final lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? '12:00');
                              final lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? '13:30');
                              final photoUrl = usuario.photoUrl ?? _getGravatarUrl(usuario.email);

                              return Card(
                                color: Colors.white.withOpacity(0.15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(photoUrl),
                                            backgroundColor: sectorColors[sector] ?? Colors.grey,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  usuario.nome ?? usuario.email,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Status: ${status.status}',
                                                  style: TextStyle(
                                                    color: _getStatusColor(status.status),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 70,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: availableHours.map((hour) {
                                              final time = hour['time'] as TimeOfDay;
                                              final isUnavailable = hour['isUnavailable'] as bool;
                                              final entry = plannerEntries.firstWhere(
                                                (e) =>
                                                    e['horario'] ==
                                                    '${time.hour.toString().padLeft(2, '0')}:00',
                                                orElse: () => {},
                                              );
                                              final isReserved = entry.isNotEmpty;

                                              return GestureDetector(
                                                onTap: () {
                                                  if (isUnavailable) return;
                                                  if (!_podeEditar(usuario.id, hour, isReserved ? entry : null)) {
                                                    _showMessage('Você não pode editar esta reserva.',
                                                        isError: true);
                                                    return;
                                                  }
                                                  _addOrUpdatePlanner(usuario.id, time, isReserved ? entry : null);
                                                },
                                                onLongPress: isReserved && _podeEditar(usuario.id, hour, entry)
                                                    ? () => _removePlannerEntry(usuario.id, entry['index'])
                                                    : null,
                                                child: Container(
                                                  width: 60,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isUnavailable
                                                        ? Colors.red.withOpacity(0.6)
                                                        : (isReserved
                                                            ? const Color.fromARGB(255, 255, 0, 0)
                                                            : Colors.grey.withOpacity(0.4)),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: isReserved ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        '${time.hour.toString().padLeft(2, '0')}:00',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (isReserved)
                                                        Text(
                                                          entry['informacao'] ?? 'N/A',
                                                          style: const TextStyle(
                                                            color: Colors.white70,
                                                            fontSize: 12,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
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
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Almoço: ${lunchStartTime.format(context)} - ${lunchEndTime.format(context)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _showMessage('Voltando para a tela anterior...');
                            if (mounted) {
                              if (_adminEmails.contains(widget.usuarioLogado.email)) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => AdminScreen(usuario: widget.usuarioLogado)),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => StatusDPScreen(usuario: widget.usuarioLogado)),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Voltar',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ]),
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