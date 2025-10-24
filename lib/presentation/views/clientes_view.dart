import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
          .eq('login_id', UserSession.loginId!)
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

  DateTime? _parseDate(Map<String, dynamic> c) {
    final raw = c['created_at'] ?? c['criado_em'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
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
    } else if (_clientes.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 200),
          Center(child: Text('Nenhum cliente cadastrado ainda.')),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _carregarClientes,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _clientes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = _clientes[index];
            final id = (c['id'] ?? '').toString();
            final nome = (c['nome'] ?? '').toString();
            final telefone = (c['telefone'] ?? '').toString();
            final email = (c['email'] ?? '').toString();
            final rua = (c['rua'] ?? '').toString();
            final numero = (c['numero'] ?? '').toString();
            final complemento = (c['complemento'] ?? '').toString();
            final cep = (c['cep'] ?? '').toString();
            final tipoRes = (c['tipo_residencia'] ?? '').toString();
            final data = _parseDate(c);
            final enderecoLine = [
              if (rua.isNotEmpty) rua,
              if (numero.isNotEmpty) 'nº $numero',
              if (complemento.isNotEmpty) complemento,
            ].join(', ');

            return _ClienteCard(
              id: id,
              nome: nome,
              telefone: telefone,
              email: email,
              endereco: enderecoLine,
              cep: cep,
              tipoResidencia: tipoRes,
              dataFormatada: data == null ? '—' : _dateFormat.format(data),
              onExcluir: () => _confirmExcluir(
                context,
                id: id,
                nome: nome.isEmpty ? 'Sem nome' : nome,
              ),
              onTap: () {
                // TODO: navegar para detalhe do cliente (se existir)
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToNovoCliente,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Cliente', style: TextStyle(color: Colors.white),),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final String id;
  final String nome;
  final String telefone;
  final String email;
  final String endereco;
  final String cep;
  final String tipoResidencia;
  final String dataFormatada;
  final VoidCallback onExcluir;
  final VoidCallback? onTap;

  const _ClienteCard({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.endereco,
    required this.cep,
    required this.tipoResidencia,
    required this.dataFormatada,
    required this.onExcluir,
    this.onTap,
    super.key,
  });

  String get _iniciais {
    if (nome.trim().isEmpty) return 'C';
    final parts = nome.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasTelefone = telefone.trim().isNotEmpty;
    final hasEmail = email.trim().isNotEmpty;
    final hasEndereco = endereco.trim().isNotEmpty || cep.trim().isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // avatar com iniciais
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _iniciais,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // linha 1 — nome + botão excluir
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nome.isEmpty ? 'Sem nome' : nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.shade400,
                          onPressed: onExcluir,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // linha 2 — telefone / email
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hasTelefone)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_iphone, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(telefone, style: TextStyle(color: Colors.grey.shade800)),
                            ],
                          ),
                        if (hasEmail)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alternate_email, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(email, style: TextStyle(color: Colors.grey.shade800)),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // linha 3 — endereço
                    if (hasEndereco)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if (endereco.isNotEmpty) endereco,
                                if (cep.isNotEmpty) ' • CEP $cep',
                              ].join(''),
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // linha 4 — chip + data
                    Row(
                      children: [
                        if (tipoResidencia.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              tipoResidencia,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              dataFormatada,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
