import 'package:supabase_flutter/supabase_flutter.dart';

class OrdemService {
  final _db = Supabase.instance.client;

  // 🔹 INSERT
  Future<Map<String, dynamic>> criarOrdem({
    required String clienteId,
    required String tipoServico,
    String? descricao,
    double? valor,
  }) async {
    final data = await _db.from('ordens_servico').insert({
      'cliente_id': clienteId,
      'tipo_servico': tipoServico,
      'descricao': descricao,
      'valor': valor,
      'status': 'Aberta',
    }).select().limit(1);

    return data.first as Map<String, dynamic>;
  }

  // 🔹 GET ALL
  Future<List<Map<String, dynamic>>> listarOrdens() async {
    final data = await _db
        .from('ordens_servico')
        .select(
      'id, tipo_servico, descricao, valor, status, created_at, clientes(nome)',
    )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // 🔹 DELETE
  Future<void> excluirOrdem(String id) async {
    await _db.from('ordens_servico').delete().eq('id', id);
  }
}
