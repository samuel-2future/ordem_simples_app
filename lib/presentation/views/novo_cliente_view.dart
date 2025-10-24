import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
import '../../core/user_session.dart';
import '../../services/cliente_service.dart';

class NovoClienteView extends StatefulWidget {
  const NovoClienteView({super.key});
  @override
  State<NovoClienteView> createState() => _NovoClienteViewState();
}

class _NovoClienteViewState extends State<NovoClienteView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _compCtrl = TextEditingController();

  final _svc = ClienteService();
  bool _loading = false;
  bool _buscandoEndereco = false;
  String? _tipoResidencia;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _cepCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _compCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarEndereco() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _buscandoEndereco = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) throw Exception('CEP não encontrado');
        _ruaCtrl.text = (data['logradouro'] ?? '').toString();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP: $e')),
      );
    } finally {
      if (mounted) setState(() => _buscandoEndereco = false);
    }
  }

  String? _validarEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null; // opcional
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!regex.hasMatch(email.trim())) return 'E-mail inválido';
    return null;
  }

  Future<void> _salvar() async {
    if (UserSession.loginId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final telefone = toNumericString(_telCtrl.text); // só dígitos
      final cep = toNumericString(_cepCtrl.text);      // só dígitos

      await _svc.criarCliente(
        loginId: UserSession.loginId!,                    // <- vínculo com usuário logado
        nome: _nomeCtrl.text.trim(),
        telefone: telefone.isEmpty ? null : _telCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        cep: cep.isEmpty ? null : _cepCtrl.text.trim(),
        rua: _ruaCtrl.text.trim().isEmpty ? null : _ruaCtrl.text.trim(),
        numero: _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
        tipoResidencia: _tipoResidencia,
        complemento: _compCtrl.text.trim().isEmpty ? null : _compCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente cadastrado com sucesso!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10));

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: InputDecoration(labelText: 'Nome', border: border),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telCtrl,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(DD) 90000-0000',
                  border: border,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter(defaultCountryCode: 'BR')],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o telefone';
                  final digits = toNumericString(v);
                  if (digits.length < 10) return 'Telefone inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'Email', border: border),
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cepCtrl,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  border: border,
                  suffixIcon: _buscandoEndereco
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _buscarEndereco,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [MaskedInputFormatter('#####-###')],
                onFieldSubmitted: (_) => _buscarEndereco(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ruaCtrl,
                decoration: InputDecoration(labelText: 'Rua', border: border),
                readOnly: _buscandoEndereco,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _numeroCtrl,
                decoration: InputDecoration(labelText: 'Número', border: border),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _tipoResidencia,
                decoration: InputDecoration(labelText: 'Tipo de Residência', border: border),
                items: const [
                  DropdownMenuItem(value: 'Casa', child: Text('Casa')),
                  DropdownMenuItem(value: 'Apartamento', child: Text('Apartamento')),
                ],
                onChanged: (v) => setState(() => _tipoResidencia = v),
                validator: (v) => v == null ? 'Selecione o tipo de residência' : null,
              ),
              const SizedBox(height: 12),

              if (_tipoResidencia == 'Apartamento')
                TextFormField(
                  controller: _compCtrl,
                  decoration: InputDecoration(
                    labelText: 'Complemento (Bloco/Torre/Apto)',
                    hintText: 'Ex: Bloco 2, Apto 304, Torre B...',
                    border: border,
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _salvar,
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
