import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

export function abrirBanco(caminho) {
  if (caminho !== ':memory:') {
    mkdirSync(dirname(caminho), { recursive: true });
  }

  const db = new DatabaseSync(caminho);

  db.exec(`
    PRAGMA foreign_keys = ON;
    PRAGMA busy_timeout = 5000;
    CREATE TABLE IF NOT EXISTS importacoes (
      origem TEXT PRIMARY KEY,
      resultado TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS clientes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      telefone TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS pets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente_id INTEGER NOT NULL,
      nome TEXT NOT NULL,
      especie TEXT NOT NULL,
      raca TEXT NOT NULL,
      porte TEXT NOT NULL,
      FOREIGN KEY (cliente_id)
        REFERENCES clientes (id)
        ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS agendamentos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pet_id INTEGER NOT NULL,
      data_hora TEXT NOT NULL UNIQUE,
      servico TEXT NOT NULL,
      FOREIGN KEY (pet_id)
        REFERENCES pets (id)
        ON DELETE RESTRICT
    );
  `);

  return db;
}

export function executarTransacao(db, operacao) {
  db.exec('BEGIN IMMEDIATE');

  try {
    const resultado = operacao();

    db.exec('COMMIT');

    return resultado;
  } catch (erro) {
    db.exec('ROLLBACK');

    throw erro;
  }
}

export function listarClientes(db) {
  const clientes = db.prepare(`
    SELECT id, nome, telefone
    FROM clientes
    ORDER BY nome COLLATE NOCASE
  `).all();

  const pets = db.prepare(`
    SELECT id, cliente_id, nome, especie, raca, porte
    FROM pets
    ORDER BY nome COLLATE NOCASE
  `).all();

  return clientes.map((cliente) => ({
    ...cliente,
    pets: pets.filter((pet) => pet.cliente_id === cliente.id)
  }));
}

export function consultarEstado(db) {
  const clientes = listarClientes(db);

  const agendamentos = db.prepare(`
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
    ORDER BY a.data_hora
  `).all();

  return {
    clientes,
    agendamentos
  };
}