import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'catalogo_racas.dart';

abstract class RacasCache {
  Future<CatalogoRacas?> ler();
  Future<void> salvar(CatalogoRacas catalogo);
  Future<void> fechar();
}

// Arquivo próprio: não modifica o cache da API nem os bancos anteriores.
class RacasCacheSqlite implements RacasCache {
  final String? diretorio;
  Future<Database>? _abertura;

  RacasCacheSqlite({this.diretorio});

  Future<Database> get _database => _abertura ??= _abrir();

  Future<Database> _abrir() async => openDatabase(
    path.join(
      diretorio ?? await getDatabasesPath(),
      'banho_tosa_racas_cache.db',
    ),
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE catalogo ('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'nomes TEXT NOT NULL, atualizado_em TEXT NOT NULL)',
    ),
  );

  @override
  Future<CatalogoRacas?> ler() async {
    final linhas = await (await _database).query('catalogo', where: 'id = 1');
    if (linhas.isEmpty) return null;
    final linha = linhas.single;
    final nomes = jsonDecode(linha['nomes'] as String);
    final data = DateTime.tryParse(linha['atualizado_em'] as String);
    if (nomes is! List ||
        nomes.isEmpty ||
        data == null ||
        nomes.any((n) => n is! String || n.trim().isEmpty || n.length > 120)) {
      throw const FormatException('Catálogo de raças inválido no cache.');
    }
    return CatalogoRacas(nomes: nomes.cast<String>(), atualizadoEm: data);
  }

  @override
  Future<void> salvar(CatalogoRacas catalogo) async {
    if (catalogo.nomes.isEmpty) return;
    await (await _database).insert('catalogo', {
      'id': 1,
      'nomes': jsonEncode(catalogo.nomes),
      'atualizado_em': catalogo.atualizadoEm.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> fechar() async {
    final abertura = _abertura;
    if (abertura != null) await (await abertura).close();
    _abertura = null;
  }
}
