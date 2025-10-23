import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../../app/routes/app_routes.dart';

class NovaOrdemView extends StatefulWidget {
  const NovaOrdemView({super.key});

  @override
  State<NovaOrdemView> createState() => _NovaOrdemViewState();
}

class _NovaOrdemViewState extends State<NovaOrdemView> {
  final clientes = ['Cliente A', 'Cliente B', 'Cliente C'];
  final tiposServico = [
    'Manutenção elétrica',
    'Troca de peça',
    'Instalação',
    'Reparo hidráulico',
    'Limpeza e conservação',
    'Inspeção preventiva',
    'Outros',
  ];

  String? clienteSelecionado;
  String? tipoSelecionado;
  final TextEditingController tipoCustomCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();

  @override
  void dispose() {
    tipoCustomCtrl.dispose();
    valorCtrl.dispose();
    super.dispose();
  }

  bool get isOutros => tipoSelecionado == 'Outros';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            FocusScope.of(context).unfocus();
            return false;
          },
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
                  items: clientes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  initialValue: clienteSelecionado,
                  onChanged: (v) => setState(() => clienteSelecionado = v),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Detalhes do Serviço',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo de Serviço'),
                  items: tiposServico
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  initialValue: tipoSelecionado,
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
                      hintText: 'Ex: Pintura de portões, troca de interfones…',
                    ),
                  ),

                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descrição do Trabalho',
                    hintText: 'Ex: Troca de lâmpadas do corredor do bloco A',
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
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.detalheOrdem),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Gerar Ordem'),
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
