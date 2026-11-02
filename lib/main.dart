import 'package:flutter/material.dart';
import 'package:nivel_certo/screens/tela_login.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nível Certo',
      // Remover a faixa vermelha de Debug
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Selecionand a tela de Login para iniciar o app
      home: const LoginScreen(),
    );
  }
}
