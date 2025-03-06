import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:status_dp_app/models/usuario.dart';
import 'package:status_dp_app/models/status.dart';
import 'package:status_dp_app/models/planner.dart';
import 'package:status_dp_app/models/horario_trabalho.dart';
import 'package:status_dp_app/services/auth_service.dart';
import 'package:intl/intl.dart';

class StatusDPScreen extends StatefulWidget {
  const StatusDPScreen({super.key});

  @override
  State<StatusDPScreen> createState() => _StatusDPScreenState();
}

class _StatusDPScreenState extends State<StatusDPScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  Usuario? _usuario;
  List<Status> _statuses = [];
  List<Planner> _planner = [];
  List<HorarioTrabalho> _horariosTrabalho = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
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

  Future<void> _login() async {
    try {
      final usuario = await _authService.login(_emailController.text, _senhaController.text);
      setState(() {
        _usuario = usuario;
      });
      _loadUserData();
      _loadPlanner();
      _loadHorarioTrabalho();
    } catch (e) {
      _showError('Erro ao fazer login: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (_usuario != null) {
      try {
        final userData = await _authService.getUserData(_usuario!.email);
        setState(() {
          _usuario = userData;
        });
      } catch (e) {
        _showError('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _loadPlanner() async {
    if (_usuario != null) {
      try {
        final planner = await _authService.getPlanner(_usuario!.id, _selectedDate);
        setState(() {
          _planner = planner;
        });
      } catch (e) {
        _showError('Erro ao carregar planner: $e');
      }
    }
  }

  Future<void> _loadHorarioTrabalho() async {
    if (_usuario != null) {
      try {
        final horarios = await _authService.getHorarioTrabalho(_usuario!.id, _selectedDate.weekday);
        setState(() {
          _horariosTrabalho = horarios;
        });
      } catch (e) {
        _showError('Erro ao carregar horários de trabalho: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status DP'),
      ),
      body: _usuario == null
          ? _buildLoginForm()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vindo, ${_usuario!.nome ?? _usuario!.email}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Setor: ${_usuario!.setor ?? "Não especificado"}'),
                    Text('Status: ${_usuario!.status ?? "DISPONIVEL"}'),
                    Text('Horário de Trabalho: ${_usuario!.horarioInicioTrabalho ?? "08:00"} - ${_usuario!.horarioFimTrabalho ?? "18:00"}'),
                    Text('Almoço: ${_usuario!.horarioAlmocoInicio ?? "12:00"} - ${_usuario!.horarioAlmocoFim ?? "13:00"}'),
                    Text('Gestão: ${_usuario!.horarioGestaoInicio ?? "15:00"} - ${_usuario!.horarioGestaoFim ?? "16:00"}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Planner para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          child: const Text('Selecionar Data'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._planner.map((p) => ListTile(
                          title: Text('${p.hora} - ${p.status}'),
                          subtitle: Text(p.informacao ?? 'Sem informações'),
                        )),
                    const SizedBox(height: 16),
                    Text('Horários de Trabalho (Dia ${_selectedDate.weekday})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._horariosTrabalho.map((h) => ListTile(
                          title: Text('Horário: ${h.horarioInicio} - ${h.horarioFim}'),
                          subtitle: Text(
                              'Almoço: ${h.horarioAlmocoInicio ?? "Não definido"} - ${h.horarioAlmocoFim ?? "Não definido"}, Gestão: ${h.horarioGestaoInicio ?? "Não definido"} - ${h.horarioGestaoFim ?? "Não definido"}'),
                        )),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      hint: const Text('Alterar Status'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue;
                          // Aqui você pode adicionar a lógica para atualizar o status via API (POST ou PUT)
                        });
                      },
                      items: _statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status.status,
                          child: Text(status.status),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _usuario = null;
                          _planner.clear();
                          _horariosTrabalho.clear();
                          _selectedStatus = null;
                        });
                        _emailController.clear();
                        _senhaController.clear();
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _senhaController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _login,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}