class UserSession {
  static int? loginId;
  static String? email;
  static String? nomeCompleto;
  static String? nomeEmpresa;

  static void fromMap(Map<String, dynamic> user) {
    loginId      = (user['id'] as num).toInt();
    email        = user['email'] as String?;
    nomeCompleto = user['nome_completo'] as String?;
    nomeEmpresa  = user['nome_empresa'] as String?;
  }

  static void clear() {
    loginId = null;
    email = null;
    nomeCompleto = null;
    nomeEmpresa = null;
  }
}
