import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final Usuario usuario;

  const AdminScreen({super.key, required this.usuario});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();
  late Usuario _usuario;
  List<Usuario> _usuarios = [];
  List<Status> _statuses = [];
  List<Planner> _planners = [];
  List<HorarioTrabalho> _horariosTrabalho = [];
  bool _isLoading = true;

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
      await _loadUsuarios();
      await _loadStatuses();
      await _loadPlanners();
      await _loadHorariosTrabalho();
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await _authService.getAllUsuarios();
      setState(() {
        _usuarios = usuarios;
      });
    } catch (e) {
      _showError('Erro ao carregar usuários: $e');
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
    }
  }

  Future<void> _loadPlanners() async {
    try {
      final planners = await _authService.getAllPlanners();
      setState(() {
        _planners = planners;
      });
    } catch (e) {
      _showError('Erro ao carregar planners: $e');
    }
  }

  Future<void> _loadHorariosTrabalho() async {
    try {
      final horarios = await _authService.getAllHorariosTrabalho();
      setState(() {
        _horariosTrabalho = horarios;
      });
    } catch (e) {
      _showError('Erro ao carregar horários de trabalho: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _addOrEditUsuario({Usuario? usuario}) async {
    final emailController = TextEditingController(text: usuario?.email ?? '');
    final nomeController = TextEditingController(text: usuario?.nome ?? '');
    final setorController = TextEditingController(text: usuario?.setor ?? '');
    final senhaController = TextEditingController(text: usuario?.senha ?? '');
    final horarioInicioController = TextEditingController(text: usuario?.horarioiniciotrabalho ?? '08:30');
    final horarioFimController = TextEditingController(text: usuario?.horariofimtrabalho ?? '18:00');
    final horarioAlmocoInicioController = TextEditingController(text: usuario?.horarioalmocoinicio ?? '12:00');
    final horarioAlmocoFimController = TextEditingController(text: usuario?.horarioalmocofim ?? '13:30');
    String? selectedStatus = usuario?.status ?? 'DISPONIVEL';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(usuario == null ? 'Novo Usuário' : 'Editar Usuário'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: setorController,
                  decoration: const InputDecoration(labelText: 'Setor'),
                ),
                TextField(
                  controller: senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                TextField(
                  controller: horarioInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Início (HH:MM)'),
                ),
                TextField(
                  controller: horarioFimController,
                  decoration: const InputDecoration(labelText: 'Horário Fim (HH:MM)'),
                ),
                TextField(
                  controller: horarioAlmocoInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Almoço Início (HH:MM)'),
                ),
                TextField(
                  controller: horarioAlmocoFimController,
                  decoration: const InputDecoration(labelText: 'Horário Almoço Fim (HH:MM)'),
                ),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status.status,
                      child: Text(status.status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                  hint: const Text('Selecione o Status'),
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
                final newUsuario = Usuario(
                  id: usuario?.id ?? 0,
                  email: emailController.text,
                  nome: nomeController.text,
                  setor: setorController.text,
                  senha: senhaController.text,
                  status: selectedStatus,
                  horarioiniciotrabalho: horarioInicioController.text,
                  horariofimtrabalho: horarioFimController.text,
                  horarioalmocoinicio: horarioAlmocoInicioController.text,
                  horarioalmocofim: horarioAlmocoFimController.text,
                );
                try {
                  if (usuario == null) {
                    await _authService.createUsuario(newUsuario);
                    _showError('Usuário cadastrado com sucesso!');
                  } else {
                    await _authService.updateUsuario(newUsuario);
                    _showError('Usuário atualizado com sucesso!');
                  }
                  await _loadUsuarios();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao salvar usuário: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOrEditStatus({Status? status}) async {
    final statusController = TextEditingController(text: status?.status ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(status == null ? 'Novo Status' : 'Editar Status'),
          content: TextField(
            controller: statusController,
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final newStatus = Status(
                  id: status?.id ?? 0,
                  status: statusController.text,
                );
                try {
                  if (status == null) {
                    await _authService.createStatus(newStatus);
                    _showError('Status cadastrado com sucesso!');
                  } else {
                    await _authService.updateStatus(newStatus);
                    _showError('Status atualizado com sucesso!');
                  }
                  await _loadStatuses();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao salvar status: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOrEditPlanner({Planner? planner, required List<Usuario> usuarios, required List<Status> statuses}) async {
    final usuarioController = TextEditingController(text: planner?.usuarioId.toString() ?? '');
    final dataController = TextEditingController(
      text: planner != null ? DateFormat('yyyy-MM-dd').format(planner.data) : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String? selectedStatus = statuses.firstWhere((s) => s.id == planner?.statusId, orElse: () => statuses.first).status;
    final horario1Controller = TextEditingController(text: planner?.horario1 ?? '');
    final informacao1Controller = TextEditingController(text: planner?.informacao1 ?? '');
    // Adicione mais controladores para os outros horários se necessário

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(planner == null ? 'Novo Planner' : 'Editar Planner'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: usuarioController,
                  decoration: const InputDecoration(labelText: 'ID do Usuário'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: dataController,
                  decoration: const InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
                ),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status.status,
                      child: Text(status.status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                  hint: const Text('Selecione o Status'),
                ),
                TextField(
                  controller: horario1Controller,
                  decoration: const InputDecoration(labelText: 'Horário 1 (HH:MM)'),
                ),
                TextField(
                  controller: informacao1Controller,
                  decoration: const InputDecoration(labelText: 'Informação 1'),
                ),
                // Adicione mais campos para os outros horários se necessário
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
                final statusId = statuses.firstWhere((s) => s.status == selectedStatus).id;
                final newPlanner = Planner(
                  id: planner?.id ?? 0,
                  usuarioId: int.parse(usuarioController.text),
                  data: DateTime.parse(dataController.text),
                  statusId: statusId,
                  horario1: horario1Controller.text.isEmpty ? null : horario1Controller.text,
                  informacao1: informacao1Controller.text.isEmpty ? null : informacao1Controller.text,
                  horario2: planner?.horario2,
                  informacao2: planner?.informacao2,
                  horario3: planner?.horario3,
                  informacao3: planner?.informacao3,
                  horario4: planner?.horario4,
                  informacao4: planner?.informacao4,
                  horario5: planner?.horario5,
                  informacao5: planner?.informacao5,
                  horario6: planner?.horario6,
                  informacao6: planner?.informacao6,
                  horario7: planner?.horario7,
                  informacao7: planner?.informacao7,
                  horario8: planner?.horario8,
                  informacao8: planner?.informacao8,
                  horario9: planner?.horario9,
                  informacao9: planner?.informacao9,
                  horario10: planner?.horario10,
                  informacao10: planner?.informacao10,
                );
                try {
                  await _authService.upsertPlanner(newPlanner);
                  _showError('Planner salvo com sucesso!');
                  await _loadPlanners();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao salvar planner: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOrEditHorarioTrabalho({HorarioTrabalho? horario}) async {
    final usuarioIdController = TextEditingController(text: horario?.usuarioId.toString() ?? '');
    final diaSemanaController = TextEditingController(text: horario?.diaSemana.toString() ?? '');
    final horarioInicioController = TextEditingController(text: horario?.horarioInicio ?? '08:30');
    final horarioFimController = TextEditingController(text: horario?.horarioFim ?? '18:00');
    final horarioAlmocoInicioController = TextEditingController(text: horario?.horarioAlmocoInicio ?? '12:00');
    final horarioAlmocoFimController = TextEditingController(text: horario?.horarioAlmocoFim ?? '13:30');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(horario == null ? 'Novo Horário de Trabalho' : 'Editar Horário de Trabalho'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: usuarioIdController,
                  decoration: const InputDecoration(labelText: 'ID do Usuário'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: diaSemanaController,
                  decoration: const InputDecoration(labelText: 'Dia da Semana (1-7)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: horarioInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Início (HH:MM)'),
                ),
                TextField(
                  controller: horarioFimController,
                  decoration: const InputDecoration(labelText: 'Horário Fim (HH:MM)'),
                ),
                TextField(
                  controller: horarioAlmocoInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Almoço Início (HH:MM)'),
                ),
                TextField(
                  controller: horarioAlmocoFimController,
                  decoration: const InputDecoration(labelText: 'Horário Almoço Fim (HH:MM)'),
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
                final newHorario = HorarioTrabalho(
                  id: horario?.id ?? 0,
                  usuarioId: int.parse(usuarioIdController.text),
                  diaSemana: int.parse(diaSemanaController.text),
                  horarioInicio: horarioInicioController.text,
                  horarioFim: horarioFimController.text,
                  horarioAlmocoInicio: horarioAlmocoInicioController.text,
                  horarioAlmocoFim: horarioAlmocoFimController.text,
                  usuario: null,
                );
                try {
                  await _authService.upsertHorarioTrabalho(newHorario);
                  _showError('Horário de trabalho salvo com sucesso!');
                  await _loadHorariosTrabalho();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao salvar horário de trabalho: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
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
                Icons.admin_panel_settings,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bem-vindo, Administrador',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Seção de Usuários
              const Text(
                'Gerenciar Usuários',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._usuarios.map((usuario) {
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
                          '${usuario.nome ?? usuario.email} (${usuario.setor ?? "Sem setor"})',
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _addOrEditUsuario(usuario: usuario),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addOrEditUsuario(),
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
                  'Adicionar Usuário',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Seção de Status
              const Text(
                'Gerenciar Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._statuses.map((status) {
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
                          status.status,
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _addOrEditStatus(status: status),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addOrEditStatus(),
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
                  'Adicionar Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Seção de Planners
              const Text(
                'Gerenciar Planners',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._planners.map((planner) {
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
                          'Usuário ID: ${planner.usuarioId} - Data: ${DateFormat('dd/MM/yyyy').format(planner.data)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _addOrEditPlanner(planner: planner, usuarios: _usuarios, statuses: _statuses),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addOrEditPlanner(usuarios: _usuarios, statuses: _statuses),
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
                  'Adicionar Planner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Seção de Horários de Trabalho
              const Text(
                'Gerenciar Horários de Trabalho',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._horariosTrabalho.map((horario) {
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
                          'Usuário ID: ${horario.usuarioId} - Dia: ${horario.diaSemana}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _addOrEditHorarioTrabalho(horario: horario),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addOrEditHorarioTrabalho(),
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
                  'Adicionar Horário de Trabalho',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botão de Sair
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