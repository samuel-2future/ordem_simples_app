import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> gerarPdfSimples() async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Ordem de Serviço',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Cliente: João da Silva'),
            pw.Text('Serviço: Troca de disjuntor'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Valor: R\$ 350,00',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/ordem_servico.pdf');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
}
