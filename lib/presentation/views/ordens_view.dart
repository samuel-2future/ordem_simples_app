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
  List<Map<String, dynamic>> _ordensFiltradas = [];

  // 🔎 Filtros
  DateTime? _dataSelecionada;
  String? _statusSelecionado; // Aberta | Assinada | Concluída | Todas

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

      // ✅ Sempre reaplica os filtros após buscar do banco
      _aplicarFiltros();
    } catch (e, s) {
      debugPrint('❌ Erro ao carregar ordens: $e\n$s');
      setState(() {
        _error = 'Erro ao carregar ordens: $e';
        _loading = false;
      });
    }
  }

  DateTime? _parseCreatedAt(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _normStatus(String? s) {
    final v = (s ?? '').toLowerCase().trim();
    if (v.startsWith('conclu')) return 'concluída';
    if (v.startsWith('assina')) return 'assinada';
    return 'aberta';
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> filtradas = List.from(_ordens);

    // Filtro de data
    if (_dataSelecionada != null) {
      filtradas = filtradas.where((o) {
        final d = _parseCreatedAt(o['created_at']);
        if (d == null) return false;
        return DateUtils.isSameDay(d, _dataSelecionada);
      }).toList();
    }

    // Filtro de status (exceto "Todas")
    if (_statusSelecionado != null &&
        _statusSelecionado!.isNotEmpty &&
        _statusSelecionado != 'Todas') {
      final alvo = _normStatus(_statusSelecionado);
      filtradas = filtradas.where((o) {
        final status = _normStatus(o['status']?.toString());
        return status == alvo;
      }).toList();
    }

    setState(() => _ordensFiltradas = filtradas);
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? hoje,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoje.year + 1),
      locale: const Locale('pt', 'BR'),
    );
    if (selecionada != null) {
      setState(() => _dataSelecionada = selecionada);
      _aplicarFiltros();
    }
  }

  void _limparData() {
    if (_dataSelecionada == null) return;
    setState(() => _dataSelecionada = null);
    _aplicarFiltros();
  }

  void _limparFiltros() {
    setState(() {
      _dataSelecionada = null;
      _statusSelecionado = 'Todas';
    });
    _aplicarFiltros();
  }

  Future<void> _irParaDetalhe(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalheOrdemView(ordemId: id)),
    );
    if (!mounted) return;
    await _loadOrdens();
  }

  Future<void> _goToNovaOrdem() async {
    final result = await Navigator.pushNamed(context, AppRoutes.novaOrdem);
    if (!mounted) return;
    if (result == true) {
      await _loadOrdens();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem criada com sucesso.')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (_normStatus(status)) {
      case 'assinada':
        return Colors.blue;
      case 'concluída':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  IconData _statusIcon(String status) {
    switch (_normStatus(status)) {
      case 'assinada':
        return Icons.edit_document;
      case 'concluída':
        return Icons.check_circle_outline;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _fmtData(dynamic iso) {
    final d = _parseCreatedAt(iso);
    if (d == null) return 'Sem data';
    return _dateFormat.format(d);
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
    Widget listContent;
    if (_loading) {
      listContent = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      listContent = Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, textAlign: TextAlign.center),
          ));
    } else if (_ordensFiltradas.isEmpty) {
      listContent = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nenhuma ordem encontrada.')),
        ],
      );
    } else {
      listContent = RefreshIndicator(
        onRefresh: _loadOrdens,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ordensFiltradas.length,
          itemBuilder: (context, index) {
            final o = _ordensFiltradas[index];
            final id = o['id'].toString();
            final clienteNome =
            (o['clientes']?['nome'] ?? 'Cliente não informado').toString();
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
                onTap: () => _irParaDetalhe(id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icone, color: cor, size: 28),
                      ),
                      const SizedBox(width: 16),
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
                                Icon(Icons.calendar_month,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _normStatus(status)[0].toUpperCase() +
                                _normStatus(status).substring(1),
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

    final dataLabel = _dataSelecionada == null
        ? 'Filtrar por data'
        : DateFormat('dd/MM/yyyy').format(_dataSelecionada!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(
            tooltip: 'Limpar filtros',
            onPressed: _limparFiltros,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎯 Barra de Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Filtro de Data
                Expanded(
                  child: InkWell(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dataLabel,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_dataSelecionada != null)
                            InkWell(
                              onTap: _limparData,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filtro de Status (agora com "Todas")
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusSelecionado ?? 'Todas',
                    hint: const Text('Status'),
                    items: const [
                      DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                      DropdownMenuItem(value: 'Aberta', child: Text('Aberta')),
                      DropdownMenuItem(value: 'Assinada', child: Text('Assinada')),
                      DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusSelecionado = v);
                      _aplicarFiltros();
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(child: listContent),
        ],
      ),
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
