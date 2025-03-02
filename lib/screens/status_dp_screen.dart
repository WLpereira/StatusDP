import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/status_service.dart'; // Verifique o caminho da importação

class StatusDPScreen extends StatefulWidget {
  final String nome;
  final String setor;

  const StatusDPScreen({super.key, required this.nome, required this.setor});

  @override
  _StatusDPScreenState createState() => _StatusDPScreenState();
}

class _StatusDPScreenState extends State<StatusDPScreen> {
  List<Map<String, dynamic>> statusList = [];
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final statusService = StatusService(); // Instância correta da classe
      final statuses = await statusService.getStatus();
      setState(() {
        statusList = statuses;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar status: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disponivel':
        return Colors.green;
      case 'Ocupado':
        return Colors.red;
      case 'Ausente':
        return Colors.orange;
      case 'Não Incomodar':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Bem-vindo, ${widget.nome}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Setor: ${widget.setor}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                ...statusList.map((status) {
                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status['nome']),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      status['nome'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Radio<String>(
                      value: status['nome'],
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (selectedStatus != null) {
                      // Aqui você pode adicionar a lógica para salvar o status selecionado
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status selecionado: $selectedStatus')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione um status')),
                      );
                    }
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
                    'Salvar Status',
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
      ),
    );
  }
}