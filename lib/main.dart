import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/variaveis/globais.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var variaveis = new Globais();

  await Supabase.initialize(
    url: variaveis.SUPABASE_URL,
    anonKey: variaveis.SUPABASE_ANON_KEY,
  );

  runApp(const OrdemSimplesApp());
}

class OrdemSimplesApp extends StatelessWidget {
  const OrdemSimplesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordem Simples',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
