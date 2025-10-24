import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../../core/user_session.dart';
import '../../services/ordem_service.dart';
import '../../services/cliente_service.dart';

class NovaOrdemView extends StatefulWidget {
  const NovaOrdemView({super.key});

  @override
  State<NovaOrdemView> createState() => _NovaOrdemViewState();
}

class _NovaOrdemViewState extends State<NovaOrdemView> {
  final _ordemSvc = OrdemService();
  final _clienteSvc = ClienteService();

  List<Map<String, dynamic>> _clientes = [];
  String? _clienteSelecionadoId;
  bool _carregandoClientes = true;
  bool _salvando = false;

  final tiposServico = [
    'Manutenção elétrica',
    'Troca de peça',
    'Instalação',
    'Reparo hidráulico',
    'Limpeza e conservação',
    'Inspeção preventiva',
    'Outros',
  ];

  String? tipoSelecionado;
  final TextEditingController tipoCustomCtrl = TextEditingController();
  final TextEditingController descricaoCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();

  bool get isOutros => tipoSelecionado == 'Outros';

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    try {
      final clientes = await ClienteService().listarClientesDoLogin(UserSession.loginId!);
      setState(() => _clientes = clientes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar clientes: $e')),
      );
    } finally {
      setState(() => _carregandoClientes = false);
    }
  }

  Future<void> _salvarOrdem() async {
    if (_clienteSelecionadoId == null || tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o cliente e o tipo de serviço.')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final valor = double.tryParse(
        valorCtrl.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'),
      );

      if (UserSession.loginId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
        );
        return;
      }

      await _ordemSvc.criarOrdem(
        loginId: UserSession.loginId!,
        clienteId: _clienteSelecionadoId!,
        tipoServico: isOutros ? tipoCustomCtrl.text.trim() : tipoSelecionado!,
        descricao: descricaoCtrl.text.trim(),
        valor: valor,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem de serviço criada com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar ordem: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    tipoCustomCtrl.dispose();
    descricaoCtrl.dispose();
    valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: _carregandoClientes
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'Dados do Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: _clientes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'].toString(),
                    child: Text(c['nome'] ?? 'Sem nome'),
                  );
                }).toList(),
                value: _clienteSelecionadoId,
                onChanged: (v) => setState(() => _clienteSelecionadoId = v),
              ),

              const SizedBox(height: 24),
              const Text(
                'Detalhes do Serviço',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration:
                const InputDecoration(labelText: 'Tipo de Serviço'),
                items: tiposServico
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                value: tipoSelecionado,
                onChanged: (v) => setState(() {
                  tipoSelecionado = v;
                  if (!isOutros) tipoCustomCtrl.clear();
                }),
              ),

              const SizedBox(height: 12),
              if (isOutros)
                TextField(
                  controller: tipoCustomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descreva o tipo de serviço',
                    hintText:
                    'Ex: Pintura de portões, troca de interfones…',
                  ),
                ),

              const SizedBox(height: 12),
              TextField(
                controller: descricaoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Trabalho',
                  hintText:
                  'Ex: Troca de lâmpadas do corredor do bloco A',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valor do Trabalho',
                  hintText: 'Ex: R\$ 250,00',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol: 'R\$ ',
                    useSymbolPadding: true,
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 2,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvarOrdem,
                  icon: _salvando
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_salvando ? 'Salvando...' : 'Gerar Ordem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
