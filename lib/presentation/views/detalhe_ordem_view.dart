import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class DetalheOrdemView extends StatelessWidget {
  const DetalheOrdemView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Ordem')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cliente: João da Silva', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Descrição: Troca de disjuntor e revisão elétrica'),
            const SizedBox(height: 8),
            const Text('Valor: R\$ 350,00'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.assinaturas),
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Assinar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
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
