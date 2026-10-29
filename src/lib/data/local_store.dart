import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract class PersistenciaLocal {
  Future<Map<String, Object?>?> lerCache(String servidor);
  Future<void> salvarCache(String servidor, Map<String, Object?> estado);
  Future<Map<String, Object?>> lerLegado();
  Future<String> origem();
  Future<void> fechar();
}

// Cache separado: nunca sobrescreve o banho_tosa.db da Etapa 4.
class LocalStore implements PersistenciaLocal {
  final String? diretorio;
  LocalStore({this.diretorio});
  Future<String> get _diretorio async => diretorio ?? await getDatabasesPath();
  Database? _db;
  Future<Database> get _database async => _db ??= await openDatabase(
    path.join(await _diretorio, 'banho_tosa_api_cache.db'),
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE cache (servidor TEXT PRIMARY KEY, estado TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE metadados (chave TEXT PRIMARY KEY, valor TEXT NOT NULL)',
      );
    },
  );

  @override
  Future<Map<String, Object?>?> lerCache(String servidor) async {
    final linhas = await (await _database).query(
      'cache',
      where: 'servidor = ?',
      whereArgs: [servidor],
    );
    return linhas.isEmpty
        ? null
        : Map<String, Object?>.from(
            jsonDecode(linhas.first['estado'] as String) as Map,
          );
  }

  @override
  Future<void> salvarCache(String servidor, Map<String, Object?> estado) async {
    await (await _database).insert('cache', {
      'servidor': servidor,
      'estado': jsonEncode(estado),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<String> origem() async {
    final db = await _database;
    return db.transaction((tx) async {
      final linhas = await tx.query(
        'metadados',
        where: 'chave = ?',
        whereArgs: ['origem'],
      );
      if (linhas.isNotEmpty) return linhas.first['valor'] as String;
      final random = Random.secure();
      final valor = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await tx.insert('metadados', {'chave': 'origem', 'valor': valor});
      return valor;
    });
  }

  @override
  Future<Map<String, Object?>> lerLegado() async {
    final arquivo = path.join(await _diretorio, 'banho_tosa.db');
    if (!await databaseExists(arquivo)) {
      return {
        'clientes': <Object?>[],
        'pets': <Object?>[],
        'agendamentos': <Object?>[],
      };
    }
    final db = await openDatabase(
      arquivo,
      readOnly: true,
      singleInstance: false,
    );
    try {
      return await db.transaction(
        (tx) async => {
          'clientes': await tx.query('clientes'),
          'pets': await tx.query('pets'),
          'agendamentos': await tx.query('agendamentos'),
        },
      );
    } finally {
      await db.close();
    }
  }

  @override
  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }
}
