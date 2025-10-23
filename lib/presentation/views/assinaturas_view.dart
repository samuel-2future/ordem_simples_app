import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class AssinaturasView extends StatelessWidget {
  const AssinaturasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assinaturas Salvas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined),
            title: Text('Assinatura #${index + 1}'),
            subtitle: const Text('Cliente Exemplo'),
            onTap: () {
              // Em breve: visualização
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.assinatura),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
