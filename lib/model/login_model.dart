// login_model.dart
import 'dart:convert';
import 'empresa_model.dart';

class LoginModel {
  final int id;
  final String email;
  final String senha;
  final String? nomeCompleto;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? empresaId;
  final EmpresaModel? empresa; // <- objeto tipado

  const LoginModel({
    required this.id,
    required this.email,
    required this.senha,
    required this.nomeCompleto,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.empresaId,
    this.empresa,
  });

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v.toUtc();
    if (v is String) return DateTime.parse(v).toUtc();
    throw ArgumentError('Data inválida: $v');
  }

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    final empresaMap = map['empresa'] as Map<String, dynamic>?;
    return LoginModel(
      id: (map['id'] as num).toInt(),
      email: map['email'] as String,
      senha: map['senha'] as String,
      nomeCompleto: map['nome_completo'] as String?,
      criadoEm: _parseDate(map['criado_em']),
      atualizadoEm: _parseDate(map['atualizado_em']),
      empresaId: map['empresa_id'] as String?,
      empresa: empresaMap != null ? EmpresaModel.fromMap(empresaMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'senha': senha,
      'nome_completo': nomeCompleto,
      'criado_em': criadoEm.toUtc().toIso8601String(),
      'atualizado_em': atualizadoEm.toUtc().toIso8601String(),
      'empresa_id': empresaId,
      // opcional: persistir alguns campos úteis da empresa na sessão
      'empresa': empresa?.toMap(),
    };
  }

  factory LoginModel.fromJson(String source) =>
      LoginModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  LoginModel copyWith({
    int? id,
    String? email,
    String? senha,
    String? nomeCompleto,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? empresaId,
    EmpresaModel? empresa,
  }) {
    return LoginModel(
      id: id ?? this.id,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      empresaId: empresaId ?? this.empresaId,
      empresa: empresa ?? this.empresa,
    );
  }
}
