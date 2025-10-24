import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/routes/app_routes.dart';
import '../../core/user_session.dart';
import '../../services/ordem_service.dart';
import 'detalhe_ordem_view.dart';

class OrdensView extends StatefulWidget {
  const OrdensView({super.key});

  @override
  State<OrdensView> createState() => _OrdensViewState();
}

class _OrdensViewState extends State<OrdensView> {
  final _svc = OrdemService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
      if (UserSession.loginId == null) {
        throw Exception('Sessão inválida. Faça login novamente.');
      }

      debugPrint('🔹 Carregando ordens do login_id: ${UserSession.loginId}');
      final data = await _svc.listarOrdensDoLogin(UserSession.loginId!);

      setState(() {
        _ordens = data;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao carregar ordens: $e\n$s');
      setState(() {
        _error = 'Erro ao carregar ordens: $e';
        _loading = false;
      });
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
      await _svc.excluirOrdem(
        loginId: UserSession.loginId!,
        ordemId: id,
      );

      if (!mounted) return;
      setState(() {
        _ordens.removeWhere((o) => o['id'].toString() == id);
      });
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assinado':
        return Colors.blue;
      case 'concluído':
      case 'concluida':
      case 'concluída':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assinado':
        return Icons.edit_document;
      case 'concluído':
      case 'concluida':
      case 'concluída':
        return Icons.check_circle_outline;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    } else if (_ordens.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nenhuma ordem cadastrada ainda.')),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadOrdens,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ordens.length,
          itemBuilder: (context, index) {
            final o = _ordens[index];
            final id = o['id'].toString();
            final clienteNome = (o['clientes']?['nome'] ?? 'Cliente não informado').toString();
            final tipo = (o['tipo_servico'] ?? '—').toString();
            final status = (o['status'] ?? 'Aberta').toString();
            final valor = (o['valor'] ?? 0).toString();
            final data = o['created_at'] != null
                ? _dateFormat.format(DateTime.parse(o['created_at']))
                : 'Sem data';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _statusColor(status).withOpacity(0.4)),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetalheOrdemView(ordemId: id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // ícone do status
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // conteúdo do card
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              clienteNome,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  data,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'R\$ ${valor.toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToNovaOrdem,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Ordem', style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
