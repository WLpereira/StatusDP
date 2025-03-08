import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'painel_screen.dart';

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

  void _goToPainel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PainelScreen(usuarioLogado: widget.usuario)),
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
              Center(
                child: ElevatedButton(
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
              Center(
                child: ElevatedButton(
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
              ),

              const SizedBox(height: 40),

              // Botão de Painel e Sair
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _goToPainel,
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
                      'Painel',
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