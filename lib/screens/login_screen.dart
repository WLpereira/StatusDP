import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar o pacote
import '../services/auth_service.dart';
import 'status_dp_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _savePassword = false; // Estado da checkbox
  bool _obscurePassword = true; // Estado para controlar a visibilidade da senha
  List<String> _userEmails = []; // Lista para armazenar os emails dos usuários

  // Lista de emails permitidos para acessar a AdminScreen
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
    _loadUserEmails(); // Carregar os emails ao iniciar a tela
    _loadSavedCredentials(); // Carregar email e senha salvos
    _checkSession(); // Verificar se há uma sessão ativa
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final lastLogin = prefs.getInt('last_login');

    if (savedEmail != null && savedPassword != null && lastLogin != null) {
      // Verifica se o último login foi há menos de 7 dias
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastLogin < const Duration(days: 7).inMilliseconds) {
        // Tenta fazer login automático
        final usuario = await _authService.login(savedEmail, savedPassword);
        if (usuario != null) {
          if (_adminEmails.contains(savedEmail)) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen(usuario: usuario)),
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StatusDPScreen(usuario: usuario)),
              );
            }
          }
        }
      }
    }
  }

  // Método para carregar os emails dos usuários do banco de dados
  Future<void> _loadUserEmails() async {
    try {
      final usuarios = await _authService.getAllUsuarios();
      setState(() {
        _userEmails = usuarios.map((usuario) => usuario.email).toList();
      });
    } catch (e) {
      _showError('Erro ao carregar emails: $e');
    }
  }

  // Método para carregar email e senha salvos
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final savePassword = prefs.getBool('save_password') ?? false;

    setState(() {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      _savePassword = savePassword;
    });
  }

  // Método para salvar email e senha
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_savePassword) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setBool('save_password', true);
      // Salva o timestamp do login
      await prefs.setInt('last_login', DateTime.now().millisecondsSinceEpoch);
    } else {
      // Limpar os dados salvos se a checkbox não estiver marcada
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('last_login');
      await prefs.setBool('save_password', false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor, preencha todos os campos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final usuario = await _authService.login(email, password);
      if (usuario != null) {
        // Salvar as credenciais se a checkbox estiver marcada
        await _saveCredentials();

        // Verifica se o email está na lista de administradores
        if (_adminEmails.contains(email)) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen(usuario: usuario)),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StatusDPScreen(usuario: usuario)),
            );
          }
        }
      } else {
        _showError('Usuário ou senha está errado.');
      }
    } catch (e) {
      _showError('Erro ao fazer login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
                  Icons.lock_outline,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bem-vindo ao PlannerDP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _userEmails.where((String email) {
                      return email.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _emailController.text = selection;
                    FocusScope.of(context).nextFocus(); // Move o foco para o campo de senha
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    // Sincronizar o controlador do Autocomplete com o _emailController
                    fieldTextEditingController.text = _emailController.text;
                    _emailController.addListener(() {
                      fieldTextEditingController.text = _emailController.text;
                    });
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: const Color(0xFF16213E),
                          width: MediaQuery.of(context).size.width - 32, // Ajusta a largura para o padding
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return GestureDetector(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  title: Text(
                                    option,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: 'Senha',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword; // Alterna a visibilidade da senha
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        child: Text(
                          _obscurePassword ? 'Mostrar' : 'Esconder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscurePassword, // Controla a visibilidade da senha
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _login();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _savePassword,
                      onChanged: (bool? value) {
                        setState(() {
                          _savePassword = value ?? false;
                        });
                      },
                      checkColor: Colors.white, // Cor do "check" dentro da checkbox
                      activeColor: Colors.blueAccent, // Cor de fundo quando marcada
                      side: const BorderSide(
                        color: Colors.white70, // Cor da borda da checkbox
                        width: 2,
                      ),
                    ),
                    const Text(
                      'Salvar senha',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
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
                          'Entrar',
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