import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/pet.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instancia = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final caminho = join(await getDatabasesPath(), 'banho_tosa.db');

    _database = await openDatabase(
      caminho,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            telefone TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id INTEGER NOT NULL,
            nome TEXT NOT NULL,
            especie TEXT NOT NULL,
            raca TEXT NOT NULL,
            porte TEXT NOT NULL,
            FOREIGN KEY (cliente_id)
              REFERENCES clientes (id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE agendamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pet_id INTEGER NOT NULL,
            data_hora TEXT NOT NULL UNIQUE,
            servico TEXT NOT NULL,
            FOREIGN KEY (pet_id)
              REFERENCES pets (id)
              ON DELETE RESTRICT
          )
        ''');
      },
    );

    return _database!;
  }

  // Recupera os clientes e seus respectivos pets.
  Future<List<Cliente>> listarClientes() async {
    final db = await database;

    final clientes = await db.query('clientes', orderBy: 'nome COLLATE NOCASE');

    final pets = await db.query('pets', orderBy: 'nome COLLATE NOCASE');

    return clientes.map((registro) {
      final petsDoCliente = pets
          .where((pet) => pet['cliente_id'] == registro['id'])
          .map((pet) => Pet.fromMap(pet))
          .toList();

      return Cliente.fromMap(registro, pets: petsDoCliente);
    }).toList();
  }

  // Cria ou atualiza um cliente e seu pet.
  Future<void> salvarClienteComPet({
    int? clienteId,
    int? petId,
    required String nomeCliente,
    required String telefone,
    required String nomePet,
    required String especie,
    required String raca,
    required String porte,
  }) async {
    final db = await database;

    await db.transaction((transacao) async {
      final dadosCliente = {'nome': nomeCliente, 'telefone': telefone};

      int idCliente;

      if (clienteId == null) {
        idCliente = await transacao.insert('clientes', dadosCliente);
      } else {
        await transacao.update(
          'clientes',
          dadosCliente,
          where: 'id = ?',
          whereArgs: [clienteId],
        );
        idCliente = clienteId;
      }

      final dadosPet = {
        'cliente_id': idCliente,
        'nome': nomePet,
        'especie': especie,
        'raca': raca,
        'porte': porte,
      };

      if (petId == null) {
        await transacao.insert('pets', dadosPet);
      } else {
        await transacao.update(
          'pets',
          dadosPet,
          where: 'id = ?',
          whereArgs: [petId],
        );
      }
    });
  }

  // Exclui clientes que não tenham agendamentos associados.
  Future<void> excluirCliente(int clienteId) async {
    final db = await database;

    final resultado = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM agendamentos a
      INNER JOIN pets p ON p.id = a.pet_id
      WHERE p.cliente_id = ?
      ''',
      [clienteId],
    );

    final total = Sqflite.firstIntValue(resultado) ?? 0;

    if (total > 0) {
      throw StateError(
        'Exclua os agendamentos deste cliente antes de removê-lo.',
      );
    }

    await db.delete('clientes', where: 'id = ?', whereArgs: [clienteId]);
  }

  // Recupera os agendamentos com os nomes do pet e do tutor.
  Future<List<Agendamento>> listarAgendamentos() async {
    final db = await database;

    final registros = await db.rawQuery('''
      SELECT
        a.id,
        a.pet_id,
        a.data_hora,
        a.servico,
        p.nome AS pet_nome,
        c.nome AS cliente_nome
      FROM agendamentos a
      INNER JOIN pets p ON p.id = a.pet_id
      INNER JOIN clientes c ON c.id = p.cliente_id
      ORDER BY a.data_hora ASC
    ''');

    return registros.map((registro) => Agendamento.fromMap(registro)).toList();
  }

  // Insere ou atualiza um agendamento.
  Future<void> salvarAgendamento({
    int? id,
    required int petId,
    required DateTime dataHora,
    required String servico,
  }) async {
    final db = await database;
    final dataFormatada = dataHora.toIso8601String();

    final conflitos = await db.query(
      'agendamentos',
      columns: ['id'],
      where: 'data_hora = ? AND id != ?',
      whereArgs: [dataFormatada, id ?? -1],
      limit: 1,
    );

    if (conflitos.isNotEmpty) {
      throw StateError('Já existe um agendamento para esta data e horário.');
    }

    final dados = {
      'pet_id': petId,
      'data_hora': dataFormatada,
      'servico': servico,
    };

    if (id == null) {
      await db.insert('agendamentos', dados);
    } else {
      await db.update('agendamentos', dados, where: 'id = ?', whereArgs: [id]);
    }
  }

  // Remove um agendamento pelo identificador.
  Future<void> excluirAgendamento(int id) async {
    final db = await database;

    await db.delete('agendamentos', where: 'id = ?', whereArgs: [id]);
  }
}
