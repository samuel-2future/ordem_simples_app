import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ordem_simples_app/presentation/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/variaveis/globais.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Corrige a assinatura: 2 argumentos (locale, data)
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  final variaveis = Globais();

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
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const LoginView(),
    );
  }
}
