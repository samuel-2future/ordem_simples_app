import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class OrdensView extends StatelessWidget {
  const OrdensView({super.key});

  void _confirmExcluir(BuildContext context, String ordemId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ordem de serviço'),
        content: Text('Tem certeza que deseja excluir a ordem "$ordemId"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // fecha o modal
              // Apenas UI: feedback visual
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ordem "$ordemId" excluída.')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final textColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(status, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          final ordemId = 'Ordem #00${index + 1}';
          return Card(
            child: ListTile(
              title: Text(ordemId),
              subtitle: const Text('Cliente Exemplo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusChip(context, 'Aberta'),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    onPressed: () => _confirmExcluir(context, ordemId),
                  ),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.detalheOrdem),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.novaOrdem),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
