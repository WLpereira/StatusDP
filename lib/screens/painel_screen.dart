import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/planner.dart';
import '../models/status.dart';
import '../models/horario_trabalho.dart'; // Adicionar import para HorarioTrabalho
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class PainelScreen extends StatefulWidget {
  final Usuario usuarioLogado;

  const PainelScreen({super.key, required this.usuarioLogado});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final AuthService _authService = AuthService();
  List<Usuario> _usuarios = [];
  List<Planner> _planners = [];
  List<Status> _statuses = [];
  Map<int, List<HorarioTrabalho>> _horariosTrabalho = {}; // Mapa para armazenar horários de trabalho por usuário
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  final Map<String, Color> _sectorColors = {
    'Suporte': Colors.green,
    'ADM': Colors.blue,
    'DEV': Colors.purple,
    'Externo': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialData(); // Garante que os dados sejam recarregados ao retornar à tela
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final usuarios = await _authService.getAllUsuarios();
      final planners = await _authService.getAllPlanners();
      final statuses = await _authService.getStatuses();

      // Carregar os horários de trabalho para todos os usuários
      Map<int, List<HorarioTrabalho>> horariosTrabalho = {};
      for (var usuario in usuarios) {
        final horarios = await _authService.getHorarioTrabalho(usuario.id, _selectedDate.weekday);
        horariosTrabalho[usuario.id] = horarios;
      }

      setState(() {
        _usuarios = usuarios;
        _planners = planners;
        _statuses = statuses;
        _horariosTrabalho = horariosTrabalho;
      });
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  String? _getInformacaoForUser(int userId, TimeOfDay time) {
    final planner = _planners.firstWhere(
      (p) => p.usuarioId == userId && DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () => Planner(
        id: -1,
        usuarioId: userId,
        data: _selectedDate,
        statusId: _statuses.isNotEmpty ? _statuses.firstWhere((s) => s.status == 'DISPONIVEL').id : 1,
      ),
    );

    if (planner.id != -1) {
      if (planner.horario1 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao1;
      if (planner.horario2 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao2;
      if (planner.horario3 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao3;
      if (planner.horario4 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao4;
      if (planner.horario5 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao5;
      if (planner.horario6 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao6;
      if (planner.horario7 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao7;
      if (planner.horario8 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao8;
      if (planner.horario9 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao9;
      if (planner.horario10 == '${time.hour.toString().padLeft(2, '0')}:00') return planner.informacao10;
    }
    return null;
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

  Future<void> _editPlanner(int userId, TimeOfDay time) async {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final timeInMinutes = time.hour * 60;

    if (DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
        timeInMinutes <= currentTimeInMinutes) {
      _showError('Não é possível editar horários já passados.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _getInformacaoForUser(userId, time) ?? '');
        return AlertDialog(
          title: Text('Editar ${time.hour.toString().padLeft(2, '0')}:00 para ${getUserName(userId)}'),
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
                await _saveOrUpdatePlanner(userId, time, controller.text.isEmpty ? null : controller.text);
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveOrUpdatePlanner(int userId, TimeOfDay time, String? informacao) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:00';
    Planner existingPlanner = _planners.firstWhere(
      (p) => p.usuarioId == userId && DateFormat('yyyy-MM-dd').format(p.data) == DateFormat('yyyy-MM-dd').format(_selectedDate),
      orElse: () => Planner(
        id: -1,
        usuarioId: userId,
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
      'usuarioid': userId,
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
      await _loadInitialData(); // Recarrega os dados imediatamente após salvar
    } catch (e) {
      _showError('Erro ao salvar informação: $e');
    }
  }

  String getUserName(int userId) {
    final user = _usuarios.firstWhere((u) => u.id == userId, orElse: () => Usuario(id: 0, email: 'Desconhecido', senha: ''));
    return user.nome ?? user.email;
  }

  List<TimeOfDay> _getAvailableHours(Usuario user) {
    // Carrega os horários de trabalho do usuário para o dia atual
    final horarios = _horariosTrabalho[user.id] ?? [];
    TimeOfDay startTime;
    TimeOfDay endTime;
    TimeOfDay lunchStartTime;
    TimeOfDay lunchEndTime;

    if (horarios.isNotEmpty) {
      final horario = horarios.first;
      startTime = _parseTimeOfDay(horario.horarioInicio ?? user.horarioiniciotrabalho ?? '06:00');
      endTime = _parseTimeOfDay(horario.horarioFim ?? user.horariofimtrabalho ?? '22:00');
      lunchStartTime = _parseTimeOfDay(horario.horarioAlmocoInicio ?? user.horarioalmocoinicio ?? '14:00');
      lunchEndTime = _parseTimeOfDay(horario.horarioAlmocoFim ?? user.horarioalmocofim ?? '15:30');
    } else {
      startTime = _parseTimeOfDay(user.horarioiniciotrabalho ?? '06:00');
      endTime = _parseTimeOfDay(user.horariofimtrabalho ?? '22:00');
      lunchStartTime = _parseTimeOfDay(user.horarioalmocoinicio ?? '14:00');
      lunchEndTime = _parseTimeOfDay(user.horarioalmocofim ?? '15:30');
    }

    int startHour = startTime.hour;
    if (startTime.minute > 0) startHour++;

    int endHour = endTime.hour;
    if (endTime.minute > 0) endHour--;

    int lunchStartHour = lunchStartTime.hour;
    int lunchEndHour = lunchEndTime.hour;
    if (lunchEndTime.minute > 0) lunchEndHour++;

    List<TimeOfDay> hours = [];
    for (int h = startHour; h <= endHour; h++) {
      final time = TimeOfDay(hour: h, minute: 0);
      final timeInMinutes = h * 60;
      final lunchStartInMinutes = lunchStartTime.hour * 60 + lunchStartTime.minute;
      final lunchEndInMinutes = lunchEndTime.hour * 60 + lunchEndTime.minute;

      if (timeInMinutes >= lunchStartInMinutes && timeInMinutes < lunchEndInMinutes) {
        continue;
      }

      hours.add(time);
    }
    return hours;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final isAdmin = widget.usuarioLogado.email == 'adm@dataplace.com.br';

    final Map<String, List<Usuario>> usersBySector = {
      'Suporte': _usuarios.where((u) => u.setor == 'Suporte').toList(),
      'ADM': _usuarios.where((u) => u.setor == 'ADM').toList(),
      'DEV': _usuarios.where((u) => u.setor == 'DEV').toList(),
      'Externo': _usuarios.where((u) => u.setor == 'Externo').toList(),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadInitialData, // Permite recarregamento manual
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
                  style: TextStyle(color: Colors.white70),
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
                        color: _sectorColors[sector] ?? Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final status = _statuses.firstWhere(
                          (s) => s.status == user.status,
                          orElse: () => Status(id: 1, status: 'DISPONIVEL'),
                        );
                        final availableHours = _getAvailableHours(user);

                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _sectorColors[sector] ?? Colors.grey,
                              child: Text(
                                user.nome?.substring(0, 1) ?? user.email.substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user.nome ?? user.email,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Status: ${status.status}',
                              style: TextStyle(color: _getStatusColor(status.status)),
                            ),
                            trailing: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: availableHours.map((time) {
                                  final informacao = _getInformacaoForUser(user.id, time);
                                  final timeInMinutes = time.hour * 60;
                                  final isPastHour = DateFormat('yyyy-MM-dd').format(now) == DateFormat('yyyy-MM-dd').format(_selectedDate) &&
                                      timeInMinutes <= currentTimeInMinutes;
                                  final canEdit = isAdmin || (widget.usuarioLogado.setor == 'ADM' && widget.usuarioLogado.id == user.id);

                                  return GestureDetector(
                                    onTap: canEdit && !isPastHour
                                        ? () => _editPlanner(user.id, time)
                                        : null,
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 4.0),
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: informacao != null ? Colors.greenAccent : Colors.grey.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${time.hour.toString().padLeft(2, '0')}:00',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                          if (informacao != null)
                                            Text(
                                              informacao,
                                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
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
                    Navigator.pop(context);
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
                    'Voltar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}