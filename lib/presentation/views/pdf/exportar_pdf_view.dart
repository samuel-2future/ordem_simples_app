import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/user_session.dart';

class ExportarPdfView extends StatefulWidget {
  final Map<String, dynamic> ordem;
  const ExportarPdfView({super.key, required this.ordem});

  @override
  State<ExportarPdfView> createState() => _ExportarPdfViewState();
}

class _ExportarPdfViewState extends State<ExportarPdfView> {
  late Future<Uint8List> _pdfFuture;
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _pdfFuture = _gerarPdf();
  }

  PdfColor _lighten(PdfColor color, [double amount = 0.85]) {
    return PdfColor(
      1 - (1 - color.red) * amount,
      1 - (1 - color.green) * amount,
      1 - (1 - color.blue) * amount,
    );
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '—';
    try {
      return _dateTimeFmt.format(DateTime.parse(iso.toString()).toLocal());
    } catch (_) {
      return '—';
    }
  }

  Future<String?> _buscarMinhaEmpresa(dynamic id) async {
    try {
      final int? loginId = (id is int)
          ? id
          : int.tryParse(id?.toString() ?? '');
      if (loginId == null) return null;

      final res = await Supabase.instance.client
          .from('logins')
          .select('nome_empresa')
          .eq('id', loginId)
          .maybeSingle();

      return res?['nome_empresa'] as String?;
    } catch (e) {
      debugPrint('Erro ao buscar empresa: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> _buscarCliente(String id) async {
    try {
      final res = await Supabase.instance.client
          .from('clientes')
          .select('nome, rua, numero, telefone, email')
          .eq('id', id)
          .maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (e) {
      debugPrint('Erro ao buscar cliente: $e');
      return null;
    }
  }

  Future<Uint8List> _gerarPdf() async {
    final o = widget.ordem;
    final clienteId = o['cliente_id'];
    final cliente =
    clienteId != null ? await _buscarCliente(clienteId.toString()) : null;

    debugPrint('$o.toString()');
    final doc = pw.Document();

    final empresa = 'Ordem de Serviço';
    final empresaPrestadora = (o['logins']?['nome_empresa'] ?? UserSession.nomeEmpresa ?? '—').toString();

    final id = o['id']?.toString() ?? '—';
    final clienteNome = cliente?['nome'] ?? '—';
    final clienteEndereco = cliente?['rua'] ?? '—';
    final clienteNumero = cliente?['numero'] ?? '—';
    final clienteTel = cliente?['telefone'] ?? '—';
    final clienteEmail = cliente?['email'] ?? '—';

    final tipo = o['tipo_servico'] ?? '—';
    final desc = o['descricao'] ?? '—';
    final valor = (o['valor'] as num?)?.toDouble();
    final status = (o['status'] ?? 'Aberta').toString();
    final criado = _fmtDate(o['created_at']);
    final assinado = _fmtDate(o['assinado_em']);
    final concluido = _fmtDate(o['concluido_em']);
    final assinante = o['assinante_nome'] ?? '';
    final funcao = o['assinante_funcao'] ?? '';
    final assinatura = o['assinatura_base64'];

    pw.MemoryImage? assinaturaImg;
    if (assinatura != null && assinatura.isNotEmpty) {
      assinaturaImg = pw.MemoryImage(base64Decode(assinatura));
    }

    PdfColor corStatus;
    switch (status.toLowerCase()) {
      case 'assinada':
        corStatus = PdfColors.blue;
        break;
      case 'concluída':
      case 'concluido':
        corStatus = PdfColors.green;
        break;
      default:
        corStatus = PdfColors.red;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Gerado em ${_fmtDate(DateTime.now().toString())}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          // Cabeçalho
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    empresa,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Prestado por: $empresaPrestadora',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: corStatus, // fundo na cor do status
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  '$status | #$id',
                  style: pw.TextStyle(
                    color: PdfColors.white, // texto branco para contraste
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Bloco de informações do cliente
          pw.Text('Dados do Cliente',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nome: $clienteNome'),
                pw.Text('Endereço: $clienteEndereco, $clienteNumero'),
                pw.Text('Telefone: $clienteTel'),
                pw.Text('E-mail: $clienteEmail'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Bloco de informações da ordem
          pw.Text('Dados da Ordem',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Text('Serviço: $tipo'),
          pw.Text('Descrição: $desc'),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Valor: ${valor == null ? '—' : _currency.format(valor)}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Linha do Tempo',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColors.grey800)),
          pw.Bullet(text: 'Criada em: $criado'),
          pw.Bullet(text: 'Assinada em: $assinado'),
          pw.Bullet(text: 'Concluída em: $concluido'),

          if (assinaturaImg != null) ...[
            pw.SizedBox(height: 20),
            pw.Text('Assinatura:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Image(assinaturaImg, height: 80),
            pw.SizedBox(height: 8),
            pw.Container(height: 1, color: PdfColors.grey400),
            pw.Text('$assinante - $funcao',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return await doc.save();
  }

  Future<void> _abrir(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ordem_servico.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF da Ordem')),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final bytes = snap.data!;
          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (f) async => bytes,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar e Compartilhar'),
                  onPressed: () => _abrir(bytes),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
