import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/status.dart';
import '../models/planner.dart';
import '../models/horario_trabalho.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart'; // Adicionada a importação correta do LoginScreen

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
              ..._planner.map((p) => Padding(
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
                          '${p.hora} - ${p.status}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          p.informacao ?? 'Sem informações',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  )),
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
                          'Almoço: ${h.horarioAlmocoInicio ?? "Não definido"} - ${h.horarioAlmocoFim ?? "Não definido"}, Gestão: ${h.horarioGestaoInicio ?? "Não definido"} - ${h.horarioGestaoFim ?? "Não definido"}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  hint: const Text(
                    'Alterar Status',
                    style: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: Colors.white.withOpacity(0.1),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
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