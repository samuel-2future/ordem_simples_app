class EmpresaModel {
  final String id;
  final String nomeEmpresa;
  final String nomeResponsavel;
  final String cnpj;
  final String endereco;
  final String estado;
  final String? telefone;      // <- novo
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmpresaModel({
    required this.id,
    required this.nomeEmpresa,
    required this.nomeResponsavel,
    required this.cnpj,
    required this.endereco,
    required this.estado,
    this.telefone,             // <- novo
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmpresaModel.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic v) =>
        v is DateTime ? v.toUtc() : DateTime.parse(v as String).toUtc();

    return EmpresaModel(
      id: map['id'] as String,
      nomeEmpresa: map['nome_empresa'] as String,
      nomeResponsavel: map['nome_responsavel'] as String,
      cnpj: (map['cnpj'] as String).replaceAll(RegExp(r'[^0-9]'), ''),
      endereco: map['endereco'] as String,
      estado: (map['estado'] as String).toUpperCase(),
      telefone: map['telefone'] as String?,                // <- novo
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome_empresa': nomeEmpresa,
    'nome_responsavel': nomeResponsavel,
    'cnpj': cnpj,
    'endereco': endereco,
    'estado': estado,
    'telefone': telefone,                              // <- novo
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  EmpresaModel copyWith({
    String? id,
    String? nomeEmpresa,
    String? nomeResponsavel,
    String? cnpj,
    String? endereco,
    String? estado,
    String? telefone,                                      // <- novo
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmpresaModel(
      id: id ?? this.id,
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      cnpj: cnpj ?? this.cnpj,
      endereco: endereco ?? this.endereco,
      estado: estado?.toUpperCase() ?? this.estado,
      telefone: telefone ?? this.telefone,                 // <- novo
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
