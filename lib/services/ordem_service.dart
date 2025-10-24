import 'dart:convert';
import 'dart:typed_data';
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

  Future<Map<String, dynamic>?> obterOrdemPorId({
    required int loginId,
    required String ordemId,
  }) async {
// OrdemService.obterOrdemPorId
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
      assinatura_base64,
      assinante_nome,
      assinante_funcao,
      assinado_em,
      concluido_em,
      created_at,
      updated_at,
      clientes:clientes(
        id, nome, telefone, email, rua, numero, complemento
      )
    ''')
        .eq('id', ordemId)
        .eq('login_id', loginId)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }



  Future<void> excluirOrdem({
    required int loginId,
    required String ordemId,
  }) async {
    await _db
        .from('ordens_servico')
        .delete()
        .eq('id', ordemId)
        .eq('login_id', loginId);
  }

  /// Assina a OS e marca status = 'Assinada'
  Future<Map<String, dynamic>> atualizarStatusAssinado({
    required int loginId,
    required String ordemId,
    required List<int> assinatura,
  }) async {
    final base64Ass = base64Encode(assinatura);
    final data = await _db
        .from('ordens_servico')
        .update({
      'status': 'Assinada',
      'assinatura_base64': base64Ass,
      'assinado_em': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', ordemId)
        .eq('login_id', loginId)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> concluirOrdem({
    required int loginId,
    required String ordemId,
    required String assinanteNome,
    required String assinanteFuncao,
  }) async {
    final agora = DateTime.now().toIso8601String();

    final data = await _db
        .from('ordens_servico')
        .update({
      'status': 'Concluída',
      'assinante_nome': assinanteNome,
      'assinante_funcao': assinanteFuncao,
      'concluido_em': agora,
      'updated_at': agora,
    })
        .eq('id', ordemId)
        .eq('login_id', loginId)
        .select()
        .single();

    return Map<String, dynamic>.from(data);
  }

}
