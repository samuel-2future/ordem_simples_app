import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';

class AssinaturaView extends StatefulWidget {
  const AssinaturaView({super.key});

  @override
  State<AssinaturaView> createState() => _AssinaturaViewState();
}

class _AssinaturaViewState extends State<AssinaturaView> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    // Forçar orientação horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Voltar para orientação normal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvarAssinatura(BuildContext context) async {
    if (_controller.isNotEmpty) {
      final Uint8List? data = await _controller.toPngBytes();
      if (data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assinatura salva com sucesso!')),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assinatura vazia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Assinatura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar',
            onPressed: () => _controller.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Salvar',
            onPressed: () => _salvarAssinatura(context),
          ),
        ],
      ),
      body: Signature(
        controller: _controller,
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}
