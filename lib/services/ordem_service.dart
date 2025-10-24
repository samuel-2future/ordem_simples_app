import 'package:supabase_flutter/supabase_flutter.dart';

class OrdemService {
  final _db = Supabase.instance.client;

  Future<Map<String, dynamic>> criarOrdem({
    required int loginId,
    required String clienteId,
    required String tipoServico,
    String? descricao,
    double? valor,
    String status = 'Aberta',
  }) async {
    final data = await _db
        .from('ordens_servico')
        .insert({
      'login_id': loginId,
      'cliente_id': clienteId,
      'tipo_servico': tipoServico,
      'descricao': descricao,
      'valor': valor,
      'status': status,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listarOrdens() async {
    final data = await _db
        .from('ordens_servico')
        .select(
      'id, tipo_servico, descricao, valor, status, created_at, clientes(nome)',
    )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> excluirOrdem({
    required int loginId,
    required String ordemId,
  }) async {
    await Supabase.instance.client
        .from('ordens_servico')
        .delete()
        .eq('id', ordemId)
        .eq('login_id', loginId);
  }

  Future<Map<String, dynamic>?> obterOrdemPorId({
    required int loginId,
    required String ordemId,
  }) async {
    final data = await _db
        .from('ordens_servico')
        .select('''
          id,
          login_id,
          cliente_id,
          tipo_servico,
          descricao,
          valor,
          status,
          created_at,
          updated_at,
          clientes:clientes(id, nome, telefone, email)
        ''')
        .eq('id', ordemId)
        .eq('login_id', loginId)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> atualizarOrdem({
    required int loginId,
    required String ordemId,
    String? tipoServico,
    String? descricao,
    double? valor,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      if (tipoServico != null) 'tipo_servico': tipoServico,
      if (descricao != null) 'descricao': descricao,
      if (valor != null) 'valor': valor,
      if (status != null) 'status': status,
    };

    final data = await _db
        .from('ordens_servico')
        .update(payload)
        .eq('id', ordemId)
        .eq('login_id', loginId)
        .select()
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listarOrdensDoLogin(int loginId) async {
    final data = await _db
        .from('ordens_servico')
        .select('''
        id,
        tipo_servico,
        descricao,
        valor,
        status,
        created_at,
        clientes (nome)
      ''')
        .eq('login_id', loginId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
