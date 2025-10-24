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
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

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
    if (!mounted) return;
    if (result == true) {
      await _loadOrdens(); // ✅ recarrega ao voltar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem criada com sucesso.')),
      );
    }
  }

  Future<void> _irParaDetalhe(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalheOrdemView(ordemId: id)),
    );
    if (!mounted) return;
    await _loadOrdens(); // ✅ recarrega sempre que voltar do detalhe
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
      case 'assinada':
        return Colors.blue;
      case 'concluída':
      case 'concluido':
      case 'concluida':
        return Colors.green;
      default: // Aberta ou outros
        return Colors.red;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assinada':
        return Icons.edit_document;
      case 'concluída':
      case 'concluido':
      case 'concluida':
        return Icons.check_circle_outline;
      default: // Aberta
        return Icons.warning_amber_rounded;
    }
  }

  String _fmtData(dynamic iso) {
    if (iso == null) return 'Sem data';
    try {
      return _dateFormat.format(DateTime.parse(iso.toString()).toLocal());
    } catch (_) {
      return 'Sem data';
    }
  }

  String _fmtValor(dynamic v) {
    if (v == null) return _currency.format(0);
    try {
      final num n = (v is num) ? v : num.parse(v.toString());
      return _currency.format(n);
    } catch (_) {
      return v.toString();
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
            final valorFmt = _fmtValor(o['valor']);
            final data = _fmtData(o['created_at']);

            final cor = _statusColor(status);
            final icone = _statusIcon(status);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cor.withOpacity(0.4)),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _irParaDetalhe(id), // ✅ aguarda e recarrega ao voltar
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // ícone do status
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icone, color: cor, size: 28),
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
                              style: TextStyle(color: Colors.grey.shade800),
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

                      // status + valor
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            valorFmt,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          IconButton(
                            tooltip: 'Excluir',
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () => _confirmExcluir(
                              context,
                              id: id,
                              tituloSnack: tipo.isEmpty ? 'Ordem $id' : tipo,
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
        label: const Text(
          'Nova Ordem',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
