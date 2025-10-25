// user_session.dart
import '../../model/login_model.dart';

class UserSession {
  static int? loginId;
  static String? email;
  static String? nomeCompleto;
  static String? nomeEmpresa;
  static String? empresaId;

  static void fromLoginModel(LoginModel user) {
    loginId      = user.id;
    email        = user.email;
    nomeCompleto = user.nomeCompleto;
    nomeEmpresa  = user.empresa?.nomeEmpresa; // vem do objeto
    empresaId    = user.empresaId;
  }

  static void clear() {
    loginId = null;
    email = null;
    nomeCompleto = null;
    nomeEmpresa = null;
    empresaId = null;
  }
}
