import 'package:flutter/material.dart';

class NovoClienteView extends StatelessWidget {
  const NovoClienteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField('Nome'),
            const SizedBox(height: 12),
            _buildField('Telefone'),
            const SizedBox(height: 12),
            _buildField('Email'),
            const SizedBox(height: 12),
            _buildField('Endereço'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label) {
    return TextField(
      decoration: InputDecoration(labelText: label),
    );
  }
}
