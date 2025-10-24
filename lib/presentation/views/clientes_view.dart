import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/routes/app_routes.dart';
import '../../core/user_session.dart';
import '../../services/cliente_service.dart';

class ClientesView extends StatefulWidget {
  const ClientesView({super.key});

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  final _db = Supabase.instance.client;
  final _svc = ClienteService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (UserSession.loginId == null) {
        throw Exception('Sessão inválida. Faça login novamente.');
      }

      debugPrint('🔹 Carregando clientes do login_id: ${UserSession.loginId}');
      final clientes = await _svc.listarClientesDoLogin(UserSession.loginId!);

      setState(() {
        _clientes = clientes;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao carregar clientes: $e\n$s');
      setState(() {
        _error = 'Erro ao carregar clientes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _goToNovoCliente() async {
    final result = await Navigator.pushNamed(context, AppRoutes.novoCliente);
    if (result == true && mounted) {
      await _carregarClientes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente cadastrado com sucesso.')),
      );
    }
  }

  Future<void> _excluirCliente(String id, String nome) async {
    try {
      final deleted = await _db
          .from('clientes')
          .delete()
          .eq('id', id)
          .eq('login_id', UserSession.loginId!) // 🔒 exclui só se for meu
          .select('id')
          .maybeSingle();

      if (!mounted) return;

      if (deleted == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir "$nome".')),
        );
        return;
      }

      setState(() {
        _clientes.removeWhere((c) => c['id'].toString() == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente "$nome" excluído.')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no banco: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir "$nome": $e')),
      );
    }
  }

  void _confirmExcluir(BuildContext context, {required String id, required String nome}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Tem certeza que deseja excluir "$nome"?'),
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
              await _excluirCliente(id, nome);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
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
    } else if (_clientes.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 200),
          Center(child: Text('Nenhum cliente cadastrado ainda.')),
        ],
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clientes.length,
        itemBuilder: (context, index) {
          final c = _clientes[index];
          final id = (c['id'] ?? '').toString();
          final nome = (c['nome'] ?? '').toString();
          final tel = (c['telefone'] ?? '').toString();

          return Card(
            child: ListTile(
              title: Text(nome.isEmpty ? 'Sem nome' : nome),
              subtitle: Text(tel.isEmpty ? 'Telefone: —' : 'Telefone: $tel'),
              trailing: IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                onPressed: () => _confirmExcluir(
                  context,
                  id: id,
                  nome: nome.isEmpty ? 'Sem nome' : nome,
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: RefreshIndicator(onRefresh: _carregarClientes, child: body),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNovoCliente,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
