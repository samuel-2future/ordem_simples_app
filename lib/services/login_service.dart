import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final _db = Supabase.instance.client;

  Future<Map<String, dynamic>?> autenticar({
    required String email,
    required String senha,
  }) async {
    final result = await _db.rpc(
      'login_user',
      params: {'p_email': email, 'p_senha': senha},
    );

    if (result == null) return null;
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }
    return null;
  }
}
