import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ordem_simples_app/services/empresa/empresa_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ordem_simples_app/presentation/views/home_view.dart';
import '../../core/user_session.dart';
import '../../model/login_model.dart';
import '../../services/login/login_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;
  bool _manterConectado = false;
  bool _verificandoLogin = true;

  final colorPrimary = Colors.blue.shade700;

  @override
  void initState() {
    super.initState();
    _verificarLoginSalvo();
  }

  Future<void> _verificarLoginSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      if (userJson != null) {
        final saved = LoginModel.fromJson(userJson);
        UserSession.fromLoginModel(saved);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
        return;
      }
    } catch (e) {
      debugPrint('Falha ao recuperar sessão salva: $e');
    } finally {
      if (mounted) setState(() => _verificandoLogin = false);
    }
  }

  Future<void> _salvarSessao(LoginModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', user.toJson()); // usa toJson() do modelo
  }

  Future<void> _limparSessaoSalva() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final service = LoginService();
    final serviceEmpresa = EmpresaService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.engineering_rounded,
                      size: 72, color: colorPrimary),
                ),
                const SizedBox(height: 20),

                Text(
                  'Ordem Simples',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: colorPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // E-mail
                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined, color: colorPrimary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colorPrimary, width: 1.8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite seu e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline, color: colorPrimary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorPrimary,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colorPrimary, width: 1.8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite sua senha';
                    if (v.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  value: _manterConectado,
                  onChanged: (v) =>
                      setState(() => _manterConectado = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Manter conectado'),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: colorPrimary,
                          content: const Text('Verificando credenciais...'),
                        ),
                      );

                      try {
                        final LoginModel? user = await service.autenticarTyped(
                          email: _emailCtrl.text.trim(),
                          senha: _senhaCtrl.text.trim(),
                        );

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('E-mail ou senha incorretos')),
                          );
                          return;
                        }

                        UserSession.fromLoginModel(user);

                        if (_manterConectado) {
                          await _salvarSessao(user);
                        } else {
                          await _limparSessaoSalva();
                        }

                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeView()),
                              (route) => false,
                        );
                      } catch (e) {
                        final msg = e.toString();
                        final offline =
                            msg.contains('SocketException') || msg.contains('Failed host lookup');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              offline
                                  ? 'Sem conexão com o Supabase. Verifique sua internet e tente novamente.'
                                  : 'Erro ao autenticar: $e',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Entrar',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Versão 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }
}
