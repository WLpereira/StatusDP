import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller; // Controlador para o campo de texto
  final String labelText; // Rótulo do campo de texto
  final bool obscureText; // Define se o texto deve ser obscurecido (útil para senhas)
  final IconData? icon; // Ícone opcional para o campo de texto

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white), // Estilo do texto digitado
      decoration: InputDecoration(
        labelText: labelText, // Rótulo do campo
        labelStyle: const TextStyle(color: Colors.white70), // Estilo do rótulo
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null, // Ícone prefixo (se fornecido)
        filled: true, // Preenche o fundo do campo
        fillColor: Colors.white.withOpacity(0.1), // Cor de fundo do campo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Borda arredondada
          borderSide: BorderSide.none, // Sem borda
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Borda arredondada quando o campo está habilitado
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // Cor da borda
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Borda arredondada quando o campo está em foco
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2), // Cor e espessura da borda
        ),
      ),
    );
  }
}