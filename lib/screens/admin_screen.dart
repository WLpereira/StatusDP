import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/user_period.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart'; // Importe a tela de login
import 'painel_screen.dart'; // Importe a tela do painel

class AdminScreen extends StatefulWidget {
  final Usuario usuario; // Adicionei 'final' para seguir boas práticas

  const AdminScreen({super.key, required this.usuario});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();
  List<Usuario> _usuarios = [];
  List<Status> _statuses = [];
  List<UserPeriod> _userPeriods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadUsuarios();
      await _loadStatuses();
      final userPeriods = await _authService.getAllUserPeriods();
      setState(() {
        _userPeriods = userPeriods;
      });
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
      throw Exception('Erro ao carregar usuários: $e');
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _authService.getStatuses();
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      throw Exception('Erro ao carregar status: $e');
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

  Future<void> _addOrEditUsuario({Usuario? usuario}) async {
    final isEditing = usuario != null;
    final emailController = TextEditingController(text: isEditing ? usuario.email : '');
    final nomeController = TextEditingController(text: isEditing ? usuario.nome : '');
    final setorController = TextEditingController(text: isEditing ? usuario.setor : '');
    final senhaController = TextEditingController(text: isEditing ? usuario.senha : '');
    final statusController = TextEditingController(text: isEditing ? usuario.status : '');
    final inicioController = TextEditingController(text: isEditing ? usuario.horarioiniciotrabalho : '');
    final fimController = TextEditingController(text: isEditing ? usuario.horariofimtrabalho : '');
    final almocoInicioController = TextEditingController(text: isEditing ? usuario.horarioalmocoinicio : '');
    final almocoFimController = TextEditingController(text: isEditing ? usuario.horarioalmocofim : '');
    final gestaoInicioController = TextEditingController(text: isEditing ? usuario.horariogestaoinicio : '');
    final gestaoFimController = TextEditingController(text: isEditing ? usuario.horariogestaofim : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Usuário' : 'Adicionar Usuário'),
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
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextField(
                  controller: inicioController,
                  decoration: const InputDecoration(labelText: 'Horário Início Trabalho (HH:MM)'),
                ),
                TextField(
                  controller: fimController,
                  decoration: const InputDecoration(labelText: 'Horário Fim Trabalho (HH:MM)'),
                ),
                TextField(
                  controller: almocoInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Início Almoço (HH:MM)'),
                ),
                TextField(
                  controller: almocoFimController,
                  decoration: const InputDecoration(labelText: 'Horário Fim Almoço (HH:MM)'),
                ),
                TextField(
                  controller: gestaoInicioController,
                  decoration: const InputDecoration(labelText: 'Horário Início Gestão (HH:MM)'),
                ),
                TextField(
                  controller: gestaoFimController,
                  decoration: const InputDecoration(labelText: 'Horário Fim Gestão (HH:MM)'),
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
                try {
                  final newUsuario = Usuario(
                    id: isEditing ? usuario.id : 0,
                    email: emailController.text,
                    senha: senhaController.text,
                    nome: nomeController.text.isEmpty ? null : nomeController.text,
                    setor: setorController.text.isEmpty ? null : setorController.text,
                    status: statusController.text.isEmpty ? null : statusController.text,
                    horarioiniciotrabalho: inicioController.text.isEmpty ? null : inicioController.text,
                    horariofimtrabalho: fimController.text.isEmpty ? null : fimController.text,
                    horarioalmocoinicio: almocoInicioController.text.isEmpty ? null : almocoInicioController.text,
                    horarioalmocofim: almocoFimController.text.isEmpty ? null : almocoFimController.text,
                    horariogestaoinicio: gestaoInicioController.text.isEmpty ? null : gestaoInicioController.text,
                    horariogestaofim: gestaoFimController.text.isEmpty ? null : gestaoFimController.text,
                  );

                  if (isEditing) {
                    await _authService.updateUsuario(newUsuario);
                    _showError('Usuário atualizado com sucesso!');
                  } else {
                    await _authService.createUsuario(newUsuario);
                    _showError('Usuário criado com sucesso!');
                  }
                  await _loadUsuarios();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao ${isEditing ? "atualizar" : "criar"} usuário: $e');
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
    final isEditing = status != null;
    final statusController = TextEditingController(text: isEditing ? status.status : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Status' : 'Adicionar Status'),
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
                try {
                  final newStatus = Status(
                    id: isEditing ? status.id : 0,
                    status: statusController.text,
                  );

                  if (isEditing) {
                    await _authService.updateStatus(newStatus);
                    _showError('Status atualizado com sucesso!');
                  } else {
                    await _authService.createStatus(newStatus);
                    _showError('Status criado com sucesso!');
                  }
                  await _loadStatuses();
                  Navigator.pop(context);
                } catch (e) {
                  _showError('Erro ao ${isEditing ? "atualizar" : "criar"} status: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  bool _isUserUnavailable(int userId, DateTime date) {
    return _userPeriods.any((period) =>
        period.usuarioId == userId &&
        date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(period.endDate.add(const Duration(days: 1))));
  }

  Future<void> _requestScheduling(Usuario user, DateTime date) async {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Solicitar Agendamento para ${user.nome ?? user.email} em ${DateFormat('dd/MM/yyyy').format(date)}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Motivo da Solicitação'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Aqui você pode implementar a lógica para salvar a solicitação no backend
                // Por exemplo, criar uma nova tabela 'scheduling_requests' no Supabase
                _showError('Solicitação enviada com sucesso!');
                Navigator.pop(context);
              },
              child: const Text('Enviar'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gerenciar Usuários',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _addOrEditUsuario(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._usuarios.map((usuario) {
                final periods = _userPeriods.where((p) => p.usuarioId == usuario.id).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        if (periods.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Períodos de Indisponibilidade:',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          ...periods.map((period) => GestureDetector(
                                onTap: () => _requestScheduling(usuario, period.startDate),
                                child: Text(
                                  '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}: ${period.info}',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),

              // Seção de Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gerenciar Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _addOrEditStatus(),
                  ),
                ],
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

              const SizedBox(height: 20),

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PainelScreen(usuarioLogado: widget.usuario),
                        ),
                      );
                    },
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
                      'Acessar Painel',
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