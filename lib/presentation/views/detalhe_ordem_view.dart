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
    final status = (_ordem?['status'] ?? '').toString().toLowerCase();
    final assinaturaBase64 = (_ordem?['assinatura_base64'] ?? '').toString();

    if (assinaturaBase64.isEmpty) {
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
    final isConcluida =
        status.toLowerCase() == 'concluída' || status.toLowerCase() == 'concluida';

    final assinanteNome = (_ordem?['assinante_nome'] ?? '').toString();
    final assinanteFuncao = (_ordem?['assinante_funcao'] ?? '').toString();
    final assinadoEm = _fmt(_ordem?['assinado_em']);
    final concluidoEm = _fmt(_ordem?['concluido_em']);

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'concluída':
      case 'concluida':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        break;
      case 'assinada':
        statusColor = Colors.blue.shade700;
        statusIcon = Icons.edit_document;
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.pending_actions_outlined;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text('Detalhes da Ordem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔷 Cabeçalho do status
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor, size: 36),
                  title: Text(
                    'Status: $status',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    _ordem!['tipo_servico'] ?? 'Serviço não informado',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🧍 Dados do Cliente
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados do Cliente',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 4),
                      _infoRow(Icons.person, 'Nome', cliente?['nome'] ?? '—'),
                      _infoRow(Icons.email_outlined, 'E-mail', cliente?['email'] ?? '—'),
                      _infoRow(Icons.phone, 'Telefone', cliente?['telefone'] ?? '—'),
                      _infoRow(
                        Icons.location_on_outlined,
                        'Endereço',
                        '${cliente?['rua'] ?? '—'}, ${cliente?['numero'] ?? ''}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🧰 Dados da Ordem
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalhes da Ordem',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      _infoRow(Icons.description_outlined, 'Descrição',
                          _ordem!['descricao'] ?? '—'),
                      _infoRow(Icons.attach_money, 'Valor',
                          valor == null ? '—' : _currency.format(valor)),
                      const SizedBox(height: 4),
                      if (assinatura != null && assinatura.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Assinatura:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(assinatura),
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ⏳ Linha do Tempo
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Linha do Tempo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      _timelineTile(Icons.play_circle, 'Criada em',
                          _fmt(_ordem?['created_at']), Colors.grey.shade700),
                      _timelineTile(Icons.edit_document, 'Assinada em', assinadoEm,
                          Colors.blue.shade700),
                      _timelineTile(Icons.check_circle_outline, 'Concluída em',
                          concluidoEm, Colors.green.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✍️ Formulário de conclusão
              if (assinatura != null && assinatura.isNotEmpty && !isConcluida)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue.shade50,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _confirmouAssinatura,
                            onChanged: (v) =>
                                setState(() => _confirmouAssinatura = v ?? false),
                            title: const Text(
                                'Confirmo que assinei esta ordem de serviço.'),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _saving ? null : _concluirOrdem,
                              icon: _saving
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _saving ? 'Salvando...' : 'Concluir OS',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (isConcluida)
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
                        Text('Assinada em: $assinadoEm',
                            style: TextStyle(color: Colors.grey.shade700)),
                        Text('Concluída em: $concluidoEm',
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // ⚙️ Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConcluida ? null : _abrirAssinatura,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.draw_outlined),
                      label: const Text('Assinar Ordem'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportarPdf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// 🔹 Helper para info row
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// 🔹 Helper para linha do tempo
  Widget _timelineTile(IconData icon, String label, String data, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: data,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
