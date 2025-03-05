import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/status_service.dart';

class StatusDPScreen extends StatefulWidget {
  final String nome;
  final String setor;

  const StatusDPScreen({super.key, required this.nome, required this.setor});

  @override
  _StatusDPScreenState createState() => _StatusDPScreenState();
}

class _StatusDPScreenState extends State<StatusDPScreen> {
  String? selectedStatus; // Valor selecionado
  List<Map<String, dynamic>> statusList = []; // Lista de status carregada da API
  bool isLoading = true; // Indicador de carregamento

  @override
  void initState() {
    super.initState();
    _fetchStatus(); // Carrega os status ao iniciar a tela
  }

  Future<void> _fetchStatus() async {
    final statusService = StatusService();
    try {
      final response = await statusService.getStatus();
      print('Status recebidos na tela: $response');

      if (response.isNotEmpty) {
        setState(() {
          statusList = response;
          // Define "DISPONIVEL" como status padrão, se existir na lista
          selectedStatus = statusList.firstWhere(
            (status) => status['status'] == 'DISPONIVEL',
            orElse: () => statusList[0], // Se "DISPONIVEL" não existir, usa o primeiro status
          )['status'];
          isLoading = false;
        });
      } else {
        setState(() {
          statusList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar status na tela: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar status: $e')),
      );
    }
  }

  // Mapear status para ícones e cores
  Map<String, IconData> statusIcons = {
    'DISPONIVEL': Icons.check_circle_outline,
    'AUSENTE': Icons.person_off,
    'OCUPADO': Icons.work,
    'NÃO INCOMODAR': Icons.do_not_disturb_on,
  };

  Map<String, Color> statusColors = {
    'DISPONIVEL': Colors.green,
    'AUSENTE': Colors.grey,
    'OCUPADO': Colors.orange,
    'NÃO INCOMODAR': Colors.red,
  };

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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
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

                      if (isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else if (statusList.isEmpty)
                        const Text(
                          'Nenhum status disponível.',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        SizedBox(
                          height: 150, // Altura fixa para a lista horizontal
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: statusList.length,
                            itemBuilder: (context, index) {
                              final status = statusList[index]['status'] as String;
                              final isSelected = selectedStatus == status;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStatus = status;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? statusColors[status]!.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? statusColors[status]!
                                            : Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          statusIcons[status] ?? Icons.circle,
                                          color: isSelected ? Colors.white : Colors.white70,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedStatus != null) {
                            // Aqui você pode adicionar a lógica para salvar o status selecionado (via API, por exemplo)
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
            ],
          ),
        ),
      ),
    );
  }
}