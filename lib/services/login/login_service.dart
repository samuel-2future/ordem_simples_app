import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/login_model.dart';

class LoginService {
  LoginService({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;
  final SupabaseClient _db;

  Future<LoginModel?> autenticarTyped({
    required String email,
    required String senha,
  }) async {
    try {
      final data = await _db
          .from('logins')
          .select('''
            id, email, senha, nome_completo, criado_em, atualizado_em, empresa_id,
            empresa:empresa_id (*)
          ''')
          .eq('email', email)
          .eq('senha', senha)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return LoginModel.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao autenticar: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao autenticar: $e');
    }
  }
}
