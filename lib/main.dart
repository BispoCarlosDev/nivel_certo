import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nivel_certo/screens/tela_login.dart';
import 'package:nivel_certo/screens/tela_minhascaixas.dart';
import 'package:nivel_certo/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ngepvftlssgcqodxkgye.supabase.co',
    publishableKey: 'sb_publishable_fuiNXjuLAfXOAjx6lESA3Q_xOtrn-Qp',
  );
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
      // Idioma português do Brasil (calendário, botões e textos do sistema)
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Quem já está logado vai direto para Minhas Caixas; os demais, para o Login
      home: AuthService.instance.logado
          ? const MinhasCaixasScreen()
          : const LoginScreen(),
    );
  }
}
