import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/routes/app_routes.dart';
import '../../core/user_session.dart';
import '../../services/ordem_service.dart';

class DetalheOrdemView extends StatelessWidget {
  final String ordemId;
  DetalheOrdemView({super.key, required this.ordemId});

  final _service = OrdemService();
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Ordem')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _service.obterOrdemPorId(
          loginId: UserSession.loginId!,
          ordemId: ordemId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ocorreu um erro ao carregar a ordem.\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final ordem = snapshot.data;
          if (ordem == null) {
            return const Center(child: Text('Ordem não encontrada.'));
          }

          final cliente = ordem['clientes'] as Map<String, dynamic>?;
          final valor = (ordem['valor'] as num?)?.toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  'Cliente: ${cliente?['nome'] ?? '—'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Serviço: ${ordem['tipo_servico'] ?? '—'}'),
                const SizedBox(height: 8),
                Text('Descrição: ${ordem['descricao'] ?? '—'}'),
                const SizedBox(height: 8),
                Text('Status: ${ordem['status'] ?? '—'}'),
                const SizedBox(height: 8),
                Text('Valor: ${valor == null ? '—' : _currency.format(valor)}'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.assinaturas,
                        arguments: ordemId,
                      ),
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
          );
        },
      ),
    );
  }
}
