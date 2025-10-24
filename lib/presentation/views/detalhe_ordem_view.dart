// lib/presentation/views/detalhe_ordem_view.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ordem_simples_app/presentation/views/pdf/exportar_pdf_view.dart';
import '../../core/user_session.dart';
import '../../services/ordem_service.dart';
import 'assinatura_view.dart';

class DetalheOrdemView extends StatefulWidget {
  final String ordemId;
  const DetalheOrdemView({super.key, required this.ordemId});

  @override
  State<DetalheOrdemView> createState() => _DetalheOrdemViewState();
}

class _DetalheOrdemViewState extends State<DetalheOrdemView> {
  final _service = OrdemService();
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final _date = DateFormat('dd/MM/yyyy HH:mm');

  final _formKey = GlobalKey<FormState>();
  final _assinanteNomeCtrl = TextEditingController();
  final _assinanteFuncaoCtrl = TextEditingController();
  bool _confirmouAssinatura = false;

  Map<String, dynamic>? _ordem;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _carregarOrdem();
  }

  String _fmt(dynamic iso) {
    if (iso == null) return '—';
    try {
      return _date.format(DateTime.parse(iso.toString()).toLocal());
    } catch (_) {
      return iso.toString();
    }
  }

  Future<void> _carregarOrdem() async {
    setState(() => _loading = true);
    final data = await _service.obterOrdemPorId(
      loginId: UserSession.loginId!,
      ordemId: widget.ordemId,
    );
    setState(() {
      _ordem = data;
      _loading = false;

      _assinanteNomeCtrl.text = (_ordem?['assinante_nome'] ?? '').toString();
      _assinanteFuncaoCtrl.text = (_ordem?['assinante_funcao'] ?? '').toString();
      _confirmouAssinatura = (_ordem?['status']?.toString().toLowerCase() == 'concluída' ||
          _ordem?['status']?.toString().toLowerCase() == 'concluida');
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem assinada com sucesso!')),
      );
      await _carregarOrdem();
    }
  }

  Future<void> _concluirOrdem() async {
    final status = (_ordem?['status'] ?? '').toString();
    if (status.toLowerCase() != 'assinada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assine a ordem antes de concluir.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || !_confirmouAssinatura) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirme a assinatura e preencha nome e função.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.concluirOrdem(
        loginId: UserSession.loginId!,
        ordemId: widget.ordemId,
        assinanteNome: _assinanteNomeCtrl.text.trim(),
        assinanteFuncao: _assinanteFuncaoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem concluída!')),
      );
      await _carregarOrdem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _exportarPdf() {
    final status = (_ordem?['status'] ?? '').toString();
    if (status.toLowerCase() != 'concluída' && status.toLowerCase() != 'concluida') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conclua a OS antes de exportar o PDF.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportarPdfView(ordem: _ordem!),
      ),
    );
  }

  @override
  void dispose() {
    _assinanteNomeCtrl.dispose();
    _assinanteFuncaoCtrl.dispose();
    super.dispose();
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
    final status = (_ordem!['status'] ?? '—').toString();
    final isConcluida = status.toLowerCase() == 'concluída' || status.toLowerCase() == 'concluida';

    final assinanteNome = (_ordem?['assinante_nome'] ?? '').toString();
    final assinanteFuncao = (_ordem?['assinante_funcao'] ?? '').toString();
    final assinadoEm = _fmt(_ordem?['assinado_em']);
    final concluidoEm = _fmt(_ordem?['concluido_em']);

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
            Text('Status: $status'),
            const SizedBox(height: 8),
            Text('Valor: ${valor == null ? '—' : _currency.format(valor)}'),
            const SizedBox(height: 24),

            if (assinatura != null && assinatura.isNotEmpty) ...[
              const Text('Assinatura:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Image.memory(base64Decode(assinatura), height: 120, fit: BoxFit.contain),
              const SizedBox(height: 16),

              // 🔁 Se NÃO estiver concluída: mostra form para concluir
              if (!isConcluida)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _confirmouAssinatura,
                        onChanged: (v) => setState(() => _confirmouAssinatura = v ?? false),
                        title: const Text('Confirmo que assinei esta ordem de serviço.'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _assinanteNomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome do assinante',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome do assinante'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _assinanteFuncaoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Função do assinante',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe a função do assinante'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _concluirOrdem,
                          icon: _saving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_saving ? 'Salvando...' : 'Concluir OS'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isConcluida) ...[
                Card(
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Ordem concluída',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Assinante: ${assinanteNome.isEmpty ? '—' : assinanteNome}'),
                        Text('Função: ${assinanteFuncao.isEmpty ? '—' : assinanteFuncao}'),
                        const SizedBox(height: 6),
                        Text('Assinada em: $assinadoEm', style: TextStyle(color: Colors.grey.shade700)),
                        Text('Concluída em: $concluidoEm', style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isConcluida ? null : _abrirAssinatura,
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Assinar'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportarPdf,
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
