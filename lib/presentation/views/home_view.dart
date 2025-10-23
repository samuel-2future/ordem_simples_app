import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordem Simples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HomeButton(
              label: 'Clientes',
              icon: Icons.people,
              onTap: () => Navigator.pushNamed(context, AppRoutes.clientes),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              label: 'Ordens de Serviço',
              icon: Icons.assignment,
              onTap: () => Navigator.pushNamed(context, AppRoutes.ordens),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              label: 'Nova Ordem',
              icon: Icons.add_circle,
              onTap: () => Navigator.pushNamed(context, AppRoutes.novaOrdem),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
