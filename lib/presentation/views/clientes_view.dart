import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class ClientesView extends StatelessWidget {
  const ClientesView({super.key});

  void _confirmExcluir(BuildContext context, String nomeCliente) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Tem certeza que deseja excluir "$nomeCliente"?'),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cliente "$nomeCliente" excluído.')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final nomeCliente = 'Cliente ${index + 1}';
          return Card(
            child: ListTile(
              title: Text(nomeCliente),
              subtitle: const Text('Telefone: (11) 99999-9999'),
              trailing: IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                onPressed: () => _confirmExcluir(context, nomeCliente),
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.novoCliente),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
