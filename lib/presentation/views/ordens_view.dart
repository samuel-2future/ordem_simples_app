import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';
import '../../services/ordem_service.dart';

class OrdensView extends StatefulWidget {
  const OrdensView({super.key});

  @override
  State<OrdensView> createState() => _OrdensViewState();
}

class _OrdensViewState extends State<OrdensView> {
  final _svc = OrdemService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _ordens = [];

  @override
  void initState() {
    super.initState();
    _loadOrdens();
  }

  Future<void> _loadOrdens() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _svc.listarOrdens();
      setState(() => _ordens = data);
    } catch (e) {
      setState(() => _error = 'Falha ao carregar ordens: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToNovaOrdem() async {
    final result = await Navigator.pushNamed(context, AppRoutes.novaOrdem);
    if (result == true && mounted) {
      await _loadOrdens();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem criada com sucesso.')),
      );
    }
  }

  Future<void> _excluirOrdem(String id, String tituloSnack) async {
    try {
      await _svc.excluirOrdem(id);
      if (!mounted) return;
      setState(() => _ordens.removeWhere((o) => o['id'].toString() == id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ordem "$tituloSnack" excluída.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir "$tituloSnack": $e')),
      );
    }
  }

  void _confirmExcluir(BuildContext context, {required String id, required String tituloSnack}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ordem de serviço'),
        content: Text('Tem certeza que deseja excluir a ordem "$tituloSnack"?'),
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
            onPressed: () async {
              Navigator.pop(context);
              await _excluirOrdem(id, tituloSnack);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final theme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'concluída':
      case 'concluida':
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green.shade800;
        break;
      case 'em andamento':
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange.shade800;
        break;
      case 'cancelada':
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red.shade800;
        break;
      default: // Aberta
        bg = theme.primary.withOpacity(0.12);
        fg = theme.primary;
    }
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadOrdens,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    } else if (_ordens.isEmpty) {
      // Para o RefreshIndicator funcionar no estado vazio
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nenhuma ordem cadastrada ainda.')),
        ],
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ordens.length,
        itemBuilder: (context, index) {
          final o = _ordens[index];
          final id = o['id'].toString(); // pode ser int (bigserial) ou uuid -> toString()
          final clienteNome = (o['clientes']?['nome'] ?? 'Cliente').toString();
          final status = (o['status'] ?? 'Aberta').toString();
          final tipo = (o['tipo_servico'] ?? '').toString();

          return Card(
            child: ListTile(
              title: Text(tipo.isEmpty ? 'Ordem $id' : tipo),
              subtitle: Text(clienteNome),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusChip(context, status),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    onPressed: () => _confirmExcluir(context, id: id, tituloSnack: tipo.isEmpty ? 'Ordem $id' : tipo),
                  ),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.detalheOrdem, arguments: id),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      body: RefreshIndicator(
        onRefresh: _loadOrdens,
        child: body,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNovaOrdem,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
