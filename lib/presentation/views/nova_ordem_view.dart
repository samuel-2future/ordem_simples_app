import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class NovaOrdemView extends StatelessWidget {
  const NovaOrdemView({super.key});

  @override
  Widget build(BuildContext context) {
    final clientes = ['Cliente A', 'Cliente B', 'Cliente C'];

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: clientes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Descrição do Trabalho'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Valor do Trabalho (R\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.detalheOrdem),
                child: const Text('Gerar Ordem'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
