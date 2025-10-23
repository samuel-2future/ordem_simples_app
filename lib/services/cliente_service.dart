import 'package:supabase_flutter/supabase_flutter.dart';

class ClienteService {
  final _db = Supabase.instance.client;

  // 🔹 Criar cliente
  Future<Map<String, dynamic>> criarCliente({
    required String nome,
    String? telefone,
    String? email,
    String? endereco,
    String? cep,
    String? numero,
    String? complemento,
  }) async {
    final rows = await _db
        .from('clientes')
        .insert({
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'cep': cep,
      'numero': numero,
      'complemento': complemento,
    })
        .select()
        .limit(1);

    return rows.first as Map<String, dynamic>;
  }

  // 🔹 Listar todos os clientes
  Future<List<Map<String, dynamic>>> listarClientes() async {
    final data = await _db
        .from('clientes')
        .select('id, nome, telefone, email, endereco, cep, numero, complemento')
        .order('nome', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }
}
