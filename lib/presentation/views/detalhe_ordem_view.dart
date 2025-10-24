import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/user_session.dart';
import '../../services/ordem_service.dart';
import 'assinatura_view.dart'; // 👈 importe direto

class DetalheOrdemView extends StatefulWidget {
  final String ordemId;
  const DetalheOrdemView({super.key, required this.ordemId});

  @override
  State<DetalheOrdemView> createState() => _DetalheOrdemViewState();
}

class _DetalheOrdemViewState extends State<DetalheOrdemView> {
  final _service = OrdemService();
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  Map<String, dynamic>? _ordem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarOrdem();
  }

  Future<void> _carregarOrdem() async {
    final data = await _service.obterOrdemPorId(
      loginId: UserSession.loginId!,
      ordemId: widget.ordemId,
    );
    setState(() {
      _ordem = data;
      _loading = false;
    });
  }

  Future<void> _abrirAssinatura() async {
    final assinaturaBytes = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssinaturaView()),
    );

    if (assinaturaBytes != null && assinaturaBytes is Uint8List) {
      await _service.atualizarStatusAssinado(
        loginId: UserSession.loginId!,
        ordemId: widget.ordemId,
        assinatura: assinaturaBytes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem assinada com sucesso!')),
      );
      await _carregarOrdem();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ordem == null) {
      return const Scaffold(
        body: Center(child: Text('Ordem não encontrada.')),
      );
    }

    final cliente = _ordem!['clientes'] as Map<String, dynamic>?;
    final valor = (_ordem!['valor'] as num?)?.toDouble();
    final assinatura = _ordem!['assinatura_base64'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Ordem')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Cliente: ${cliente?['nome'] ?? '—'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Serviço: ${_ordem!['tipo_servico'] ?? '—'}'),
            const SizedBox(height: 8),
            Text('Descrição: ${_ordem!['descricao'] ?? '—'}'),
            const SizedBox(height: 8),
            Text('Status: ${_ordem!['status'] ?? '—'}'),
            const SizedBox(height: 8),
            Text('Valor: ${valor == null ? '—' : _currency.format(valor)}'),
            const SizedBox(height: 24),
            if (assinatura != null && assinatura.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assinatura:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Image.memory(
                    base64Decode(assinatura),
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _abrirAssinatura,
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Assinar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: exportar PDF
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
