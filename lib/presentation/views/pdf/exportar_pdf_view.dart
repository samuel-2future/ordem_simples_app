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

class ExportarPdfView extends StatefulWidget {
  final Map<String, dynamic> ordem;
  const ExportarPdfView({super.key, required this.ordem});

  @override
  State<ExportarPdfView> createState() => _ExportarPdfViewState();
}

class _ExportarPdfViewState extends State<ExportarPdfView> {
  late Future<Uint8List> _pdfFuture;
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    _pdfFuture = _gerarPdf();
  }

  Future<Uint8List> _gerarPdf() async {
    final ordem = widget.ordem;
    final cliente = ordem['clientes'] ?? {};
    final doc = pw.Document();

    // Dados
    final clienteNome = cliente['nome'] ?? '—';
    final tipoServico = ordem['tipo_servico'] ?? '—';
    final descricao = ordem['descricao'] ?? '—';
    final status = ordem['status'] ?? '—';
    final valor = (ordem['valor'] as num?)?.toDouble();
    final assinaturaBase64 = ordem['assinatura_base64'] as String?;

    pw.MemoryImage? assinaturaImg;
    if (assinaturaBase64 != null && assinaturaBase64.isNotEmpty) {
      assinaturaImg = pw.MemoryImage(base64Decode(assinaturaBase64));
    }

    final dataAtual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Ordem de Serviço',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text('Cliente: $clienteNome', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Serviço: $tipoServico'),
            pw.Text('Descrição: $descricao'),
            pw.Text('Status: $status'),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Valor: ${valor == null ? '—' : _currency.format(valor)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),

            if (assinaturaImg != null) ...[
              pw.Text('Assinatura:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Image(assinaturaImg, height: 80),
            ],

            pw.Spacer(),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Gerado em $dataAtual',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ),
          ],
        ),
      ),
    );

    return await doc.save();
  }

  Future<void> _baixarEPdf(Uint8List bytes) async {
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao gerar PDF: ${snapshot.error}'));
          }

          final pdfBytes = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (format) async => pdfBytes,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _baixarEPdf(pdfBytes),
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar e Compartilhar'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
