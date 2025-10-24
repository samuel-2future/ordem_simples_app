import 'package:supabase_flutter/supabase_flutter.dart';

class ClienteService {
  final _db = Supabase.instance.client;

  Future<Map<String, dynamic>> criarCliente({
    required int loginId,
    required String nome,
    String? telefone,
    String? email,
    String? cep,
    String? rua,
    String? numero,
    String? tipoResidencia,
    String? complemento,
  }) async {
    final payload = {
      'login_id': loginId,
      'nome': nome,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (cep != null && cep.isNotEmpty) 'cep': cep,
      if (rua != null && rua.isNotEmpty) 'rua': rua,
      if (numero != null && numero.isNotEmpty) 'numero': numero,
      if (tipoResidencia != null && tipoResidencia.isNotEmpty) 'tipo_residencia': tipoResidencia,
      if (complemento != null && complemento.isNotEmpty) 'complemento': complemento,
    };

    final data = await _db.from('clientes').insert(payload).select().single();
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listarClientesDoLogin(int loginId) async {
    final data = await _db
        .from('clientes')
        .select('id, nome, telefone, email, endereco, created_at')
        .eq('login_id', loginId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> buscarPorNome({
    required int loginId,
    required String termo,
  }) async {
    final data = await _db
        .from('clientes')
        .select('id, nome, telefone, email, endereco, created_at')
        .eq('login_id', loginId)
        .ilike('nome', '%$termo%')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
