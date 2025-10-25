// empresa_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/empresa_model.dart';

class EmpresaService {
  EmpresaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'empresa';

  // Colunas explicitadas (melhor para tipagem e segurança)
  static const _cols =
      'id, nome_empresa, nome_responsavel, cnpj, endereco, estado, created_at, updated_at, telefone';

  // ===== READ =====

  Future<List<EmpresaModel>> buscarTodos({
    int limit = 50,
    int offset = 0,
    String? search,
    String? estado,
    String orderBy = 'created_at',
    bool descending = true,
  }) async {
    try {
      var query = _client.from(_table).select(_cols);

      if (search != null && search.trim().isNotEmpty) {
        query = query.or(
          'nome_empresa.ilike.%$search%,nome_responsavel.ilike.%$search%',
        );
      }

      if (estado != null && estado.trim().isNotEmpty) {
        query = query.eq('estado', estado.toUpperCase());
      }

      final data = await query
          .order(orderBy, ascending: !descending)
          .range(offset, offset + limit - 1);

      return (data as List)
          .map((e) => EmpresaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar empresas: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar empresas: $e');
    }
  }

  Future<EmpresaModel?> buscarPorId(String id) async {
    try {
      final data = await _client
          .from(_table)
          .select(_cols)
          .eq('id', id)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return EmpresaModel.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar empresa por ID: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar empresa por ID: $e');
    }
  }

  /// Aceita `id` nulo e retorna `null` sem lançar exceção.
  Future<EmpresaModel?> buscarPorIdOrNull(String? id) async {
    if (id == null || id.isEmpty) return null;
    return buscarPorId(id);
  }

  /// Busca em lote por IDs.
  Future<List<EmpresaModel>> buscarPorIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final data = await _client
          .from(_table)
          .select(_cols)
          .inFilter('id', ids); // <- use inFilter aqui

      return (data as List)
          .map((e) => EmpresaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar empresas por IDs: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar empresas por IDs: $e');
    }
  }


  // ===== CREATE =====

  Future<EmpresaModel> cadastrar(EmpresaCreate input) async {
    try {
      final inserted = await _client
          .from(_table)
          .insert(input.toInsertMap())
          .select(_cols)
          .single();

      return EmpresaModel.fromMap(inserted as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao cadastrar empresa: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao cadastrar empresa: $e');
    }
  }

  // ===== UPDATE =====

  Future<EmpresaModel> atualizar(String id, EmpresaUpdate input) async {
    try {
      final map = input.toUpdateMap();
      if (map.isEmpty) {
        throw Exception('Nada para atualizar.');
      }

      final updated = await _client
          .from(_table)
          .update(map)
          .eq('id', id)
          .select(_cols)
          .single();

      return EmpresaModel.fromMap(updated as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar empresa: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar empresa: $e');
    }
  }

  // ===== DELETE =====

  Future<void> deletar(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao deletar empresa: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao deletar empresa: $e');
    }
  }
}

// ========== DTOs tipados para inserção/atualização ==========

class EmpresaCreate {
  final String nomeEmpresa;
  final String nomeResponsavel;
  final String cnpj;   // pode vir com máscara; será normalizado
  final String endereco;
  final String estado; // UF

  EmpresaCreate({
    required this.nomeEmpresa,
    required this.nomeResponsavel,
    required this.cnpj,
    required this.endereco,
    required this.estado,
  });

  Map<String, dynamic> toInsertMap() => {
    'nome_empresa': nomeEmpresa,
    'nome_responsavel': nomeResponsavel,
    'cnpj': _digitsOnly(cnpj),
    'endereco': endereco,
    'estado': estado.toUpperCase(),
  };

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}

class EmpresaUpdate {
  String? nomeEmpresa;
  String? nomeResponsavel;
  String? cnpj;    // será normalizado se fornecido
  String? endereco;
  String? estado;  // UF

  EmpresaUpdate({
    this.nomeEmpresa,
    this.nomeResponsavel,
    this.cnpj,
    this.endereco,
    this.estado,
  });

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (_hasValue(nomeEmpresa)) map['nome_empresa'] = nomeEmpresa;
    if (_hasValue(nomeResponsavel)) map['nome_responsavel'] = nomeResponsavel;
    if (_hasValue(cnpj)) map['cnpj'] = _digitsOnly(cnpj!);
    if (_hasValue(endereco)) map['endereco'] = endereco;
    if (_hasValue(estado)) map['estado'] = estado!.toUpperCase();
    return map;
  }

  static bool _hasValue(String? v) => v != null && v.trim().isNotEmpty;

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}
