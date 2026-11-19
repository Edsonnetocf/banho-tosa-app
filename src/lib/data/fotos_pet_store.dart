import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/app_log.dart';

class FotoPetException implements Exception {
  final String mensagem;
  const FotoPetException(this.mensagem);
  @override
  String toString() => mensagem;
}

abstract class FotosPetStore {
  Future<Map<int, String>> carregar(String servidor);
  Future<String> salvar(String servidor, int petId, String origem);
  Future<void> remover(String servidor, int petId);
  Future<void> fechar();
}

/// Cópias privadas das imagens e índice SQLite, separados por servidor e pet.
/// A imagem selecionada na galeria nunca é removida por este armazenamento.
class FotosPetStoreLocal implements FotosPetStore {
  final String? diretorio;
  final int limiteBytes;
  Future<Database>? _abertura;
  Directory? _pasta;
  static final _nomeValido = RegExp(r'^foto-[a-f0-9]{32}\.img$');

  FotosPetStoreLocal({this.diretorio, this.limiteBytes = 10 * 1024 * 1024});

  Future<Database> get _database => _abertura ??= _abrirComRecuperacao();

  Future<Database> _abrirComRecuperacao() async {
    try {
      return await _abrir();
    } catch (_) {
      _abertura = null;
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final base = diretorio ?? (await getApplicationSupportDirectory()).path;
    _pasta = await Directory(path.join(base, 'fotos_pets'))
        .create(recursive: true);
    return openDatabase(
      path.join(_pasta!.path, 'banho_tosa_fotos_pets.sqlite'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE fotos ('
        'servidor TEXT NOT NULL, pet_id INTEGER NOT NULL CHECK (pet_id > 0), '
        'arquivo TEXT NOT NULL, PRIMARY KEY (servidor, pet_id))',
      ),
    );
  }

  File? _arquivoSeguro(String nome) =>
      _nomeValido.hasMatch(nome) ? File(path.join(_pasta!.path, nome)) : null;

  Future<String?> _nomeAtual(Database db, String servidor, int petId) async {
    final linhas = await db.query(
      'fotos',
      columns: ['arquivo'],
      where: 'servidor = ? AND pet_id = ?',
      whereArgs: [servidor, petId],
    );
    return linhas.isEmpty ? null : linhas.single['arquivo'] as String;
  }

  @override
  Future<Map<int, String>> carregar(String servidor) async {
    final db = await _database;
    final linhas = await db.query(
      'fotos',
      where: 'servidor = ?',
      whereArgs: [servidor],
    );
    final fotos = <int, String>{};
    var ausentes = 0;
    for (final linha in linhas) {
      final arquivo = _arquivoSeguro(linha['arquivo'] as String);
      if (arquivo != null && await arquivo.exists()) {
        fotos[linha['pet_id'] as int] = arquivo.path;
      } else {
        ausentes++;
      }
    }
    if (ausentes > 0) {
      AppLog.aviso(
        'FOTOS',
        '$ausentes imagem(ns) ausente(s) ou com referência inválida.',
      );
    }
    return fotos;
  }

  @override
  Future<String> salvar(String servidor, int petId, String origem) async {
    if (petId <= 0) {
      throw const FotoPetException('Pet inválido para associar a foto.');
    }
    final original = File(origem);
    if (!await original.exists()) {
      throw const FotoPetException(
        'A foto selecionada não está mais disponível.',
      );
    }
    final tamanho = await original.length();
    if (tamanho == 0 || tamanho > limiteBytes) {
      throw const FotoPetException(
        'Escolha uma foto válida e de tamanho menor.',
      );
    }
    final db = await _database;
    final anterior = await _nomeAtual(db, servidor, petId);
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    // O codec da imagem é identificado pelos bytes, independentemente da extensão.
    final nome = 'foto-$id.img';
    final destino = _arquivoSeguro(nome)!;
    try {
      await original.copy(destino.path);
      await db.insert('fotos', {
        'servidor': servidor,
        'pet_id': petId,
        'arquivo': nome,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      await _apagarCopia(nome);
      rethrow;
    }
    // Só remove a cópia anterior após persistir a nova associação.
    if (anterior != null) await _apagarCopia(anterior);
    return destino.path;
  }

  @override
  Future<void> remover(String servidor, int petId) async {
    if (petId <= 0) {
      throw const FotoPetException('Pet inválido para remover a foto.');
    }
    final db = await _database;
    final anterior = await _nomeAtual(db, servidor, petId);
    await db.delete(
      'fotos',
      where: 'servidor = ? AND pet_id = ?',
      whereArgs: [servidor, petId],
    );
    if (anterior != null) await _apagarCopia(anterior);
  }

  Future<void> _apagarCopia(String nome) async {
    final arquivo = _arquivoSeguro(nome);
    if (arquivo == null) return;
    try {
      if (await arquivo.exists()) await arquivo.delete();
    } on FileSystemException {
      // O índice já foi atualizado; falha na limpeza não desfaz a operação.
      AppLog.aviso(
        'FOTOS',
        'Uma cópia antiga não pôde ser removida do armazenamento privado.',
      );
    }
  }

  @override
  Future<void> fechar() async {
    final abertura = _abertura;
    if (abertura == null) return;
    Database db;
    try {
      db = await abertura;
    } catch (_) {
      _abertura = null;
      _pasta = null;
      return;
    }
    await db.close();
    _abertura = null;
    _pasta = null;
  }
}
