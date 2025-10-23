import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
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
        _ruaCtrl.text = data['logradouro'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP: $e')),
      );
    } finally {
      setState(() => _buscandoEndereco = false);
    }
  }

  Future<void> _salvar() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await _svc.criarCliente(
        nome: _nomeCtrl.text.trim(),
        telefone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        endereco: _ruaCtrl.text.trim(),
        numero: _numeroCtrl.text.trim(),
        complemento: _tipoResidencia == 'Apartamento'
            ? _compCtrl.text.trim()
            : null,
        cep: _cepCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente cadastrado com sucesso!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validarEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null; // opcional
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!regex.hasMatch(email.trim())) return 'E-mail inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(DDD) XXXXX-XXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o telefone';
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Telefone inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cepCtrl,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  suffixIcon: _buscandoEndereco
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _buscarEndereco,
                  ),
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _buscarEndereco(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ruaCtrl,
                decoration: const InputDecoration(labelText: 'Rua'),
                readOnly: _buscandoEndereco,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroCtrl,
                decoration: const InputDecoration(labelText: 'Número'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              /// 🔹 Dropdown de tipo de residência
              DropdownButtonFormField<String>(
                value: _tipoResidencia,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Residência',
                ),
                items: const [
                  DropdownMenuItem(value: 'Casa', child: Text('Casa')),
                  DropdownMenuItem(value: 'Apartamento', child: Text('Apartamento')),
                ],
                onChanged: (v) => setState(() => _tipoResidencia = v),
                validator: (v) =>
                v == null ? 'Selecione o tipo de residência' : null,
              ),

              const SizedBox(height: 12),

              /// 🔹 Campo de complemento (só se for apartamento)
              if (_tipoResidencia == 'Apartamento')
                TextFormField(
                  controller: _compCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Complemento (Bloco / Torre / Apto)',
                    hintText: 'Ex: Bloco 2, Apto 304, Torre B...',
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
