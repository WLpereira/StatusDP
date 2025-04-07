import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/user_period.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
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
          backgroundColor: const Color.fromARGB(255, 244, 185, 185),
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

  Future<void> _manageUserPeriods(Usuario usuario) async {
    final periods = _userPeriods.where((p) => p.usuarioId == usuario.id).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Gerenciar Períodos de Indisponibilidade de ${usuario.nome ?? usuario.email}'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    if (periods.isEmpty)
                      const Text(
                        'Nenhum período de indisponibilidade registrado.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...periods.map((period) {
                        return ListTile(
                          title: Text(
                            '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}: ${period.info}',
                            style: const TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteUserPeriod(period);
                              setDialogState(() {
                                periods.remove(period);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _addUserPeriod(usuario);
                        setDialogState(() {
                          periods.clear();
                          periods.addAll(_userPeriods.where((p) => p.usuarioId == usuario.id));
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add Indisponibilidade',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addUserPeriod(Usuario usuario) async {
    DateTime? startDate;
    DateTime? endDate;
    final infoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Período de Indisponibilidade'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2026),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Colors.green),
                              dialogBackgroundColor: const Color(0xFF16213E),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Text(
                        startDate == null
                            ? 'Selecionar Data Início'
                            : 'Início: ${DateFormat('dd/MM/yyyy').format(startDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2026),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Colors.green),
                              dialogBackgroundColor: const Color(0xFF16213E),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'Selecionar Data Fim'
                            : 'Fim: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextField(
                      controller: infoController,
                      decoration: const InputDecoration(labelText: 'Motivo (máx. 10 caracteres)'),
                      maxLength: 10,
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
                      _showError('Preencha todos os campos.');
                      return;
                    }
                    if (endDate!.isBefore(startDate!)) {
                      _showError('A data final deve ser após a data inicial.');
                      return;
                    }
                    try {
                      final newPeriod = UserPeriod(
                        id: 0,
                        usuarioId: usuario.id,
                        startDate: startDate!,
                        endDate: endDate!,
                        info: infoController.text,
                      );
                      await _authService.addUserPeriod(newPeriod);
                      final updatedPeriods = await _authService.getAllUserPeriods();
                      setState(() {
                        _userPeriods = updatedPeriods;
                      });
                      _showError('Período adicionado com sucesso!');
                      Navigator.pop(context);
                    } catch (e) {
                      _showError('Erro ao adicionar período: $e');
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewUserPeriod() async {
    Usuario? selectedUser;
    DateTime? startDate;
    DateTime? endDate;
    final infoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Novo Período de Indisponibilidade'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButton<Usuario>(
                      hint: const Text('Selecione um usuário'),
                      value: selectedUser,
                      isExpanded: true,
                      items: _usuarios.map((usuario) {
                        return DropdownMenuItem<Usuario>(
                          value: usuario,
                          child: Text(usuario.nome ?? usuario.email),
                        );
                      }).toList(),
                      onChanged: (Usuario? newValue) {
                        setDialogState(() {
                          selectedUser = newValue;
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2026),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Colors.green),
                              dialogBackgroundColor: const Color(0xFF16213E),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Text(
                        startDate == null
                            ? 'Selecionar Data Início'
                            : 'Início: ${DateFormat('dd/MM/yyyy').format(startDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2026),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Colors.green),
                              dialogBackgroundColor: const Color(0xFF16213E),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'Selecionar Data Fim'
                            : 'Fim: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextField(
                      controller: infoController,
                      decoration: const InputDecoration(labelText: 'Motivo (máx. 10 caracteres)'),
                      maxLength: 10,
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
                    if (selectedUser == null || startDate == null || endDate == null || infoController.text.isEmpty) {
                      _showError('Preencha todos os campos.');
                      return;
                    }
                    if (endDate!.isBefore(startDate!)) {
                      _showError('A data final deve ser após a data inicial.');
                      return;
                    }
                    try {
                      final newPeriod = UserPeriod(
                        id: 0,
                        usuarioId: selectedUser!.id,
                        startDate: startDate!,
                        endDate: endDate!,
                        info: infoController.text,
                      );
                      await _authService.addUserPeriod(newPeriod);
                      final updatedPeriods = await _authService.getAllUserPeriods();
                      setState(() {
                        _userPeriods = updatedPeriods;
                      });
                      _showError('Período adicionado com sucesso!');
                      Navigator.pop(context);
                    } catch (e) {
                      _showError('Erro ao adicionar período: $e');
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUserPeriod(UserPeriod period) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja excluir este período de indisponibilidade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _authService.deleteUserPeriod(period.id);
      final updatedPeriods = await _authService.getAllUserPeriods();
      setState(() {
        _userPeriods = updatedPeriods;
      });
      _showError('Período excluído com sucesso!');
    } catch (e) {
      _showError('Erro ao excluir período: $e');
    }
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
      'Sem Setor': _usuarios.where((u) => u.setor == null || u.setor!.isEmpty).toList()
        ..sort((a, b) => (a.nome ?? a.email).compareTo(b.nome ?? b.email)),
    };

    final sectorColors = {
      'Suporte': const Color.fromARGB(255, 232, 94, 1),
      'Suporte/Consultor': const Color.fromARGB(255, 238, 1, 1),
      'Cloud': Colors.blue,
      'ADM': const Color.fromARGB(255, 189, 20, 251),
      'DEV': const Color.fromARGB(255, 1, 106, 40),
      'Externo': const Color.fromARGB(255, 113, 211, 238),
      'QA': const Color.fromARGB(255, 207, 217, 4),
      'Sem Setor': Colors.grey,
    };

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Gerenciar Usuários',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addNewUserPeriod(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                          shadowColor: Colors.green.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Adicionar Período de Indisponibilidade',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _addOrEditUsuario(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                          shadowColor: Colors.yellow.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Adicionar Usuário',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: sectorColors[sector] ?? Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...users.map((usuario) {
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
                                  Expanded(
                                    child: Text(
                                      usuario.nome ?? usuario.email,
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8.0,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _manageUserPeriods(usuario),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          elevation: 5,
                                          shadowColor: Colors.green.withOpacity(0.5),
                                        ),
                                        child: const Text(
                                          'Gerenciar Indisponibilidade',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: () => _addOrEditUsuario(usuario: usuario),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Editar Usuário',
                                      ),
                                    ],
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
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
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